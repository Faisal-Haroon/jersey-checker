import 'dart:convert';

class Imported3DModel {
  Imported3DModel({
    required this.id,
    required this.title,
    required this.filePath,
    required this.isAsset,
    required this.sizeBytes,
    required this.addedDate,
    this.category = 'Custom Model',
  });

  final String id;
  final String title;
  final String filePath; // Asset path or local file path
  final bool isAsset;
  final int sizeBytes;
  final DateTime addedDate;
  final String category;

  String get formattedSize {
    if (sizeBytes < 1024) return '$sizeBytes B';
    if (sizeBytes < 1024 * 1024) return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'filePath': filePath,
        'isAsset': isAsset,
        'sizeBytes': sizeBytes,
        'addedDate': addedDate.toIso8601String(),
        'category': category,
      };

  factory Imported3DModel.fromJson(Map<String, dynamic> json) => Imported3DModel(
        id: json['id'] as String,
        title: json['title'] as String,
        filePath: json['filePath'] as String,
        isAsset: json['isAsset'] as bool? ?? false,
        sizeBytes: json['sizeBytes'] as int? ?? 0,
        addedDate: DateTime.parse(json['addedDate'] as String),
        category: json['category'] as String? ?? 'Custom Model',
      );

  static String encodeList(List<Imported3DModel> list) =>
      jsonEncode(list.map((e) => e.toJson()).toList());

  static List<Imported3DModel> decodeList(String source) =>
      (jsonDecode(source) as List)
          .map((e) => Imported3DModel.fromJson(e as Map<String, dynamic>))
          .toList();
}
