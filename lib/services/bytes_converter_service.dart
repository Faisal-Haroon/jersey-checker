import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:path/path.dart' as path;

import '../models/selected_file.dart';
import 'media_scanner_service.dart';

class ConversionResult {
  const ConversionResult({
    required this.total,
    required this.successful,
    required this.failed,
    required this.failedFileNames,
    this.targetExtension = '.bytes',
  });

  final int total;
  final int successful;
  final int failed;
  final List<String> failedFileNames;
  final String targetExtension;

  bool get isSuccess => failed == 0;
  String get statusMessage {
    if (total == 0) return 'No files selected for conversion.';
    if (failed == 0) {
      return '$successful file${successful == 1 ? '' : 's'} converted successfully.';
    }
    return '$successful file${successful == 1 ? '' : 's'} converted, $failed failed (${failedFileNames.join(', ')}).';
  }
}

class BytesConverterService {
  // -----------------------------------------------------------------------
  // Core helper: write bytes to outputDir/baseName[ext], auto-renaming on
  // collision. Works reliably across all Android storage versions.
  //
  // Strategy:
  //   1. Pre-scan outputDir to find all existing file names.
  //   2. Check candidate names: pak24 -> pak24 (1) -> pak24 (2)...
  //   3. Catch any collision/permission error during write and increment.
  //   4. Returns the path that was successfully written.
  // -----------------------------------------------------------------------
  static Future<String> _writeWithAutoRename(
    String outputDir,
    String baseName,
    Uint8List bytes, {
    String extension = '',
  }) async {
    // 1. Scan directory for existing filenames so we know in advance which names are taken
    final existingNames = <String>{};
    try {
      final dir = Directory(outputDir);
      if (await dir.exists()) {
        await for (final entity in dir.list(followLinks: false)) {
          existingNames.add(path.basename(entity.path).toLowerCase());
        }
      }
    } catch (_) {}

    String fileNameForAttempt(int n) {
      final suffix = n == 0 ? '' : ' ($n)';
      return extension.isEmpty
          ? '$baseName$suffix'
          : '$baseName$suffix$extension';
    }

    for (int attempt = 0; attempt <= 999; attempt++) {
      final fileName = fileNameForAttempt(attempt);
      final filePath = path.join(outputDir, fileName);

      // If directory listing already saw this file, skip immediately
      if (existingNames.contains(fileName.toLowerCase())) {
        continue;
      }

      // Check if file exists via File API
      if (await _fileExistsSafe(filePath)) {
        existingNames.add(fileName.toLowerCase());
        continue;
      }

      final file = File(filePath);
      try {
        await file.writeAsBytes(bytes, flush: true, mode: FileMode.write);
        existingNames.add(fileName.toLowerCase());
        return filePath; // Successfully written!
      } catch (e) {
        final errStr = e.toString().toLowerCase();
        final osCode =
            (e is FileSystemException) ? (e.osError?.errorCode ?? 0) : 0;
        final isCollision = osCode == 17 ||
            osCode == 13 ||
            errStr.contains('exist') ||
            errStr.contains('17') ||
            errStr.contains('denied') ||
            errStr.contains('eexist') ||
            errStr.contains('eacces');

        if (isCollision) {
          // File already exists or cannot be overwritten; try next numbered slot: pak24 (1), pak24 (2)...
          existingNames.add(fileName.toLowerCase());
          continue;
        }
        rethrow;
      }
    }

    // Absolute fallback: timestamp suffix (never collides)
    final ts = DateTime.now().millisecondsSinceEpoch;
    final fallbackName =
        extension.isEmpty ? '${baseName}_$ts' : '${baseName}_$ts$extension';
    final fallback = path.join(outputDir, fallbackName);
    await File(fallback).writeAsBytes(bytes, flush: true, mode: FileMode.write);
    return fallback;
  }

  /// Safe exists check — checks async exists, sync exists, and length.
  static Future<bool> _fileExistsSafe(String filePath) async {
    try {
      final f = File(filePath);
      if (await f.exists()) return true;
      if (f.existsSync()) return true;
      if (await f.length() > 0) return true;
    } catch (_) {}
    return false;
  }

  /// Converts PNG/JPG/Image files into `.bytes` binary files preserving binary integrity
  static Future<ConversionResult> convertBatch({
    required List<SelectedJerseyFile> files,
    required String outputDirectoryPath,
    void Function(int current, int total)? onProgress,
  }) async {
    int successful = 0;
    int failed = 0;
    final failedNames = <String>[];

    // Ensure output directory exists recursively
    try {
      final outDir = Directory(outputDirectoryPath);
      if (!await outDir.exists()) {
        await outDir.create(recursive: true);
      }
    } catch (_) {}

    for (int i = 0; i < files.length; i++) {
      final selected = files[i];
      try {
        String base = selected.customName;
        // Strip common image extensions (.png, .jpg, .jpeg, etc.)
        for (final ext in [
          '.png',
          '.jpg',
          '.jpeg',
          '.webp',
          '.jfif',
          '.bmp',
        ]) {
          if (base.toLowerCase().endsWith(ext)) {
            base = base.substring(0, base.length - ext.length);
            break;
          }
        }

        // Sanitize to prevent OS invalid argument / illegal character errors
        final sanitized = base.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_').trim();
        final rawTargetName =
            sanitized.isEmpty ? 'jersey_texture' : sanitized;

        // Write with auto-rename on collision (pak24 → pak24 (1) → …)
        final writtenPath = await _writeWithAutoRename(
          outputDirectoryPath,
          rawTargetName,
          selected.bytes,
        );

        final writtenLength = await File(writtenPath).length();
        if (writtenLength == selected.bytes.length && writtenLength > 0) {
          successful++;
          // Trigger Android MediaScanner so system document picker indexes it
          await MediaScannerService.scanFile(writtenPath);
        } else {
          failed++;
          failedNames.add('${selected.name} (File write empty)');
        }
      } catch (e) {
        failed++;
        String err = e.toString();
        if (err.contains('17') || err.toLowerCase().contains('exist')) {
          err = 'File collision error';
        } else if (err.contains('13') || err.toLowerCase().contains('denied')) {
          err = 'Storage permission denied';
        }
        failedNames.add('${selected.name} ($err)');
      }

      onProgress?.call(i + 1, files.length);
    }

    return ConversionResult(
      total: files.length,
      successful: successful,
      failed: failed,
      failedFileNames: failedNames,
      targetExtension: '',
    );
  }



