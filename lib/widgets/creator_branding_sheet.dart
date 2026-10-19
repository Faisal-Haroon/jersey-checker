import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../services/studio_preferences_service.dart';
import '../theme/app_theme.dart';

class CreatorBrandingSheet extends StatefulWidget {
  const CreatorBrandingSheet({
    super.key,
    required this.currentPreferences,
    required this.onApply,
  });

  final StudioPreferences currentPreferences;
  final ValueChanged<StudioPreferences> onApply;

  @override
  State<CreatorBrandingSheet> createState() => _CreatorBrandingSheetState();
}

class _CreatorBrandingSheetState extends State<CreatorBrandingSheet> {
  late bool _isWatermarkEnabled;
  late TextEditingController _nameController;
  late TextEditingController _linkController;
  String? _logoPath;
  bool _isPickingLogo = false;

  @override
  void initState() {
    super.initState();
    _isWatermarkEnabled = widget.currentPreferences.isWatermarkEnabled;
    _nameController = TextEditingController(
      text: widget.currentPreferences.creatorName,
    );
    _linkController = TextEditingController(
      text: widget.currentPreferences.downloadLink,
    );
    _logoPath = widget.currentPreferences.creatorLogoPath;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _linkController.dispose();
    super.dispose();
  }

  Future<void> _pickLogo() async {
    setState(() => _isPickingLogo = true);
    try {
      final res = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['png', 'jpg', 'jpeg'],
      );
      if (res != null && res.files.single.path != null) {
        final sourceFile = File(res.files.single.path!);
        final appDir = await getApplicationDocumentsDirectory();
        final ext = p.extension(sourceFile.path).isNotEmpty
            ? p.extension(sourceFile.path)
            : '.png';

        // Clean up any old logo files in appDir
        try {
          final entries = appDir.listSync();
          for (final entry in entries) {
            final name = p.basename(entry.path);
            if (name.startsWith('creator_logo')) {
              entry.deleteSync();
            }
          }
        } catch (_) {}

        // Unique filename with timestamp so imageCache never serves stale image
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final destPath = p.join(appDir.path, 'creator_logo_$timestamp$ext');
        await sourceFile.copy(destPath);

        // Clear image cache so new image loads immediately
        PaintingBinding.instance.imageCache.clear();
        PaintingBinding.instance.imageCache.clearLiveImages();

        setState(() {
          _logoPath = destPath;
          _isWatermarkEnabled = true;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick logo: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isPickingLogo = false);
    }
  }

  void _removeLogo() {
    if (_logoPath != null) {
      try {
        final file = File(_logoPath!);
        if (file.existsSync()) file.deleteSync();
      } catch (_) {}
    }
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
    setState(() {
      _logoPath = null;
    });
  }

  void _saveAndApply() {
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
    final updated = widget.currentPreferences.copyWith(
      isWatermarkEnabled: _isWatermarkEnabled,
      creatorName: _nameController.text.trim(),
      creatorLogoPath: _logoPath,
      clearLogo: _logoPath == null,
      downloadLink: _linkController.text.trim(),
    );
    StudioPreferencesService().savePreferences(updated);
    widget.onApply(updated);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: AppTheme.border),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
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

              // Title Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.verified_rounded, color: AppTheme.primaryBlue, size: 22),
                      SizedBox(width: 8),
                      Text(
                        'Creator Branding',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textMain,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Add your channel name or logo as a watermark behind the 3D model when showcasing kits.',
                style: TextStyle(fontSize: 12, color: AppTheme.textMuted, height: 1.4),
              ),
              const SizedBox(height: 16),

              // Master Toggle Card
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: _isWatermarkEnabled
                      ? AppTheme.primaryBlue.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _isWatermarkEnabled
                        ? AppTheme.primaryBlue.withValues(alpha: 0.3)
                        : AppTheme.border,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isWatermarkEnabled
                          ? Icons.branding_watermark_rounded
                          : Icons.branding_watermark_outlined,
                      color: _isWatermarkEnabled
                          ? AppTheme.primaryBlue
                          : AppTheme.textMuted,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Show Backdrop Watermark',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textMain,
                            ),
                          ),
                          Text(
                            'Displays behind model in 3D & Screenshots',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppTheme.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _isWatermarkEnabled,
                      activeThumbColor: AppTheme.primaryBlue,
                      onChanged: (val) {
                        setState(() => _isWatermarkEnabled = val);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Creator / Channel Name Field
              const Text(
                'CREATOR / CHANNEL NAME',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textMuted,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: 'e.g. BOBZIE MODS or CRICKET STUDIO',
                  hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
                  prefixIcon: const Icon(Icons.person_rounded, size: 20),
                  filled: true,
                  fillColor: Colors.black.withValues(alpha: 0.03),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppTheme.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppTheme.border),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Channel Logo Picker Section
              const Text(
                'CHANNEL LOGO (OPTIONAL PNG)',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textMuted,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 8),
              if (_logoPath != null && File(_logoPath!).existsSync()) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          File(_logoPath!),
                          key: ValueKey(_logoPath),
                          width: 48,
                          height: 48,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Custom Logo Active',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textMain,
                              ),
                            ),
                            Text(
                              'Rendered centrally behind model',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppTheme.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, color: AppTheme.primaryBlue, size: 20),
                        tooltip: 'Change Logo',
                        onPressed: _isPickingLogo ? null : _pickLogo,
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                        tooltip: 'Remove Logo',
                        onPressed: _removeLogo,
                      ),
                    ],
                  ),
                ),
              ] else ...[
                OutlinedButton.icon(
                  onPressed: _isPickingLogo ? null : _pickLogo,
                  icon: const Icon(Icons.upload_file_rounded, size: 18),
                  label: Text(_isPickingLogo ? 'Opening...' : 'Select Channel Logo (PNG)'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 18),

              // Download / Kit Link
              const Text(
                'KIT DOWNLOAD / CHANNEL LINK',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textMuted,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _linkController,
                decoration: InputDecoration(
                  hintText: 'e.g. https://t.me/yourchannel or drive link',
                  hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
                  prefixIcon: const Icon(Icons.link_rounded, size: 20),
                  filled: true,
                  fillColor: Colors.black.withValues(alpha: 0.03),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppTheme.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppTheme.border),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'This link will be attached when sharing your showcase image.',
                style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
              ),
              const SizedBox(height: 24),

              // Action Button
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _saveAndApply,
                  icon: const Icon(Icons.check_circle_outline, size: 18),
                  label: const Text(
                    'Save & Apply Branding',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
