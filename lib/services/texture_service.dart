import 'package:file_picker/file_picker.dart';
import '../models/selected_file.dart';
import 'texture_validation_service.dart';

class TextureService {
  /// Pick a single PNG jersey texture file for 3D preview.
  static Future<SelectedJerseyFile?> pickSinglePng() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.custom,
      allowedExtensions: ['png', 'jpg', 'jpeg', 'webp'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) return null;
    final file = result.files.first;

    if (file.bytes == null) {
      throw const FormatException('Unable to read selected image file.');
    }

    final selected = SelectedJerseyFile(
      name: file.name,
      bytes: file.bytes!,
      size: file.size,
      path: file.path,
    );

    final validation = TextureValidationService.validateTexture(selected);
    if (!validation.isValid) {
      throw FormatException(validation.errorMessage ?? 'Invalid image texture.');
    }

    return selected;
  }

  /// Pick one or multiple image jersey files for batch conversion.
  static Future<List<SelectedJerseyFile>> pickMultiplePngs() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['png', 'jpg', 'jpeg', 'webp'],
      withData: true,
    );

    if (result == null) return [];

    final list = <SelectedJerseyFile>[];
    for (final file in result.files) {
      if (file.bytes != null) {
        final item = SelectedJerseyFile(
          name: file.name,
          bytes: file.bytes!,
          size: file.size,
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
  static Future<List<SelectedJerseyFile>> pickMultipleBytesFiles() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.any,
      withData: true,
    );

    if (result == null) return [];

    final list = <SelectedJerseyFile>[];
    for (final file in result.files) {
      if (file.bytes != null) {
        final item = SelectedJerseyFile(
          name: file.name,
          bytes: file.bytes!,
          size: file.size,
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
}
