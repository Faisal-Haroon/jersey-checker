import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ShowcaseOverlay extends StatelessWidget {
  const ShowcaseOverlay({
    super.key,
    required this.child,
    this.watermarkText = '',
    this.showBadge = false,
  });

  final Widget child;
  final String watermarkText;
  final bool showBadge;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (showBadge)
          Positioned(
            top: 12,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppTheme.primaryBlue.withValues(alpha: 0.3),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.sports_cricket,
                    size: 14,
                    color: AppTheme.primaryBlue,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'KIT PREVIEW',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                      color: AppTheme.textMain,
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (watermarkText.isNotEmpty)
          Positioned(
            bottom: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppTheme.border),
              ),
              child: Text(
                watermarkText,
                style: const TextStyle(
                  fontSize: 10,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textMuted,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
