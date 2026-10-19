import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:screenshot/screenshot.dart';

import '../models/imported_model.dart';
import '../models/selected_file.dart';
import '../services/model_storage_service.dart';
import '../services/screenshot_service.dart';
import '../services/studio_preferences_service.dart';
import '../theme/app_theme.dart';
import '../widgets/banner_ad_widget.dart';
import '../widgets/creator_branding_sheet.dart';
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
  final ShowcaseScreenshotService _screenshotService =
      ShowcaseScreenshotService();
  final ModelStorageService _modelStorage = ModelStorageService();

  // Default coin shown on every app open
  static final Imported3DModel _defaultCoinModel = Imported3DModel(
    id: '__default_coin__',
    title: 'Bobzie X Coin',
    filePath: 'assets/models/coin.glb',
    isAsset: true,
    sizeBytes: 0,
    addedDate: DateTime(2024),
    category: 'Default',
  );

  late Imported3DModel _activeModel;
  bool _isCapturing = false;
  bool _isTransparentCapture = false;
  bool _isAutoRotateEnabled = true;
  String _cameraOrbit = '0deg 75deg 250%';
  double _modelExposure = 1.0;
  bool _showBrightnessSlider = false;
  bool _showMoreTools = false;
  dynamic _webViewController;

  final StudioPreferencesService _prefsService = StudioPreferencesService();
  bool _isGridEnabled = true;
  bool _isWatermarkEnabled = false;
  String _creatorName = '';
  String? _creatorLogoPath;
  String _downloadLink = '';

  double _viewportHeight = 650.0;
  double _viewportWidth = 360.0;
  static const double _topHudHeight = 82.0;

  String get _modelRadius =>
      _activeModel.id == '__default_coin__' ? '250%' : '142%';
  String get _currentFrontOrbit => '0deg 75deg $_modelRadius';
  String get _currentRightOrbit => '90deg 75deg $_modelRadius';
  String get _currentBackOrbit => '180deg 75deg $_modelRadius';
  String get _currentLeftOrbit => '270deg 75deg $_modelRadius';

  @override
  void initState() {
    super.initState();
    _activeModel = _defaultCoinModel; // Always start with coin
    _initModels();
    _initStudioPrefs();
  }

  Future<void> _initStudioPrefs() async {
    await _prefsService.init();
    final prefs = _prefsService.preferences;
    if (mounted) {
      setState(() {
        _isGridEnabled = prefs.isGridEnabled;
        _isWatermarkEnabled = prefs.isWatermarkEnabled;
        _creatorName = prefs.creatorName;
        _creatorLogoPath = prefs.creatorLogoPath;
        _downloadLink = prefs.downloadLink;
        _modelExposure = prefs.modelExposure;
      });
    }
  }

  void _toggleGrid() {
    setState(() => _isGridEnabled = !_isGridEnabled);
    _prefsService.savePreferences(
      _prefsService.preferences.copyWith(isGridEnabled: _isGridEnabled),
    );
  }

  void _updateExposure(double val) {
    final clamped = double.parse(val.clamp(0.5, 2.0).toStringAsFixed(2));
    setState(() {
      _modelExposure = clamped;
    });
    _webViewController?.runJavaScript(
      "var mv = document.querySelector('#jersey-3d-player-viewer') || document.querySelector('model-viewer'); if (mv) { mv.setAttribute('exposure', '$clamped'); mv.exposure = $clamped; }",
    );
  }

  void _saveExposurePreference() {
    _prefsService.savePreferences(
      _prefsService.preferences.copyWith(modelExposure: _modelExposure),
    );
  }

  Widget _buildVerticalBrightnessSlider() {
    const double sliderHeight = 100.0;
    final double ratio = ((_modelExposure - 0.5) / 1.5).clamp(0.0, 1.0);

    return Container(
      width: 36,
      height: sliderHeight,
      decoration: BoxDecoration(
        color: const Color(0xFF1E2228).withValues(alpha: 0.90),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFFBBF24).withValues(alpha: 0.5),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFBBF24).withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(19),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (details) {
            final r = (1.0 - (details.localPosition.dy / sliderHeight))
                .clamp(0.0, 1.0);
            _updateExposure(0.5 + r * 1.5);
            _saveExposurePreference();
          },
          onPanUpdate: (details) {
            final r = (1.0 - (details.localPosition.dy / sliderHeight))
                .clamp(0.0, 1.0);
            _updateExposure(0.5 + r * 1.5);
          },
          onPanEnd: (_) => _saveExposurePreference(),
          onDoubleTap: () {
            // Instant reset to Studio default (1.0x)
            _updateExposure(1.0);
            _saveExposurePreference();
          },
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              // Filled Level Indicator from bottom to top
              FractionallySizedBox(
                heightFactor: ratio,
                alignment: Alignment.bottomCenter,
                child: Container(
                  width: 40,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Color(0xFFD97706),
                        Color(0xFFFBBF24),
                      ],
                    ),
                  ),
                ),
              ),

              // Visual Icons & Text Indicator
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Top (Max Brightness Indicator)
                    const Icon(
                      Icons.wb_sunny_rounded,
                      size: 14,
                      color: Colors.white,
                    ),

                    // Center Value (e.g. 1.2x)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${_modelExposure.toStringAsFixed(1)}x',
                        style: const TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),

                    // Bottom (Min Brightness Indicator)
                    Icon(
                      Icons.brightness_low_rounded,
                      size: 13,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openCreatorBrandingSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: CreatorBrandingSheet(
          currentPreferences: _prefsService.preferences,
          onApply: (updated) {
            PaintingBinding.instance.imageCache.clear();
            PaintingBinding.instance.imageCache.clearLiveImages();
            setState(() {
              _isWatermarkEnabled = updated.isWatermarkEnabled;
              _creatorName = updated.creatorName;
              _creatorLogoPath = updated.creatorLogoPath;
              _downloadLink = updated.downloadLink;
            });
          },
        ),
      ),
    );
  }

  Future<void> _initModels() async {
    await _modelStorage.init();

    // Check if user previously selected a model and load it
    final lastModelId = await _modelStorage.getLastSelectedModelId();
    if (lastModelId != null && mounted) {
      try {
        final lastModel = _modelStorage.models.firstWhere(
          (m) => m.id == lastModelId,
        );
        setState(() {
          _activeModel = lastModel;
          _cameraOrbit = '0deg 75deg $_modelRadius';
        });
      } catch (_) {
        // Fallback to coin if the last selected model was deleted
      }
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
          selectedModelId: _activeModel.id,
          onSelectModel: (model) {
            setState(() {
              _activeModel = model;
              _cameraOrbit = '0deg 75deg $_modelRadius';
            });
            _modelStorage.saveLastSelectedModelId(model.id); // Save preference
            widget.onResetView();
          },
        ),
      ),
    );
  }

  void _openCaptureModeSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: AppTheme.border),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Row(
                  children: [
                    Icon(Icons.camera_alt_rounded,
                        color: AppTheme.primaryBlue, size: 22),
                    SizedBox(width: 8),
                    Text(
                      'Capture 3D Showcase',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textMain,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Choose background style for your capture:',
                  style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                ),
                const SizedBox(height: 18),

                // Option 1: Studio Background
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () {
                      Navigator.pop(ctx);
                      _handleTakeShowcase(isTransparent: false);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.wallpaper_rounded,
                                color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Studio Background',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.textMain,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Includes studio gradient / grid & creator watermark',
                                  style: TextStyle(
                                      fontSize: 11.5, color: AppTheme.textMuted),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios_rounded,
                              size: 14, color: AppTheme.textMuted),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Option 2: Transparent PNG
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () {
                      Navigator.pop(ctx);
                      _handleTakeShowcase(isTransparent: true);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: const Color(0xFF8B5CF6).withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.auto_awesome_rounded,
                                color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Transparent PNG (No Background)',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.textMain,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Pure 3D model cutout • Perfect for YouTube thumbnails & edits',
                                  style: TextStyle(
                                      fontSize: 11.5, color: AppTheme.textMuted),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios_rounded,
                              size: 14, color: AppTheme.textMuted),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleTakeShowcase({bool isTransparent = false}) async {
    setState(() {
      _isCapturing = true;
      _isTransparentCapture = isTransparent;
    });
    // Give time for UI to build before capturing
    await Future.delayed(const Duration(milliseconds: 120));
    try {
      final topCropRatio = (_topHudHeight / _viewportHeight).clamp(0.06, 0.22);
      final imageBytes = await _screenshotService.captureShowcase(
        topCropRatio: topCropRatio,
        aspectRatio: 3 / 4,
      );
      if (!mounted) return;
      setState(() {
        _isCapturing = false;
        _isTransparentCapture = false;
      });

      if (imageBytes == null) {
        _showSnackBar('Failed to capture 3D showcase image.');
        return;
      }

      _showShowcaseDialog(imageBytes, isTransparent: isTransparent);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCapturing = false;
          _isTransparentCapture = false;
        });
        _showSnackBar('Error capturing showcase: $e');
      }
    }
  }

  void _showShowcaseDialog(dynamic imageBytes, {bool isTransparent = false}) {
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
              title: Row(
                children: [
                  Icon(
                    isTransparent
                        ? Icons.auto_awesome_rounded
                        : Icons.camera_alt_rounded,
                    color: isTransparent
                        ? const Color(0xFF8B5CF6)
                        : AppTheme.primaryBlue,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    isTransparent ? 'Transparent Cutout' : 'Captured Showcase',
                    style: const TextStyle(
                      color: AppTheme.textMain,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      constraints: const BoxConstraints(maxHeight: 280),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: AspectRatio(
                        aspectRatio: 3 / 4,
                        child: isTransparent
                            ? CustomPaint(
                                painter: const _CheckerboardPainter(),
                                child: Image.memory(
                                  imageBytes,
                                  fit: BoxFit.contain,
                                ),
                              )
                            : Image.memory(
                                imageBytes,
                                fit: BoxFit.contain,
                              ),
                      ),
                    ),
                  ),
                  if (isTransparent) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color:
                            const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFF8B5CF6)
                              .withValues(alpha: 0.25),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle_rounded,
                              size: 12, color: Color(0xFF8B5CF6)),
                          SizedBox(width: 5),
                          Text(
                            'Transparent PNG (Alpha Channel)',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF8B5CF6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              actionsAlignment: MainAxisAlignment.spaceEvenly,
              actionsPadding: const EdgeInsets.only(
                bottom: 16,
                left: 16,
                right: 16,
              ),
              actions: [
                Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () {
                              Navigator.of(ctx).pop();
                              final shareText = isTransparent
                                  ? '🏏 3D Kit Cutout by ${_creatorName.isNotEmpty ? _creatorName : "Jersey Checker"}\nCrafted with Jersey Checker 3D'
                                  : (_downloadLink.isNotEmpty
                                      ? '🏏 Custom Kit by ${_creatorName.isNotEmpty ? _creatorName : "Jersey Checker"}\n📥 Download: $_downloadLink\nCrafted with Jersey Checker 3D'
                                      : (_creatorName.isNotEmpty
                                          ? '🏏 Custom Kit by $_creatorName • Crafted with Jersey Checker 3D'
                                          : 'Created with Jersey Checker 3D'));
                              _screenshotService.shareShowcase(
                                imageBytes,
                                customText: shareText,
                              );
                            },
                            icon: const Icon(Icons.share, size: 18),
                            label: const Text('Share'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: isSaving
                                ? null
                                : () async {
                                    setDialogState(() => isSaving = true);
                                    final success = await _screenshotService
                                        .saveToGallery(imageBytes);
                                    setDialogState(() => isSaving = false);
                                    if (ctx.mounted) {
                                      _showSnackBar(
                                        success
                                            ? 'Saved to Gallery successfully!'
                                            : 'Could not save to gallery. Check permissions.',
                                      );
                                    }
                                  },
                            icon: const Icon(Icons.download, size: 17),
                            label: Text(isSaving ? 'Saving' : 'Save'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(color: AppTheme.textMuted),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showSnackBar(String text) {
    final cleanMsg = text.replaceAll(
      RegExp(r'^(Exception|PlatformException|FormatException):\s*'),
      '',
    );
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(cleanMsg),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final exposureJs = '''
      const mv = document.querySelector('#jersey-3d-player-viewer');
      if (mv) {
        mv.exposure = $_modelExposure;
        mv.setAttribute('exposure', '$_modelExposure');
      }
    ''';

    String? relatedJs;
    if (widget.selectedJersey != null) {
      final base64Img = base64Encode(widget.selectedJersey!.bytes);
      final ext = widget.selectedJersey!.name.toLowerCase().endsWith('.png')
          ? 'png'
          : 'jpeg';
      final dataUrl = 'data:image/$ext;base64,$base64Img';

      relatedJs =
          '''
        (async function() {
          $exposureJs
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
    } else {
      relatedJs = '''
        (async function() {
          $exposureJs
        })();
      ''';
    }

    final modelSrc = _activeModel.isAsset
        ? _activeModel.filePath
        : 'file://${_activeModel.filePath}';

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Column(
        children: [
          // FULL 3D VIEWPORT (Takes all available space up to the top of screen)
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                _viewportHeight = constraints.maxHeight;
                _viewportWidth = constraints.maxWidth;
                final frameWidth = _viewportWidth;
                final maxAvailableHeight = (_viewportHeight - _topHudHeight).clamp(0.0, double.infinity);
                final frameHeight = (_viewportWidth * (4 / 3)).clamp(0.0, maxAvailableHeight);
                final frameBottom = _topHudHeight + frameHeight;

                return Stack(
                  children: [
                    // 1. SCREENSHOT CAPTURES ONLY THIS CLEAN STUDIO CONTAINER + 3D MODEL
                    Screenshot(
                      controller: _screenshotService.controller,
                      child: Container(
                        width: double.infinity,
                        height: double.infinity,
                        decoration: _isTransparentCapture
                            ? const BoxDecoration(color: Colors.transparent)
                            : BoxDecoration(
                                gradient: _isGridEnabled
                                    ? const LinearGradient(
                                        colors: [
                                          Color(0xFF383E45),
                                          Color(0xFF1E2228),
                                        ],
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                      )
                                    : const RadialGradient(
                                        center: Alignment(0.0, -0.15),
                                        radius: 0.95,
                                        colors: [
                                          Color(0xFF4A525D),
                                          Color(0xFF1A1D21),
                                        ],
                                      ),
                              ),
                        child: Stack(
                          children: [
                            // Grid pattern
                            if (_isGridEnabled && !_isTransparentCapture)
                              const Positioned.fill(
                                child:
                                    CustomPaint(painter: _BlenderGridPainter()),
                              ),

                            // Backdrop Watermark (Slanted Athletic Ribbon in 3:4 frame)
                            if (_isWatermarkEnabled && !_isTransparentCapture) ...[
                              Positioned(
                                top: _topHudHeight,
                                left: 0,
                                width: frameWidth,
                                height: frameHeight,
                                child: Center(
                                  child: _creatorLogoPath != null &&
                                          File(_creatorLogoPath!).existsSync()
                                      ? Opacity(
                                          opacity: 0.22,
                                          child: Image.file(
                                            File(_creatorLogoPath!),
                                            key: ValueKey(
                                                '$_creatorLogoPath-${File(_creatorLogoPath!).lastModifiedSync().millisecondsSinceEpoch}'),
                                            width: 180,
                                            height: 180,
                                            fit: BoxFit.contain,
                                          ),
                                        )
                                      : (_creatorName.isNotEmpty
                                          ? Transform.rotate(
                                              angle: -0.21, // ~ -12 deg slanted athletic ribbon
                                              child: Opacity(
                                                opacity: 0.22,
                                                child: SizedBox(
                                                  width: frameWidth * 1.3,
                                                  child: Column(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Container(
                                                        height: 2,
                                                        width: double.infinity,
                                                        decoration:
                                                            BoxDecoration(
                                                          gradient:
                                                              LinearGradient(
                                                            colors: [
                                                              Colors.transparent,
                                                              Colors.white
                                                                  .withValues(
                                                                      alpha:
                                                                          0.5),
                                                              Colors.transparent,
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(height: 6),
                                                      Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                        children: [
                                                          Text(
                                                            '// ',
                                                            style: TextStyle(
                                                              fontSize: 22,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w900,
                                                              color: Colors
                                                                  .blue
                                                                  .shade300,
                                                              fontStyle:
                                                                  FontStyle
                                                                      .italic,
                                                            ),
                                                          ),
                                                          Flexible(
                                                            child: Text(
                                                              _creatorName
                                                                  .toUpperCase(),
                                                              textAlign:
                                                                  TextAlign
                                                                      .center,
                                                              maxLines: 1,
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                              style:
                                                                  const TextStyle(
                                                                fontSize: 26,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w900,
                                                                color: Colors
                                                                    .white,
                                                                letterSpacing:
                                                                    4.5,
                                                                fontStyle:
                                                                    FontStyle
                                                                        .italic,
                                                              ),
                                                            ),
                                                          ),
                                                          Text(
                                                            ' //',
                                                            style: TextStyle(
                                                              fontSize: 22,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w900,
                                                              color: Colors
                                                                  .blue
                                                                  .shade300,
                                                              fontStyle:
                                                                  FontStyle
                                                                      .italic,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      const SizedBox(height: 6),
                                                      Container(
                                                        height: 2,
                                                        width: double.infinity,
                                                        decoration:
                                                            BoxDecoration(
                                                          gradient:
                                                              LinearGradient(
                                                            colors: [
                                                              Colors.transparent,
                                                              Colors.white
                                                                  .withValues(
                                                                      alpha:
                                                                          0.5),
                                                              Colors.transparent,
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            )
                                          : const SizedBox.shrink()),
                                ),
                              ),
                              if (_creatorName.isNotEmpty && !_isTransparentCapture)
                                Positioned(
                                  top: frameBottom - 34,
                                  left: 14,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3.5,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.black.withValues(alpha: 0.6),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Colors.white
                                            .withValues(alpha: 0.18),
                                        width: 0.8,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.verified_rounded,
                                          size: 11,
                                          color: AppTheme.primaryBlue,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          _creatorName,
                                          style: const TextStyle(
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.w800,
                                            color: Colors.white,
                                            letterSpacing: 0.3,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],

                            // 3D Model with watermark overlay
                            ShowcaseOverlay(
                              showWatermark: _isCapturing,
                              watermarkTop: frameBottom - 34,
                              child: Padding(
                                padding:
                                    const EdgeInsets.only(top: 40, bottom: 8),
                                child: ModelViewer(
                                  key: ValueKey(
                                    '$modelSrc-${widget.viewerKey}-${widget.selectedJersey?.name}-$_cameraOrbit-$_isAutoRotateEnabled',
                                  ),
                                  id: 'jersey-3d-player-viewer',
                                  src: modelSrc,
                                  alt: '3D Kit Model Viewer',
                                  autoRotate: true,
                                  autoRotateDelay: 0,
                                  rotationPerSecond: _isAutoRotateEnabled
                                      ? '15deg'
                                      : '0deg',
                                  cameraControls: true,
                                  cameraOrbit: _cameraOrbit,
                                  minCameraOrbit: 'auto auto 100%',
                                  maxCameraOrbit: 'auto auto 600%',
                                  touchAction: TouchAction.panY,
                                  backgroundColor: Colors.transparent,
                                  exposure: _modelExposure,
                                  onWebViewCreated: (controller) {
                                    _webViewController = controller;
                                  },
                                  relatedJs: relatedJs,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 2. FLOATING TOP HUD (Model, Texture, Menu, Camera)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E2228).withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.15),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.35),
                              blurRadius: 14,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: _StudioHudButton(
                                icon: Icons.view_in_ar_rounded,
                                label: '3D Model',
                                onTap: _openModelPicker,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _StudioHudButton(
                                icon: Icons.texture_rounded,
                                label: 'Texture',
                                isPrimary: true,
                                onTap: widget.onPickJersey,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                onPressed: _isCapturing
                                    ? null
                                    : _openCaptureModeSelector,
                                icon: const Icon(
                                  Icons.camera_alt_rounded,
                                  size: 18,
                                  color: Colors.white,
                                ),
                                tooltip: 'Take Showcase',
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(minWidth: 38, minHeight: 38),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // 3. RIGHT FLOATING CONTROLS (Collapsible)
                Positioned(
                  top: 75,
                  right: 14,
                  child: SafeArea(
                    bottom: false,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // ── ALWAYS VISIBLE ──────────────────────────
                        // Reset Camera
                        GestureDetector(
                          onTap: () {
                            _setAngle('0deg 75deg $_modelRadius');
                            widget.onResetView();
                          },
                          child: Container(
                            width: 36,
                            height: 36,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E2228).withValues(alpha: 0.85),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.25),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.refresh_rounded,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 7),

                        // 360° Auto Rotate
                        GestureDetector(
                          onTap: () => setState(() => _isAutoRotateEnabled = !_isAutoRotateEnabled),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 36,
                            height: 36,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _isAutoRotateEnabled
                                  ? AppTheme.primaryBlue
                                  : const Color(0xFF1E2228).withValues(alpha: 0.85),
                              border: Border.all(
                                color: _isAutoRotateEnabled
                                    ? Colors.blue.shade300
                                    : Colors.white.withValues(alpha: 0.15),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.25),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Text(
                              '360°',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        // Gap between 360 and tune/more toggle
                        const SizedBox(height: 12),

                        // ── MORE / LESS TOGGLE (tune icon) ───────────────────
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _showMoreTools = !_showMoreTools;
                              if (!_showMoreTools) _showBrightnessSlider = false;
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 36,
                            height: 36,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _showMoreTools
                                  ? const Color(0xFF374151).withValues(alpha: 0.95)
                                  : const Color(0xFF1E2228).withValues(alpha: 0.85),
                              border: Border.all(
                                color: _showMoreTools
                                    ? Colors.white.withValues(alpha: 0.35)
                                    : Colors.white.withValues(alpha: 0.15),
                                width: _showMoreTools ? 1.5 : 1.0,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: AnimatedRotation(
                              turns: _showMoreTools ? 0.5 : 0.0,
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeInOut,
                              child: Icon(
                                Icons.tune_rounded,
                                size: 16,
                                color: _showMoreTools
                                    ? Colors.white
                                    : Colors.white.withValues(alpha: 0.75),
                              ),
                            ),
                          ),
                        ),

                        // ── EXPANDABLE PRO TOOLS ─────────────────────
                        AnimatedSize(
                          duration: const Duration(milliseconds: 280),
                          curve: Curves.easeInOut,
                          alignment: Alignment.topCenter,
                          child: _showMoreTools
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    const SizedBox(height: 8),
                                    // Thin divider
                                    Container(
                                      width: 20,
                                      height: 1,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(1),
                                      ),
                                    ),
                                    const SizedBox(height: 8),

                                    // Grid / Spotlight Toggle
                                    GestureDetector(
                                      onTap: _toggleGrid,
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 200),
                                        width: 36,
                                        height: 36,
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF1E2228).withValues(alpha: 0.85),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: _isGridEnabled
                                                ? Colors.white.withValues(alpha: 0.15)
                                                : AppTheme.primaryBlue,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(alpha: 0.25),
                                              blurRadius: 6,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Icon(
                                          _isGridEnabled
                                              ? Icons.grid_on_rounded
                                              : Icons.wb_sunny_rounded,
                                          size: 16,
                                          color: _isGridEnabled
                                              ? Colors.white
                                              : const Color(0xFF60A5FA),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 7),

                                    // Creator Branding
                                    GestureDetector(
                                      onTap: _openCreatorBrandingSheet,
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 200),
                                        width: 36,
                                        height: 36,
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: _isWatermarkEnabled
                                              ? AppTheme.primaryBlue.withValues(alpha: 0.85)
                                              : const Color(0xFF1E2228).withValues(alpha: 0.85),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: _isWatermarkEnabled
                                                ? Colors.blue.shade200
                                                : Colors.white.withValues(alpha: 0.15),
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(alpha: 0.25),
                                              blurRadius: 6,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: const Icon(
                                          Icons.verified_rounded,
                                          size: 16,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 7),

                                    // Brightness Toggle
                                    GestureDetector(
                                      onTap: () => setState(() => _showBrightnessSlider = !_showBrightnessSlider),
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 200),
                                        width: 36,
                                        height: 36,
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: _showBrightnessSlider
                                              ? const Color(0xFFFBBF24).withValues(alpha: 0.25)
                                              : const Color(0xFF1E2228).withValues(alpha: 0.85),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: (_showBrightnessSlider || (_modelExposure - 1.0).abs() > 0.05)
                                                ? const Color(0xFFFBBF24)
                                                : Colors.white.withValues(alpha: 0.15),
                                            width: _showBrightnessSlider ? 1.5 : 1.0,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: _showBrightnessSlider
                                                  ? const Color(0xFFFBBF24).withValues(alpha: 0.3)
                                                  : Colors.black.withValues(alpha: 0.25),
                                              blurRadius: 6,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Icon(
                                          Icons.wb_sunny_rounded,
                                          size: 16,
                                          color: (_showBrightnessSlider || (_modelExposure - 1.0).abs() > 0.05)
                                              ? const Color(0xFFFBBF24)
                                              : Colors.white,
                                        ),
                                      ),
                                    ),
                                    if (_showBrightnessSlider) ...[
                                      const SizedBox(height: 7),
                                      _buildVerticalBrightnessSlider(),
                                    ],
                                  ],
                                )
                              : const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ),
                ),

                // 4. BOTTOM ANGLE BUTTONS
                Positioned(
                  bottom: 12,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E2228).withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.15),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _AngleButton(
                            label: 'Front',
                            isSelected: _cameraOrbit.startsWith('0deg'),
                            onTap: () => _setAngle(_currentFrontOrbit),
                          ),
                          const SizedBox(width: 4),
                          _AngleButton(
                            label: 'Right',
                            isSelected: _cameraOrbit.startsWith('90deg'),
                            onTap: () => _setAngle(_currentRightOrbit),
                          ),
                          const SizedBox(width: 4),
                          _AngleButton(
                            label: 'Back',
                            isSelected: _cameraOrbit.startsWith('180deg'),
                            onTap: () => _setAngle(_currentBackOrbit),
                          ),
                          const SizedBox(width: 4),
                          _AngleButton(
                            label: 'Left',
                            isSelected: _cameraOrbit.startsWith('270deg'),
                            onTap: () => _setAngle(_currentLeftOrbit),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),

          // STICKY BOTTOM BANNER AD
          const AppBannerWidget(topPadding: 4, bottomPadding: 2),
        ],
      ),
    );
  }
}

class _StudioHudButton extends StatelessWidget {
  const _StudioHudButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isPrimary = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          decoration: BoxDecoration(
            color: isPrimary
                ? AppTheme.primaryBlue
                : Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isPrimary
                  ? Colors.blue.shade300.withValues(alpha: 0.5)
                  : Colors.white.withValues(alpha: 0.15),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: Colors.white),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.2,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
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

class _BlenderGridPainter extends CustomPainter {
  const _BlenderGridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..strokeWidth = 1.0;

    final axisPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..strokeWidth = 1.5;

    final double step = 40.0;

    final centerX = size.width / 2;
    final centerY = size.height / 2;

    // Draw vertical lines
    for (double i = 0; centerX + i < size.width; i += step) {
      canvas.drawLine(
        Offset(centerX + i, 0),
        Offset(centerX + i, size.height),
        i == 0 ? axisPaint : paint,
      );
      if (i > 0) {
        canvas.drawLine(
          Offset(centerX - i, 0),
          Offset(centerX - i, size.height),
          paint,
        );
      }
    }

    // Draw horizontal lines
    for (double i = 0; centerY + i < size.height; i += step) {
      canvas.drawLine(
        Offset(0, centerY + i),
        Offset(size.width, centerY + i),
        i == 0 ? axisPaint : paint,
      );
      if (i > 0) {
        canvas.drawLine(
          Offset(0, centerY - i),
          Offset(size.width, centerY - i),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CheckerboardPainter extends CustomPainter {
  const _CheckerboardPainter();

  @override
  void paint(Canvas canvas, Size size) {
    const squareSize = 10.0;
    final paintLight = Paint()..color = const Color(0xFF2A2E35);
    final paintDark = Paint()..color = const Color(0xFF1E2228);

    for (double y = 0; y < size.height; y += squareSize) {
      for (double x = 0; x < size.width; x += squareSize) {
        final isEven =
            ((x / squareSize).floor() + (y / squareSize).floor()) % 2 == 0;
        canvas.drawRect(
          Rect.fromLTWH(x, y, squareSize, squareSize),
          isEven ? paintLight : paintDark,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
