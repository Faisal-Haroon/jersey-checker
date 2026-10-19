import 'package:flutter/material.dart';

import '../services/ad_service.dart';
import '../services/network_service.dart';
import '../theme/app_theme.dart';
import '../widgets/banner_ad_widget.dart';
import 'converter_screen.dart';

/// Selection Hub for the Converter feature.
/// Presents two prominent, beautifully styled cards:
/// 1. PNG → File
/// 2. File → PNG
///
/// Clicking either checks internet connectivity, triggers an interstitial ad,
/// and navigates directly into the Converter screen with the chosen mode.
class ConvertModePickerScreen extends StatelessWidget {
  const ConvertModePickerScreen({
    super.key,
    required this.onSelectMode,
  });

  final ValueChanged<ConversionMode> onSelectMode;

  Future<void> _handleModeSelection(
    BuildContext context,
    ConversionMode mode,
  ) async {
    // Check internet connection
    final isOnline = await NetworkService.hasInternetConnection();
    if (!context.mounted) return;

    if (!isOnline) {
      _showNoInternetDialog(context, mode);
      return;
    }

    // Show interstitial ad if ready at this natural transition
    AdService.instance.showInterstitialIfReady(
      actionInterval: 1,
      onDone: () => onSelectMode(mode),
    );
  }

  void _showNoInternetDialog(BuildContext context, ConversionMode mode) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        backgroundColor: Colors.white,
        contentPadding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: const Icon(
                Icons.wifi_off_rounded,
                color: Color(0xFFEF4444),
                size: 28,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Internet Required',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'An active internet connection is required to use this conversion tool.\n\nPlease turn on Wi-Fi or Mobile Data and try again.',
              style: TextStyle(
                fontSize: 12.5,
                color: Color(0xFF64748B),
                height: 1.45,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _handleModeSelection(context, mode);
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Retry',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Select Converter Tool',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
                color: AppTheme.textMain,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 9,
                vertical: 3.5,
              ),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                '2 TOOLS',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.primaryBlue,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // ── CARD 1: PNG TO FILE ────────────────────────────────
        _ModeSelectionCard(
          title: 'PNG → File',
          subtitle: 'Convert PNG textures into Jersey files',
          accentColor: AppTheme.primaryBlue,
          accentBgColor: const Color(0xFFEFF6FF),
          imageAsset: 'assets/pngtofile.webp',
          onTap: () => _handleModeSelection(context, ConversionMode.pngToBytes),
        ),
        const SizedBox(height: 12),

        // ── CARD 2: FILE TO PNG ────────────────────────────────
        _ModeSelectionCard(
          title: 'File → PNG',
          subtitle: 'Extract PNG textures from Jersey files',
          accentColor: const Color(0xFF10B981),
          accentBgColor: const Color(0xFFECFDF5),
          imageAsset: 'assets/filetopng.webp',
          onTap: () => _handleModeSelection(context, ConversionMode.bytesToPng),
        ),
        const SizedBox(height: 18),

        // ── MREC AD PLACEMENT (HIGH EARNING OPPORTUNITY) ────────
        const AppMrecWidget(),
      ],
    );
  }
}

class _ModeSelectionCard extends StatelessWidget {
  const _ModeSelectionCard({
    required this.title,
    required this.subtitle,
    required this.accentColor,
    required this.accentBgColor,
    required this.imageAsset,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final Color accentColor;
  final Color accentBgColor;
  final String imageAsset;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: accentColor.withValues(alpha: 0.1),
        highlightColor: accentColor.withValues(alpha: 0.05),
        child: Ink(
          decoration: BoxDecoration(
            color: AppTheme.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: accentColor.withValues(alpha: 0.35),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: accentColor.withValues(alpha: 0.06),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              // Visual Illustration Image Card
              Container(
                width: 90,
                height: 54,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: accentColor.withValues(alpha: 0.35),
                    width: 1.2,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.asset(
                    imageAsset,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Title & Subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                        color: AppTheme.textMain,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Action Arrow Indicator Circle
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 13,
                  color: accentColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
