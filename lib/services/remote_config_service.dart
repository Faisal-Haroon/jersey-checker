import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class AppConfig {
  const AppConfig({
    required this.modelUrl,
    required this.modelVersion,
    required this.watermarkText,
    required this.minAppVersion,
  });

  final String modelUrl;
  final String modelVersion;
  final String watermarkText;
  final String minAppVersion;

  factory AppConfig.defaultConfig() {
    return const AppConfig(
      modelUrl: '',
      modelVersion: '1.0',
      watermarkText: 'Jersey Checker 3D',
      minAppVersion: '1.0.0',
    );
  }
}

class RemoteConfigService {
  static const String fallbackModelAsset = 'assets/models/player_model.glb';

  /// Get remote or cached GLB model path; falls back to bundled asset if offline
  static Future<String> getActiveModelPath({String? remoteUrl}) async {
    if (remoteUrl == null ||
        remoteUrl.isEmpty ||
        !remoteUrl.startsWith('http')) {
      return fallbackModelAsset;
    }

    try {
      final cacheDir = await getApplicationDocumentsDirectory();
      final cacheFile = File('${cacheDir.path}/cached_player_model.glb');

      if (await cacheFile.exists()) {
        return cacheFile.path;
      }

      final response = await http.get(Uri.parse(remoteUrl));
      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
        await cacheFile.writeAsBytes(response.bodyBytes, flush: true);
        return cacheFile.path;
      }
    } catch (_) {
      // Fallback cleanly to bundled local asset
    }

    return fallbackModelAsset;
  }
}
