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
        final rawName = path.basenameWithoutExtension(selected.customName);
        final targetFileName = rawName.toLowerCase().endsWith('.png') ? rawName : '$rawName.png';
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
      targetExtension: '.png',
    );
  }
}
