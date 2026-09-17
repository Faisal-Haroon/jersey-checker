import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:screenshot/screenshot.dart';

import '../models/imported_model.dart';
import '../models/selected_file.dart';
import '../services/model_storage_service.dart';
import '../services/screenshot_service.dart';
import '../theme/app_theme.dart';
import '../widgets/model_picker_sheet.dart';
import '../widgets/showcase_overlay.dart';

class JerseyTesterScreen extends StatefulWidget {
  const JerseyTesterScreen({
    super.key,
    required this.selectedJersey,
    required this.onPickJersey,
    required this.viewerKey,
    required this.onResetView,
  });

  final SelectedJerseyFile? selectedJersey;
  final VoidCallback onPickJersey;
  final Key viewerKey;
  final VoidCallback onResetView;

  @override
  State<JerseyTesterScreen> createState() => _JerseyTesterScreenState();
}

class _JerseyTesterScreenState extends State<JerseyTesterScreen> {
  final ShowcaseScreenshotService _screenshotService = ShowcaseScreenshotService();
  final ModelStorageService _modelStorage = ModelStorageService();
  
  Imported3DModel? _activeModel;
  bool _isCapturing = false;
  String _cameraOrbit = '0deg 75deg 105%';

  @override
  void initState() {
    super.initState();
    _initModels();
  }

  Future<void> _initModels() async {
    await _modelStorage.init();
    if (mounted && _modelStorage.models.isNotEmpty) {
      setState(() {
        _activeModel = _modelStorage.models.first;
      });
    }
  }

  void _setAngle(String orbit) {
    setState(() {
      _cameraOrbit = orbit;
    });
  }

