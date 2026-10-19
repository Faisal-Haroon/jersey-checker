import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class StudioPreferences {
  final bool isGridEnabled;
  final bool isWatermarkEnabled;
  final String creatorName;
  final String? creatorLogoPath;
  final String downloadLink;
  final double modelExposure;

  const StudioPreferences({
    this.isGridEnabled = true,
    this.isWatermarkEnabled = false,
    this.creatorName = '',
    this.creatorLogoPath,
    this.downloadLink = '',
    this.modelExposure = 1.0,
  });

  StudioPreferences copyWith({
    bool? isGridEnabled,
    bool? isWatermarkEnabled,
    String? creatorName,
    String? creatorLogoPath,
    bool clearLogo = false,
    String? downloadLink,
    double? modelExposure,
  }) {
    return StudioPreferences(
      isGridEnabled: isGridEnabled ?? this.isGridEnabled,
      isWatermarkEnabled: isWatermarkEnabled ?? this.isWatermarkEnabled,
      creatorName: creatorName ?? this.creatorName,
      creatorLogoPath: clearLogo ? null : (creatorLogoPath ?? this.creatorLogoPath),
      downloadLink: downloadLink ?? this.downloadLink,
      modelExposure: modelExposure ?? this.modelExposure,
    );
  }

  Map<String, dynamic> toJson() => {
        'isGridEnabled': isGridEnabled,
        'isWatermarkEnabled': isWatermarkEnabled,
        'creatorName': creatorName,
        'creatorLogoPath': creatorLogoPath,
        'downloadLink': downloadLink,
        'modelExposure': modelExposure,
      };

  factory StudioPreferences.fromJson(Map<String, dynamic> json) {
    return StudioPreferences(
      isGridEnabled: json['isGridEnabled'] as bool? ?? true,
      isWatermarkEnabled: json['isWatermarkEnabled'] as bool? ?? false,
      creatorName: json['creatorName'] as String? ?? '',
      creatorLogoPath: json['creatorLogoPath'] as String?,
      downloadLink: json['downloadLink'] as String? ?? '',
      modelExposure: (json['modelExposure'] as num?)?.toDouble() ?? 1.0,
    );
  }
}

class StudioPreferencesService {
  static final StudioPreferencesService _instance =
      StudioPreferencesService._internal();
  factory StudioPreferencesService() => _instance;
  StudioPreferencesService._internal();

  StudioPreferences _preferences = const StudioPreferences();
  bool _initialized = false;

  StudioPreferences get preferences => _preferences;

  Future<void> init() async {
    if (_initialized) return;
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File(p.join(dir.path, 'studio_preferences.json'));
      if (await file.exists()) {
        final content = await file.readAsString();
        if (content.trim().isNotEmpty) {
          _preferences = StudioPreferences.fromJson(
            jsonDecode(content) as Map<String, dynamic>,
          );
        }
      }
      _initialized = true;
    } catch (_) {
      _initialized = true;
    }
  }

  Future<void> savePreferences(StudioPreferences prefs) async {
    _preferences = prefs;
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File(p.join(dir.path, 'studio_preferences.json'));
      await file.writeAsString(jsonEncode(prefs.toJson()));
    } catch (_) {}
  }
}
