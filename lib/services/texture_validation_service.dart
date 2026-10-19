import '../models/selected_file.dart';

class TextureValidationResult {
  const TextureValidationResult({required this.isValid, this.errorMessage});

  final bool isValid;
  final String? errorMessage;
}

class TextureValidationService {
  // Max file size limit for mobile memory safety: 25 MB
  static const int maxFileSizeBytes = 25 * 1024 * 1024;

  static TextureValidationResult validateTexture(SelectedJerseyFile file) {
    if (file.bytes.isEmpty) {
      return const TextureValidationResult(
        isValid: false,
        errorMessage: 'Selected image file appears empty or corrupted.',
      );
    }

    final name = file.name.toLowerCase();
    final validExtensions = ['.png', '.jpg', '.jpeg', '.webp', '.jfif', '.bmp'];
    final hasValidExt = validExtensions.any((ext) => name.endsWith(ext));

    if (!hasValidExt) {
      // Magic bytes check for images without standard extension
      if (file.bytes.length >= 3) {
        final isPng = file.bytes[0] == 0x89 && file.bytes[1] == 0x50;
        final isJpg = file.bytes[0] == 0xFF && file.bytes[1] == 0xD8;
        final isWebp = file.bytes.length >= 12 &&
            file.bytes[0] == 0x52 &&
            file.bytes[1] == 0x49 &&
            file.bytes[2] == 0x46 &&
            file.bytes[3] == 0x46;
        if (!isPng && !isJpg && !isWebp) {
          return const TextureValidationResult(
            isValid: false,
            errorMessage:
                'Invalid file format. Only PNG, JPG, and WEBP image textures are supported.',
          );
        }
      }
    }

    if (file.size > maxFileSizeBytes) {
      return const TextureValidationResult(
        isValid: false,
        errorMessage:
            'Texture file size is too large (max 25MB). Please choose a smaller image texture.',
      );
    }

    return const TextureValidationResult(isValid: true);
  }

  static TextureValidationResult validateByteFile(SelectedJerseyFile file) {
    if (file.bytes.isEmpty) {
      return const TextureValidationResult(
        isValid: false,
        errorMessage: 'Selected byte file appears empty or corrupted.',
      );
    }

    if (file.size > maxFileSizeBytes) {
      return const TextureValidationResult(
        isValid: false,
        errorMessage:
            'File size is too large (max 15MB). Please choose a smaller file.',
      );
    }

    return const TextureValidationResult(isValid: true);
  }
}