  void _openModelPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => FractionallySizedBox(
        heightFactor: 0.75,
        child: ModelPickerSheet(
          selectedModelId: _activeModel?.id ?? '',
          onSelectModel: (model) {
            setState(() {
              _activeModel = model;
            });
            widget.onResetView();
          },
        ),
      ),
    );
  }

  Future<void> _handleTakeShowcase() async {
    setState(() => _isCapturing = true);
    try {
      final imageBytes = await _screenshotService.captureShowcase();
      if (!mounted) return;
      setState(() => _isCapturing = false);

      if (imageBytes == null) {
        _showSnackBar('Failed to capture 3D showcase image.');
        return;
      }

      _showShowcaseDialog(imageBytes);
    } catch (e) {
      if (mounted) {
        setState(() => _isCapturing = false);
        _showSnackBar('Error capturing showcase: $e');
      }
    }
  }

  void _showShowcaseDialog(dynamic imageBytes) {
    showDialog(
      context: context,
      builder: (ctx) {
        bool isSaving = false;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppTheme.cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: AppTheme.border),
              ),
              title: const Row(
                children: [
                  Icon(Icons.camera_alt, color: AppTheme.primaryBlue),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Showcase Ready',
                      style: TextStyle(color: AppTheme.textMain, fontSize: 18),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(
                      imageBytes,
                      height: 240,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Your 3D jersey showcase screenshot is captured!',
                    style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Close'),
                ),
                OutlinedButton.icon(
                  onPressed: isSaving
                      ? null
                      : () async {
                          setDialogState(() => isSaving = true);
                          final success =
                              await _screenshotService.saveToGallery(imageBytes);
                          setDialogState(() => isSaving = false);
                          if (ctx.mounted) {
                            _showSnackBar(
                              success
                                  ? 'Saved to Gallery successfully!'
                                  : 'Could not save to gallery. Check permissions.',
                            );
                          }
                        },
                  icon: const Icon(Icons.download),
                  label: Text(isSaving ? 'Saving...' : 'Save Gallery'),
                ),
                FilledButton.icon(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    _screenshotService.shareShowcase(imageBytes);
                  },
                  icon: const Icon(Icons.share),
                  label: const Text('Share'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showSnackBar(String text) {
    final cleanMsg = text.replaceAll(RegExp(r'^(Exception|PlatformException|FormatException):\s*'), '');
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(cleanMsg),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    String? relatedJs;
    if (widget.selectedJersey != null) {
      final base64Img = base64Encode(widget.selectedJersey!.bytes);
      final ext = widget.selectedJersey!.name.toLowerCase().endsWith('.png') ? 'png' : 'jpeg';
      final dataUrl = 'data:image/$ext;base64,$base64Img';

      relatedJs = '''
        (async function() {
          const modelViewer = document.querySelector('#jersey-3d-player-viewer');
          const applyTexture = async () => {
            if (modelViewer && modelViewer.model) {
              try {
                const texture = await modelViewer.createTexture('$dataUrl');
                const materials = modelViewer.model.materials;
                if (materials && materials.length > 0) {
                  for (let i = 0; i < materials.length; i++) {
                    if (materials[i].pbrMetallicRoughness && materials[i].pbrMetallicRoughness.baseColorTexture) {
                      materials[i].pbrMetallicRoughness.baseColorTexture.setTexture(texture);
                    }
                  }
                }
              } catch (e) {
                console.error('Error applying jersey texture:', e);
              }
            }
          };

          if (modelViewer && modelViewer.model) {
            applyTexture();
          } else if (modelViewer) {
            modelViewer.addEventListener('load', applyTexture);
          }
        })();
      ''';
    }

    final modelSrc = _activeModel == null
        ? 'assets/models/player_model.glb'
        : _activeModel!.isAsset
            ? _activeModel!.filePath
            : 'file://${_activeModel!.filePath}';

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // TOP CLEAN BUTTONS
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _openModelPicker,
                  icon: const Icon(Icons.view_in_ar, size: 18),
                  label: const Text('3D Model'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  onPressed: widget.onPickJersey,
                  icon: const Icon(Icons.texture, size: 18),
                  label: const Text('Texture'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                onPressed: _isCapturing ? null : _handleTakeShowcase,
                icon: const Icon(Icons.camera_alt, size: 18),
                tooltip: 'Take Showcase',
              ),
            ],
          ),
          const SizedBox(height: 8),

          // ACTIVE SELECTIONS STATUS BAR
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.cardColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.border),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle_outline, size: 14, color: AppTheme.primaryBlue),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Model: ${_activeModel?.title ?? "Default"} • Texture: ${widget.selectedJersey?.name ?? "Default"}',
                    style: const TextStyle(fontSize: 11, color: AppTheme.textMuted, fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // FULL 3D VIEWPORT WITH SEPARATE SCREENSHOT CONTAINER & UI BUTTONS OVERLAY
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  // 1. SCREENSHOT CAPTURES ONLY THIS CLEAN STUDIO CONTAINER + 3D MODEL
                  Screenshot(
                    controller: _screenshotService.controller,
                    child: Container(
                      width: double.infinity,
                      height: double.infinity,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF383E45), Color(0xFF1E2228)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                      child: ShowcaseOverlay(
                        child: ModelViewer(
                          key: ValueKey('$modelSrc-${widget.viewerKey}-${widget.selectedJersey?.name}-$_cameraOrbit'),
                          id: 'jersey-3d-player-viewer',
                          src: modelSrc,
                          alt: '3D Kit Model Viewer',
                          autoRotate: false,
                          cameraControls: true,
                          cameraOrbit: _cameraOrbit,
                          touchAction: TouchAction.panY,
                          backgroundColor: Colors.transparent,
                          relatedJs: relatedJs,
                        ),
                      ),
                    ),
                  ),

                  // 2. UI OVERLAY BUTTONS
                  Positioned(
                    top: 10,
                    right: 10,
                    child: IconButton.filledTonal(
                      onPressed: () {
                        _setAngle('0deg 75deg 105%');
                        widget.onResetView();
                      },
                      icon: const Icon(Icons.refresh, size: 18),
                      tooltip: 'Reset Camera',
                    ),
                  ),

                  Positioned(
                    bottom: 12,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _AngleButton(
                              label: 'Front',
                              isSelected: _cameraOrbit == '0deg 75deg 105%',
                              onTap: () => _setAngle('0deg 75deg 105%'),
                            ),
                            const SizedBox(width: 4),
                            _AngleButton(
                              label: 'Right',
                              isSelected: _cameraOrbit == '90deg 75deg 105%',
                              onTap: () => _setAngle('90deg 75deg 105%'),
                            ),
                            const SizedBox(width: 4),
                            _AngleButton(
                              label: 'Back',
                              isSelected: _cameraOrbit == '180deg 75deg 105%',
                              onTap: () => _setAngle('180deg 75deg 105%'),
                            ),
                            const SizedBox(width: 4),
                            _AngleButton(
                              label: 'Left',
                              isSelected: _cameraOrbit == '270deg 75deg 105%',
                              onTap: () => _setAngle('270deg 75deg 105%'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AngleButton extends StatelessWidget {
  const _AngleButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryBlue : Colors.white10,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : Colors.white70,
          ),
        ),
      ),
    );
  }
}
