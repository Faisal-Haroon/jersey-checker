import 'package:flutter/material.dart';
import '../models/selected_file.dart';
import '../theme/app_theme.dart';

class HomeDashboardScreen extends StatelessWidget {
  const HomeDashboardScreen({
    super.key,
    required this.onOpen3DStudio,
    required this.onOpenConverter,
    required this.testerJersey,
    required this.convertedCount,
  });

  final VoidCallback onOpen3DStudio;
  final VoidCallback onOpenConverter;
  final SelectedJerseyFile? testerJersey;
  final int convertedCount;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 32),
      children: [
        // ── HERO BANNER ──────────────────────────────────
        _HeroBanner(
          testerJersey: testerJersey,
          convertedCount: convertedCount,
        ),
        const SizedBox(height: 28),

        // ── TOOL CARDS ───────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'TOOLS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textMuted,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _ToolCard(
                      title: '3D Studio',
                      subtitle: 'Load texture on\n3D model & preview',
                      icon: Icons.view_in_ar_rounded,
                      color: AppTheme.primaryBlue,
                      onTap: onOpen3DStudio,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _ToolCard(
                      title: 'Converter',
                      subtitle: 'PNG to File\nbatch convert',
                      icon: Icons.transform_rounded,
                      color: const Color(0xFF10B981),
                      onTap: onOpenConverter,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // ── QUICK STATS ROW ──────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Expanded(
                child: _MiniStatCard(
                  icon: Icons.layers_rounded,
                  label: 'Active Model',
                  value: testerJersey != null ? testerJersey!.name : 'None',
                  color: AppTheme.primaryBlue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MiniStatCard(
                  icon: Icons.check_circle_rounded,
                  label: 'Converted',
                  value: '$convertedCount files',
                  color: const Color(0xFF10B981),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // ── PRO TIP ──────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: AppTheme.primaryBlue.withValues(alpha: 0.15)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.tips_and_updates_rounded,
                      color: AppTheme.primaryBlue, size: 20),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'How it works',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.primaryBlue,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Open 3D Studio, load your PNG texture on the model, then use Converter to export it as a .bytes file.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textMuted,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── HERO BANNER ─────────────────────────────────────────────
class _HeroBanner extends StatelessWidget {
  const _HeroBanner({
    required this.testerJersey,
    required this.convertedCount,
  });

  final SelectedJerseyFile? testerJersey;
  final int convertedCount;

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;

    return Container(
      width: double.infinity,
      clipBehavior: Clip.hardEdge,
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(36),
          bottomRight: Radius.circular(36),
        ),
      ),
      child: Stack(
        children: [
          // ── Gradient background ──
          Container(
            height: 230,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                stops: [0.0, 0.5, 1.0],
                colors: [
                  Color(0xFF0A1628),
                  Color(0xFF0F2952),
                  Color(0xFF1648A8),
                ],
              ),
            ),
          ),

          // ── Decorative orbs ──
          Positioned(
            top: -50,
            right: -50,
            child: _Orb(size: 210, opacity: 0.05),
          ),
          Positioned(
            top: 55,
            right: 35,
            child: _Orb(size: 90, opacity: 0.07),
          ),
          Positioned(
            bottom: -40,
            left: screenW * 0.3,
            child: _Orb(size: 150, opacity: 0.08, color: const Color(0xFF60A5FA)),
          ),
          Positioned(
            bottom: 10,
            right: -20,
            child: _Orb(size: 80, opacity: 0.06, color: const Color(0xFF34D399)),
          ),

          // ── Stripe pattern ──
          Positioned.fill(
            child: CustomPaint(painter: _StripePainter()),
          ),

          // ── Content ──
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 26),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Top row ──
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // App icon
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.18),
                            width: 1),
                      ),
                      child: Image.asset(
                        'assets/TransparentLogo.png',
                        width: 48,
                        height: 48,
                        cacheWidth: 150,
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Text block
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Version badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 9, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  width: 1),
                            ),
                            child: const Text(
                              'TEXTURE STUDIO',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFFBFDBFE),
                                letterSpacing: 1.0,
                              ),
                            ),
                          ),
                          const SizedBox(height: 7),
                          const Text(
                            'Jersey Studio',
                            style: TextStyle(
                              fontSize: 27,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: -1.0,
                              height: 1.0,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Design  \u2022  Preview  \u2022  Convert',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: Color(0xFF93C5FD),
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 22),

                // ── Divider line ──
                Container(
                  height: 1,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
                const SizedBox(height: 18),

                // ── Quick action buttons ──
                Row(
                  children: [
                    Expanded(
                      child: _HeroButton(
                        icon: Icons.view_in_ar_rounded,
                        label: '3D Studio',
                        color: const Color(0xFF60A5FA),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _HeroButton(
                        icon: Icons.transform_rounded,
                        label: 'Converter',
                        color: const Color(0xFF34D399),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── ORB HELPER ──────────────────────────────────────────────
class _Orb extends StatelessWidget {
  const _Orb({
    required this.size,
    required this.opacity,
    this.color = Colors.white,
  });

  final double size;
  final double opacity;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: opacity),
      ),
    );
  }
}

// ── HERO BUTTON ─────────────────────────────────────────────
class _HeroButton extends StatelessWidget {
  const _HeroButton({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ── MINI STAT CARD ──────────────────────────────────────────
class _MiniStatCard extends StatelessWidget {
  const _MiniStatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppTheme.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textMain,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── STRIPE PAINTER ──────────────────────────────────────────
class _StripePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.025)
      ..strokeWidth = 32
      ..style = PaintingStyle.stroke;

    for (double x = -size.height; x < size.width + size.height; x += 55) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x + size.height, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_StripePainter oldDelegate) => false;
}

// ── TOOL CARD ───────────────────────────────────────────────
class _ToolCard extends StatelessWidget {
  const _ToolCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.cardColor,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppTheme.border),
          ),
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textMain,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.textMuted,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
