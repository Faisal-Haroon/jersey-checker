import 'dart:io';
import 'package:path/path.dart' as path;

import '../models/selected_file.dart';

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
      return '$successful file${successful == 1 ? '' : 's'} converted to $targetExtension successfully.';
    }
    return '$successful file${successful == 1 ? '' : 's'} converted, $failed failed (${failedFileNames.join(', ')}).';
  }
}

class BytesConverterService {
  /// Converts PNG/Image files into `.bytes` files preserving binary integrity
  static Future<ConversionResult> convertBatch({
    required List<SelectedJerseyFile> files,
    required String outputDirectoryPath,
    void Function(int current, int total)? onProgress,
  }) async {
    int successful = 0;
    int failed = 0;
    final failedNames = <String>[];

    for (int i = 0; i < files.length; i++) {
      final selected = files[i];
      try {
        final rawName = path.basenameWithoutExtension(selected.customName);
        final targetFileName = rawName;
        final targetPath = path.join(outputDirectoryPath, targetFileName);

        final targetFile = File(targetPath);
        await targetFile.writeAsBytes(selected.bytes, flush: true);

        final writtenLength = await targetFile.length();
        if (writtenLength == selected.bytes.length) {
          successful++;
        } else {
          failed++;
          failedNames.add(selected.name);
        }
      } catch (e) {
        failed++;
        failedNames.add(selected.name);
      }

      onProgress?.call(i + 1, files.length);
    }

    return ConversionResult(
      total: files.length,
      successful: successful,
      failed: failed,
      failedFileNames: failedNames,
      targetExtension: '.bytes',
    );
  }

  /// Extracts raw PNG/JPG image bytes if valid image header is present, returns null if GPU compressed
  static List<int>? extractImageBytes(List<int> bytes) {
    if (bytes.length < 8) return null;
    
    // 1. Direct PNG check
    if (bytes[0] == 0x89 && bytes[1] == 0x50 && bytes[2] == 0x4E && bytes[3] == 0x47) {
      return bytes;
    }
    // 2. Direct JPG check
    if (bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) {
      return bytes;
    }
    // 3. Direct WEBP check (RIFF....WEBP)
    if (bytes[0] == 0x52 && bytes[1] == 0x49 && bytes[2] == 0x46 && bytes[3] == 0x46 &&
        bytes.length >= 12 && bytes[8] == 0x57 && bytes[9] == 0x45 && bytes[10] == 0x42 && bytes[11] == 0x50) {
      return bytes;
    }

    // 4. Embedded PNG search (first 2048 bytes header check)
    final searchLimit = bytes.length - 8 < 2048 ? bytes.length - 8 : 2048;
    for (int i = 0; i < searchLimit; i++) {
      if (bytes[i] == 0x89 && bytes[i + 1] == 0x50 && bytes[i + 2] == 0x4E && bytes[i + 3] == 0x47) {
        return bytes.sublist(i);
      }
    }
    // 5. Embedded JPG search
    final jpgLimit = bytes.length - 3 < 2048 ? bytes.length - 3 : 2048;
    for (int i = 0; i < jpgLimit; i++) {
      if (bytes[i] == 0xFF && bytes[i + 1] == 0xD8 && bytes[i + 2] == 0xFF) {
        return bytes.sublist(i);
      }
    }
    return null;
  }

  /// Converts `.bytes` / binary files into `.png` image files
  static Future<ConversionResult> convertBytesToPngBatch({
    required List<SelectedJerseyFile> files,
    required String outputDirectoryPath,
    void Function(int current, int total)? onProgress,
  }) async {
    int successful = 0;
    int failed = 0;
    final failedNames = <String>[];

    for (int i = 0; i < files.length; i++) {
      final selected = files[i];
      try {
        final cleanBytes = extractImageBytes(selected.bytes);
        if (cleanBytes == null) {
          failed++;
          failedNames.add('${selected.name} (Unity GPU compressed texture)');
          continue;
        }

        final rawName = path.basenameWithoutExtension(selected.customName);
        final targetFileName = rawName.toLowerCase().endsWith('.png') ? rawName : '$rawName.png';
        final targetPath = path.join(outputDirectoryPath, targetFileName);

        final targetFile = File(targetPath);
        await targetFile.writeAsBytes(cleanBytes, flush: true);

        final writtenLength = await targetFile.length();
        if (writtenLength == cleanBytes.length) {
          successful++;
        } else {
          failed++;
          failedNames.add(selected.name);
        }
      } catch (e) {
        failed++;
        failedNames.add(selected.name);
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
