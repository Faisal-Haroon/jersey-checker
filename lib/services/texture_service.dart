import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import '../models/selected_file.dart';
import 'texture_validation_service.dart';

class TextureService {
  /// Helper to safely obtain bytes from FilePicker platform file on all Android versions
  static Future<Uint8List?> _resolveBytes(PlatformFile file) async {
    if (file.bytes != null && file.bytes!.isNotEmpty) {
      return file.bytes;
    }
    if (file.path != null && file.path!.isNotEmpty) {
      try {
        final f = File(file.path!);
        if (await f.exists()) {
          return await f.readAsBytes();
        }
      } catch (_) {}
    }
    return null;
  }

  /// Pick a single PNG/JPG jersey texture file for 3D preview.
  static Future<SelectedJerseyFile?> pickSinglePng() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.custom,
      allowedExtensions: ['png', 'jpg', 'jpeg', 'webp', 'jfif', 'bmp'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) return null;
    final file = result.files.first;
    final bytes = await _resolveBytes(file);

    if (bytes == null || bytes.isEmpty) {
      throw const FormatException('Unable to read selected image file.');
    }

    final selected = SelectedJerseyFile(
      name: file.name,
      bytes: bytes,
      size: file.size > 0 ? file.size : bytes.length,
      path: file.path,
    );

    final validation = TextureValidationService.validateTexture(selected);
    if (!validation.isValid) {
      throw FormatException(
        validation.errorMessage ?? 'Invalid image texture.',
      );
    }

    return selected;
  }

  /// Pick one or multiple image jersey files (PNG, JPG, JPEG, WEBP) for batch conversion.
  static Future<List<SelectedJerseyFile>> pickMultiplePngs() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['png', 'jpg', 'jpeg', 'webp', 'jfif', 'bmp'],
      withData: true,
    );

    if (result == null) return [];

    final list = <SelectedJerseyFile>[];
    for (final file in result.files) {
      final bytes = await _resolveBytes(file);
      if (bytes != null && bytes.isNotEmpty) {
        final item = SelectedJerseyFile(
          name: file.name,
          bytes: bytes,
          size: file.size > 0 ? file.size : bytes.length,
          path: file.path,
        );
        final validation = TextureValidationService.validateTexture(item);
        if (validation.isValid) {
          list.add(item);
        }
      }
    }
    return list;
  }

  /// Pick one or multiple byte files (.bytes, .bin, etc.) for extraction to PNG.
  /// Uses withData: false so Android SAF returns a valid path for ALL folders
  /// (Downloads, Downloads subfolders, shared storage) — then reads bytes manually.
  static Future<List<SelectedJerseyFile>> pickMultipleBytesFiles() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.any,
      withData: false, // path-based: works across ALL Android folders
    );

    if (result == null) return [];

    final list = <SelectedJerseyFile>[];
    for (final file in result.files) {
      final bytes = await _resolveBytes(file);
      if (bytes != null && bytes.isNotEmpty) {
        final item = SelectedJerseyFile(
          name: file.name,
          bytes: bytes,
          size: file.size > 0 ? file.size : bytes.length,
          path: file.path,
        );
        final validation = TextureValidationService.validateByteFile(item);
        if (validation.isValid) {
          list.add(item);
        }
      }
    }
    return list;
  }



  /// Directly read all files from a directory (such as Download/JerseyStudio)
  /// completely bypassing Android SAF and MediaStore picker limitations.
  static Future<List<SelectedJerseyFile>> loadFilesFromDirectory(
    String dirPath,
  ) async {
    final dir = Directory(dirPath);
    if (!await dir.exists()) return [];

    final list = <SelectedJerseyFile>[];
    try {
      final entities = dir.listSync(followLinks: false);
      for (final entity in entities) {
        if (entity is File) {
          final fileName = entity.uri.pathSegments.lastWhere(
            (s) => s.isNotEmpty,
            orElse: () => 'file',
          );
          if (fileName.startsWith('.')) continue;

          try {
            final bytes = await entity.readAsBytes();
            if (bytes.isNotEmpty) {
              final item = SelectedJerseyFile(
                name: fileName,
                bytes: bytes,
                size: bytes.length,
                path: entity.path,
              );
              list.add(item);
            }
          } catch (_) {}
        }
      }
    } catch (_) {}
    return list;
  }
}
