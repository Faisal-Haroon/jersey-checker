import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/banner_ad_widget.dart';

class HomeDashboardScreen extends StatelessWidget {
  const HomeDashboardScreen({
    super.key,
    required this.onOpen3DStudio,
    required this.onOpenConverter,
  });

  final VoidCallback onOpen3DStudio;
  final VoidCallback onOpenConverter;

  void _launchUrl(String url) {
    launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── SCROLLABLE CARDS BODY ─────────────────────────────
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
            children: [
              // ── TOP WELCOME BANNER CONTAINER ────────────────
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF0D254C),
                      Color(0xFF17479E),
                      Color(0xFF2563EB),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF17479E).withValues(alpha: 0.32),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: Stack(
                    children: [
                      // Subtle decorative ambient glow circles
                      Positioned(
                        top: -30,
                        right: -20,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: -40,
                        left: 40,
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF60A5FA)
                                .withValues(alpha: 0.12),
                          ),
                        ),
                      ),

                      // Card Content
                      Padding(
                        padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3.5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.16),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.white
                                            .withValues(alpha: 0.28),
                                      ),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.auto_awesome,
                                          color: Color(0xFFFDE047),
                                          size: 11,
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          'KIT STUDIO',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w900,
                                            color: Colors.white,
                                            letterSpacing: 0.8,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 7),
                                  const Text(
                                    'Welcome to Studio',
                                    style: TextStyle(
                                      fontSize: 18.5,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    'Preview jerseys in 3D & convert game files',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      color: Colors.white.withValues(alpha: 0.88),
                                      height: 1.25,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 14),
                            Container(
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.16),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.32),
                                  width: 1.2,
                                ),
                              ),
                              child: Image.asset(
                                'assets/TransparentLogo.png',
                                width: 48,
                                height: 48,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ── CREATIVE TOOLS SECTION HEADER ───────────────
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 16,
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'CREATIVE TOOLS',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F172A),
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // ── ROW 1: 3D STUDIO & CONVERTER ────────────────
              Row(
                children: [
                  // 1. 3D STUDIO CARD
                  Expanded(
                    child: _VisualGridCard(
                      borderColor: const Color(0xFFC7D2FE),
                      glowColor: const Color(0xFF818CF8),
                      topLeftWidget: const _IconBox(
                        icon: Icons.crop_free_rounded,
                        color: Color(0xFF334155),
                      ),
                      centerWidget: Image.asset(
                        'assets/3d_Studio.webp',
                        height: 110,
                        fit: BoxFit.contain,
                      ),
                      title: '3D STUDIO',
                      buttonText: 'Launch →',
                      buttonGradient: const LinearGradient(
                        colors: [Color(0xFF93C5FD), Color(0xFF6366F1)],
                      ),
                      buttonTextColor: Colors.white,
                      onTap: onOpen3DStudio,
                    ),
                  ),
                  const SizedBox(width: 14),

                  // 2. CONVERTER CARD
                  Expanded(
                    child: _VisualGridCard(
                      borderColor: const Color(0xFFA7F3D0),
                      glowColor: const Color(0xFF10B981),
                      topLeftWidget: const _IconBox(
                        icon: Icons.swap_horiz_rounded,
                        color: Color(0xFF334155),
                      ),
                      centerWidget: Image.asset(
                        'assets/converter.webp',
                        height: 110,
                        fit: BoxFit.contain,
                      ),
                      title: 'CONVERTER',
                      buttonText: 'Convert →',
                      buttonGradient: const LinearGradient(
                        colors: [Color(0xFF6EE7B7), Color(0xFF10B981)],
                      ),
                      buttonTextColor: const Color(0xFF064E3B),
                      onTap: onOpenConverter,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 22),

              // ── COMMUNITY & SUPPORT SECTION HEADER ──────────
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 16,
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'COMMUNITY & SUPPORT',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F172A),
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // ── ROW 2: CRICKET STORE & RATE US ──────────────
              Row(
                children: [
                  // 3. CRICKET STORE CARD
                  Expanded(
                    child: _VisualGridCard(
                      borderColor: const Color(0xFFC7D2FE),
                      glowColor: const Color(0xFF818CF8),
                      verticalSpacing: 8,
                      buttonVerticalSpacing: 10,
                      buttonHeight: 34,
                      cardPadding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                      centerWidget: Image.asset(
                        'assets/Jersey_app.webp',
                        height: 95,
                        fit: BoxFit.contain,
                      ),
                      title: 'GC5 JERSEYS',
                      buttonText: 'Download →',
                      buttonGradient: const LinearGradient(
                        colors: [Color(0xFFC4B5FD), Color(0xFFA78BFA)],
                      ),
                      buttonTextColor: const Color(0xFF3730A3),
                      onTap: () => _launchUrl(
                        'https://play.google.com/store/apps/details?id=com.uswatechnologies.cricketplpstore&hl=en',
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),

                  // 4. RATE US CARD
                  Expanded(
                    child: _VisualGridCard(
                      borderColor: const Color(0xFFFED7AA),
                      glowColor: const Color(0xFFF59E0B),
                      verticalSpacing: 8,
                      buttonVerticalSpacing: 10,
                      buttonHeight: 34,
                      cardPadding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                      centerWidget: SizedBox(
                        height: 95,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Curved Stars on top
                            Positioned(
                              top: 6,
                              child: Image.asset(
                                'assets/rate.webp',
                                width: 115,
                                fit: BoxFit.contain,
                              ),
                            ),
                            // Thumbs-up icon nestled underneath the arched stars
                            Positioned(
                              bottom: 4,
                              child: Container(
                                padding: const EdgeInsets.all(7),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEF3C7),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(0xFFFDE68A),
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFF59E0B)
                                          .withValues(alpha: 0.22),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.thumb_up_rounded,
                                  size: 22,
                                  color: Color(0xFFD97706),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      title: 'RATE US',
                      buttonText: 'Rate Us →',
                      buttonGradient: const LinearGradient(
                        colors: [Color(0xFFFDE68A), Color(0xFFF59E0B)],
                      ),
                      buttonTextColor: const Color(0xFF78350F),
                      onTap: () => _launchUrl(
                        'https://play.google.com/store/apps/details?id=com.bobziex.jerseychecker&hl=en',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // ── STICKY BOTTOM BANNER AD ───────────────────────────
        const AppBannerWidget(topPadding: 4, bottomPadding: 4),
      ],
    );
  }
}

// ── VISUAL GRID CARD WIDGET ─────────────────────────────────
class _VisualGridCard extends StatelessWidget {
  const _VisualGridCard({
    required this.borderColor,
    required this.glowColor,
    required this.centerWidget,
    required this.title,
    required this.buttonText,
    required this.buttonGradient,
    required this.buttonTextColor,
    required this.onTap,
    this.topLeftWidget,
    this.verticalSpacing = 12,
    this.buttonVerticalSpacing = 14,
    this.buttonHeight = 38,
    this.cardPadding = const EdgeInsets.fromLTRB(12, 12, 12, 14),
  });

  final Color borderColor;
  final Color glowColor;
  final Widget centerWidget;
  final String title;
  final String buttonText;
  final LinearGradient buttonGradient;
  final Color buttonTextColor;
  final VoidCallback onTap;
  final Widget? topLeftWidget;
  final double verticalSpacing;
  final double buttonVerticalSpacing;
  final double buttonHeight;
  final EdgeInsetsGeometry cardPadding;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: borderColor,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: glowColor.withValues(alpha: 0.10),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: cardPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Visual Graphic with corner widgets overlaid directly on top
                Stack(
                  children: [
                    Center(child: centerWidget),
                    if (topLeftWidget != null)
                      Positioned(
                        top: 0,
                        left: 0,
                        child: topLeftWidget!,
                      ),
                  ],
                ),
                SizedBox(height: verticalSpacing),

                // Title (Bold uppercase)
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                    letterSpacing: 0.3,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: buttonVerticalSpacing),

                // Gradient Action Button
                Container(
                  width: double.infinity,
                  height: buttonHeight,
                  decoration: BoxDecoration(
                    gradient: buttonGradient,
                    borderRadius: BorderRadius.circular(buttonHeight / 2),
                    boxShadow: [
                      BoxShadow(
                        color: glowColor.withValues(alpha: 0.30),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    buttonText,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: buttonTextColor,
                      letterSpacing: 0.2,
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
}

// ── ICON BOX HELPER ─────────────────────────────────────────
class _IconBox extends StatelessWidget {
  const _IconBox({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, size: 16, color: color),
    );
  }
}