  /// Extracts raw PNG/JPG image bytes if valid image header is present, returns null if GPU compressed
  static List<int>? extractImageBytes(List<int> bytes) {
    if (bytes.length < 4) return null;

    // 1. Direct PNG check
    if (bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47) {
      return bytes;
    }
    // 2. Direct JPG check (SOI: 0xFF, 0xD8)
    if (bytes[0] == 0xFF && bytes[1] == 0xD8) {
      return bytes;
    }
    // 3. Direct WEBP check (RIFF....WEBP)
    if (bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46 &&
        bytes.length >= 12 &&
        bytes[8] == 0x57 &&
        bytes[9] == 0x45 &&
        bytes[10] == 0x42 &&
        bytes[11] == 0x50) {
      return bytes;
    }

    // 4. Embedded PNG search (search entire file)
    final searchLimit = bytes.length - 4;
    for (int i = 0; i < searchLimit; i++) {
      if (bytes[i] == 0x89 &&
          bytes[i + 1] == 0x50 &&
          bytes[i + 2] == 0x4E &&
          bytes[i + 3] == 0x47) {
        return bytes.sublist(i);
      }
    }
    // 5. Embedded JPG search (search entire file)
    final jpgLimit = bytes.length - 2;
    for (int i = 0; i < jpgLimit; i++) {
      if (bytes[i] == 0xFF && bytes[i + 1] == 0xD8) {
        return bytes.sublist(i);
      }
    }
    return null;
  }

  /// Extracts image bytes from any file (JPG, PNG, WEBP or Unity embedded)
  /// and converts it to a genuine, standard PNG format using Flutter's native decoder.
  static Future<Uint8List?> extractAndConvertToPng(Uint8List bytes) async {
    // 1. Try decoding directly with native image engine
    try {
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final byteData =
          await frame.image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData != null) {
        return byteData.buffer.asUint8List();
      }
    } catch (_) {}

    // 2. If direct decode fails (e.g. Unity binary wrapper), search embedded image
    final cleanBytes = extractImageBytes(bytes);
    if (cleanBytes != null) {
      final rawSublist = Uint8List.fromList(cleanBytes);
      try {
        final codec = await ui.instantiateImageCodec(rawSublist);
        final frame = await codec.getNextFrame();
        final byteData =
            await frame.image.toByteData(format: ui.ImageByteFormat.png);
        if (byteData != null) {
          return byteData.buffer.asUint8List();
        }
      } catch (_) {
        // Fallback: return raw extracted image bytes
        return rawSublist;
      }
      return rawSublist;
    }

    return null;
  }

  /// Converts `.bytes` / binary / JPG files into genuine `.png` image files
  static Future<ConversionResult> convertBytesToPngBatch({
    required List<SelectedJerseyFile> files,
    required String outputDirectoryPath,
    void Function(int current, int total)? onProgress,
  }) async {
    int successful = 0;
    int failed = 0;
    final failedNames = <String>[];

    // Ensure output directory exists recursively
    try {
      final outDir = Directory(outputDirectoryPath);
      if (!await outDir.exists()) {
        await outDir.create(recursive: true);
      }
    } catch (_) {}

    for (int i = 0; i < files.length; i++) {
      final selected = files[i];
      try {
        final cleanPngBytes = await extractAndConvertToPng(selected.bytes);
        if (cleanPngBytes == null) {
          failed++;
          failedNames.add('${selected.name} (Unsupported texture format)');
          continue;
        }

        final rawName = path.basenameWithoutExtension(selected.customName);
        final sanitized = rawName.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_').trim();
        final base = sanitized.isEmpty ? 'converted_texture' : sanitized;

        // Write with auto-rename on collision (pak24.png → pak24 (1).png → …)
        final writtenPath = await _writeWithAutoRename(
          outputDirectoryPath,
          base,
          cleanPngBytes,
          extension: '.png',
        );

        final targetFile = File(writtenPath);
        final writtenLength = await targetFile.length();
        if (writtenLength == cleanPngBytes.length && writtenLength > 0) {
          successful++;
          // Trigger Android MediaScanner so system document picker indexes it
          await MediaScannerService.scanFile(writtenPath);
        } else {
          failed++;
          failedNames.add('${selected.name} (File write empty)');
        }
      } catch (e) {
        failed++;
        String err = e.toString();
        if (err.contains('17') || err.toLowerCase().contains('exist')) {
          err = 'File collision error';
        } else if (err.contains('13') || err.toLowerCase().contains('denied')) {
          err = 'Storage permission denied';
        }
        failedNames.add('${selected.name} ($err)');
      }

      onProgress?.call(i + 1, files.length);
    }

    return ConversionResult(
      total: files.length,
      successful: successful,
      failed: failed,
      failedFileNames: failedNames,
      targetExtension: '.png',
    );
  }
}
