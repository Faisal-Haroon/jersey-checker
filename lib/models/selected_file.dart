import 'dart:typed_data';

class SelectedJerseyFile {
  SelectedJerseyFile({
    required this.name,
    required this.bytes,
    required this.size,
    this.path,
    String? customName,
  }) : customName = customName ?? name;

  final String name;
  final Uint8List bytes;
  final int size;
  final String? path;
  String customName;

  String get formattedSize {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
