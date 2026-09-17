import '../models/selected_file.dart';

class TextureValidationResult {
  const TextureValidationResult({
    required this.isValid,
    this.errorMessage,
  });

  final bool isValid;
  final String? errorMessage;
}

class TextureValidationService {
  // Max file size limit for mobile memory safety: 15 MB
  static const int maxFileSizeBytes = 15 * 1024 * 1024;

  static TextureValidationResult validateTexture(SelectedJerseyFile file) {
    final name = file.name.toLowerCase();
    if (!name.endsWith('.png') && !name.endsWith('.jpg') && !name.endsWith('.jpeg') && !name.endsWith('.webp')) {
      return const TextureValidationResult(
        isValid: false,
        errorMessage: 'Invalid file format. Only PNG, JPG, and WEBP image textures are supported.',
      );
    }

    if (file.bytes.isEmpty) {
      return const TextureValidationResult(
        isValid: false,
        errorMessage: 'Selected image file appears empty or corrupted.',
      );
    }

    if (file.size > maxFileSizeBytes) {
      return const TextureValidationResult(
        isValid: false,
        errorMessage:
            'Texture file size is too large (max 15MB). Please choose a smaller image texture.',
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
        errorMessage: 'File size is too large (max 15MB). Please choose a smaller file.',
      );
    }

    return const TextureValidationResult(isValid: true);
  }
}
