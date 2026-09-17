import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/imported_model.dart';

class ModelStorageService {
  static final ModelStorageService _instance = ModelStorageService._internal();
  factory ModelStorageService() => _instance;
  ModelStorageService._internal();

  final List<Imported3DModel> _models = [];
  bool _initialized = false;

  List<Imported3DModel> get models => List.unmodifiable(_models);

  Future<void> init() async {
    if (_initialized) return;
    try {
      final docDir = await getApplicationDocumentsDirectory();
      final indexFile = File(p.join(docDir.path, 'models_index.json'));

      if (await indexFile.exists()) {
        final content = await indexFile.readAsString();
        if (content.trim().isNotEmpty) {
          _models.clear();
          _models.addAll(Imported3DModel.decodeList(content));
        }
      }

      // Add default asset dummy model if list is empty or if default asset exists
      _ensureDefaultModel();
      _initialized = true;
    } catch (e) {
      _ensureDefaultModel();
      _initialized = true;
    }
  }

  void _ensureDefaultModel() {
    const defaultAssetPath = 'assets/models/player_model.glb';
    final hasDefault = _models.any((m) => m.id == 'default_dummy_player');
    if (!hasDefault) {
      _models.insert(
        0,
        Imported3DModel(
          id: 'default_dummy_player',
          title: 'Default Generic Player',
          filePath: defaultAssetPath,
          isAsset: true,
          sizeBytes: 1676,
          addedDate: DateTime.now(),
          category: 'Standard Mannequin',
        ),
      );
    }
  }

  Future<void> _saveIndex() async {
    try {
      final docDir = await getApplicationDocumentsDirectory();
      final indexFile = File(p.join(docDir.path, 'models_index.json'));
      await indexFile.writeAsString(Imported3DModel.encodeList(_models));
    } catch (_) {}
  }

  Future<Imported3DModel?> pickAndImportLocalModel() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      withData: false,
    );

    if (result == null || result.files.isEmpty) return null;

    final file = result.files.first;
    final fileName = file.name;

    final ext = p.extension(fileName).toLowerCase();
    if (ext != '.glb' && ext != '.gltf') {
      throw Exception('Invalid file type. Please select a .glb or .gltf 3D model file.');
    }

    final fileBytes = file.bytes;

    if (fileBytes == null && file.path == null) {
      throw Exception('Could not read selected 3D model file content.');
    }

    final docDir = await getApplicationDocumentsDirectory();
    final modelsDir = Directory(p.join(docDir.path, 'custom_models'));
    if (!await modelsDir.exists()) {
      await modelsDir.create(recursive: true);
    }

    final sanitizedName = fileName.replaceAll(RegExp(r'[^\w\.-]'), '_');
    final targetPath = p.join(modelsDir.path, '${DateTime.now().millisecondsSinceEpoch}_$sanitizedName');
    final targetFile = File(targetPath);

    if (fileBytes != null) {
      await targetFile.writeAsBytes(fileBytes);
    } else if (file.path != null) {
      await File(file.path!).copy(targetPath);
    }

    final newModel = Imported3DModel(
      id: 'model_${DateTime.now().millisecondsSinceEpoch}',
      title: p.basenameWithoutExtension(fileName),
      filePath: targetPath,
      isAsset: false,
      sizeBytes: await targetFile.length(),
      addedDate: DateTime.now(),
      category: 'Imported Model',
    );

    _models.add(newModel);
    await _saveIndex();
    return newModel;
  }

  Future<Imported3DModel?> downloadModelFromUrl(String url, String customTitle) async {
    final uri = Uri.parse(url.trim());
    final response = await http.get(uri);
    if (response.statusCode != 200) {
      throw Exception('Failed to download 3D model (HTTP ${response.statusCode})');
    }

    final bytes = response.bodyBytes;
    if (bytes.isEmpty) {
      throw Exception('Downloaded 3D model file is empty.');
    }

    final docDir = await getApplicationDocumentsDirectory();
    final modelsDir = Directory(p.join(docDir.path, 'custom_models'));
    if (!await modelsDir.exists()) {
      await modelsDir.create(recursive: true);
    }

    final titleClean = customTitle.trim().isEmpty ? 'Downloaded Model' : customTitle.trim();
    final targetPath = p.join(modelsDir.path, '${DateTime.now().millisecondsSinceEpoch}_model.glb');
    final targetFile = File(targetPath);
    await targetFile.writeAsBytes(bytes);

    final newModel = Imported3DModel(
      id: 'model_${DateTime.now().millisecondsSinceEpoch}',
      title: titleClean,
      filePath: targetPath,
      isAsset: false,
      sizeBytes: bytes.length,
      addedDate: DateTime.now(),
      category: 'Downloaded Model',
    );

    _models.add(newModel);
    await _saveIndex();
    return newModel;
  }

  Future<bool> deleteModel(String id) async {
    final index = _models.indexWhere((m) => m.id == id);
    if (index == -1) return false;

    final model = _models[index];
    if (model.isAsset) return false; // Prevent deleting default asset

    try {
      final file = File(model.filePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}

    _models.removeAt(index);
    await _saveIndex();
    return true;
  }
}
