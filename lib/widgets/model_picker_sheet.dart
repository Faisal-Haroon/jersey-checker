import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';

import '../models/imported_model.dart';
import '../services/glb_texture_extractor.dart';
import '../services/model_storage_service.dart';
import '../theme/app_theme.dart';

class ModelPickerSheet extends StatefulWidget {
  const ModelPickerSheet({
    super.key,
    required this.selectedModelId,
    required this.onSelectModel,
  });

  final String selectedModelId;
  final ValueChanged<Imported3DModel> onSelectModel;

  @override
  State<ModelPickerSheet> createState() => _ModelPickerSheetState();
}

class _ModelPickerSheetState extends State<ModelPickerSheet> {
  final ModelStorageService _storageService = ModelStorageService();
  bool _isImporting = false;

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _handleImportLocal() async {
    setState(() => _isImporting = true);
    try {
      final newModel = await _storageService.pickAndImportLocalModel();
      if (!mounted) return;
      setState(() => _isImporting = false);

      if (newModel != null) {
        widget.onSelectModel(newModel);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Imported "${newModel.title}" successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isImporting = false);
        _showError(e.toString());
      }
    }
  }


  Future<void> _extractModelTexture(Imported3DModel model) async {
    try {
      Uint8List? bytes;
      if (model.isAsset) {
        final byteData = await DefaultAssetBundle.of(
          context,
        ).load(model.filePath);
        bytes = byteData.buffer.asUint8List();
      } else {
        final file = File(model.filePath);
        if (await file.exists()) {
          bytes = await file.readAsBytes();
        }
      }

      if (bytes == null || bytes.isEmpty) {
        if (mounted) Navigator.pop(context);
        _showError('Model file not accessible.');
        return;
      }

      final textures = GlbTextureExtractorService.extractTexturesFromGlbBytes(
        bytes,
      );
      if (textures.isEmpty) {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.white, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This model has no embedded textures. You can select any custom jersey PNG texture above to apply!',
                    ),
                  ),
                ],
              ),
              backgroundColor: AppTheme.primaryBlue,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
        return;
      }

      final countSaved =
          await GlbTextureExtractorService.saveAllExtractedTexturesToGallery(
            textures,
            model.title,
          );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              countSaved > 0
                  ? 'Extracted & saved $countSaved texture(s) (Shirt, Face, etc.) to Gallery!'
                  : 'Could not save textures to Gallery. Check permissions.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        _showError(e.toString());
      }
    }
  }

  void _showError(String rawError) {
    String cleanMsg = rawError
        .replaceAll(
          RegExp(r'^(Exception|PlatformException|FormatException):\s*'),
          '',
        )
        .replaceAll(RegExp(r'^\w+Exception:\s*'), '');

    if (cleanMsg.contains('read_external_storage_denied')) {
      cleanMsg = 'Storage permission denied. Please grant storage access.';
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(cleanMsg),
          backgroundColor: AppTheme.errorRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
  }


  @override
  Widget build(BuildContext context) {
    final models = _storageService.models;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.view_in_ar, color: AppTheme.primaryBlue),
              const SizedBox(width: 10),
              const Text(
                '3D Models Library',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textMain,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close, color: AppTheme.textMuted),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: _isImporting ? null : _handleImportLocal,
                  icon: const Icon(Icons.add_a_photo_outlined, size: 16),
                  label: Text(_isImporting ? 'Importing...' : 'Import GLB'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar()
                      ..showSnackBar(
                        SnackBar(
                          content: const Row(
                            children: [
                              Icon(Icons.construction_rounded,
                                  color: Colors.white, size: 16),
                              SizedBox(width: 8),
                              Text('Web Import — Coming Soon!'),
                            ],
                          ),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      );
                  },
                  icon: const Icon(Icons.cloud_off_rounded, size: 16),
                  label: const Text('Web Import'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.textMuted,
                    side: const BorderSide(color: AppTheme.border),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Text(
            'AVAILABLE MODELS',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppTheme.textMuted,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 10),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: models.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final model = models[index];
                final isSelected = model.id == widget.selectedModelId;

                return InkWell(
                  onTap: () {
                    widget.onSelectModel(model);
                    Navigator.pop(context);
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.primaryBlue.withValues(alpha: 0.1)
                          : AppTheme.background,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected
                            ? AppTheme.primaryBlue
                            : AppTheme.border,
                        width: isSelected ? 1.5 : 1.0,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          model.isAsset ? Icons.checkroom : Icons.unarchive,
                          color: isSelected
                              ? AppTheme.primaryBlue
                              : AppTheme.textMuted,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                model.title,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: isSelected
                                      ? AppTheme.primaryBlue
                                      : AppTheme.textMain,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${model.category} • ${model.formattedSize}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Extract Texture Button
                        IconButton(
                          icon: const Icon(
                            Icons.file_download_outlined,
                            size: 20,
                            color: AppTheme.primaryBlue,
                          ),
                          tooltip: 'Extract & Save Default Texture (PNG)',
                          onPressed: () => _extractModelTexture(model),
                        ),
                        if (isSelected)
                          const Icon(
                            Icons.check_circle,
                            color: AppTheme.primaryBlue,
                            size: 20,
                          )
                        else if (!model.isAsset)
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              size: 18,
                              color: AppTheme.errorRed,
                            ),
                            onPressed: () async {
                              final deleted = await _storageService.deleteModel(
                                model.id,
                              );
                              if (deleted && context.mounted) {
                                setState(() {});
                              }
                            },
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
