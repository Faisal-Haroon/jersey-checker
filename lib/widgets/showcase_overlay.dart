import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class ShowcaseOverlay extends StatelessWidget {
  const ShowcaseOverlay({
    super.key,
    required this.child,
    this.watermarkText = '',
    this.showBadge = false,
    this.showWatermark = false,
  });

  final Widget child;
  final String watermarkText;
  final bool showBadge;
  final bool showWatermark;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,

        // ── Premium Watermark — Bottom Right ─────────────
        if (showWatermark)
          Positioned(
            bottom: 14,
            right: 14,
            child: _PremiumWatermark(),
          ),
      ],
    );
  }
}

// ── PREMIUM WATERMARK WIDGET ────────────────────────────────
class _PremiumWatermark extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        // Frosted glass / dark translucent look
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.18),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon block
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: const Color(0xFF2563EB).withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(7),
            ),
            child: const Icon(
              FontAwesomeIcons.googlePlay,
              color: Colors.white,
              size: 13,
            ),
          ),
          const SizedBox(width: 8),

          // Text block
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Jersey Studio',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 0.2,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 1),
              const Text(
                'GET IT ON PLAYSTORE',
                style: TextStyle(
                  fontSize: 7.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF93C5FD),
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
