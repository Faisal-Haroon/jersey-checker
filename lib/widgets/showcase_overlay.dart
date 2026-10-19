import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class ShowcaseOverlay extends StatelessWidget {
  const ShowcaseOverlay({
    super.key,
    required this.child,
    this.watermarkText = '',
    this.showBadge = false,
    this.showWatermark = false,
    this.watermarkTop,
  });

  final Widget child;
  final String watermarkText;
  final bool showBadge;
  final bool showWatermark;
  final double? watermarkTop;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,

        // ── Premium Watermark — Bottom Right ─────────────
        if (showWatermark)
          Positioned(
            top: watermarkTop,
            bottom: watermarkTop == null ? 14 : null,
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.18),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            FontAwesomeIcons.googlePlay,
            color: Color(0xFF60A5FA),
            size: 9.5,
          ),
          SizedBox(width: 5),
          Text(
            'Jersey Checker',
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}
