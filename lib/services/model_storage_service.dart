import 'dart:io';
import 'package:file_picker/file_picker.dart';

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
    // Remove old generic player from saved list if it exists
    _models.removeWhere((m) => m.id == 'default_dummy_player');

    const defaultAssetPath = 'assets/models/coin.glb';
    final hasDefault = _models.any((m) => m.id == '__default_coin__');
    if (!hasDefault) {
      _models.insert(
        0,
        Imported3DModel(
          id: '__default_coin__',
          title: 'Bobzie X Coin',
          filePath: defaultAssetPath,
          isAsset: true,
          sizeBytes: 220184,
          addedDate: DateTime.now(),
          category: 'Default',
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

  Future<void> saveLastSelectedModelId(String id) async {
    try {
      final docDir = await getApplicationDocumentsDirectory();
      final file = File(p.join(docDir.path, 'last_selected_model.txt'));
      await file.writeAsString(id);
    } catch (_) {}
  }

  Future<String?> getLastSelectedModelId() async {
    try {
      final docDir = await getApplicationDocumentsDirectory();
      final file = File(p.join(docDir.path, 'last_selected_model.txt'));
      if (await file.exists()) {
        return await file.readAsString();
      }
    } catch (_) {}
    return null;
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
      throw Exception(
        'Invalid file type. Please select a .glb or .gltf 3D model file.',
      );
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
    final targetPath = p.join(
      modelsDir.path,
      '${DateTime.now().millisecondsSinceEpoch}_$sanitizedName',
    );
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
