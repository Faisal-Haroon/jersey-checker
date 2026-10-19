import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';

class CommunityProfileScreen extends StatelessWidget {
  const CommunityProfileScreen({super.key});

  Future<void> _openUrl(BuildContext context, String urlString) async {
    final uri = Uri.parse(urlString);
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not open link: $urlString')),
          );
        }
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      children: [
        // Profile Header Card
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppTheme.cardColor,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppTheme.border),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/TransparentLogo.png',
                    width: 76,
                    height: 76,
                    cacheWidth: 200,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Jersey Studio Hub',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.textMain,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                '3D Kit Creators Community',
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Creators Collaboration Section Title
        const Text(
          'CREATORS & COLLABORATIONS',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: AppTheme.textMuted,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 12),

        // Baltistani Gamer Card
        _SocialCard(
          title: 'Baltistani Gamer',
          subtitle: 'Official Youtube Channel • Lead App Developer',
          icon: FontAwesomeIcons.youtube,
          iconColor: const Color(0xFFFF0000),
          onTap: () =>
              _openUrl(context, 'https://youtube.com/@baltistanigamer'),
        ),
        const SizedBox(height: 10),

        // Bobzie X Card
        _SocialCard(
          title: 'Bobzie X',
          subtitle: 'Official Youtube Channel • Co-Creator & Concept',
          icon: FontAwesomeIcons.youtube,
          iconColor: const Color(0xFFFF0000),
          onTap: () => _openUrl(context, 'https://youtube.com/@bobziex'),
        ),
        const SizedBox(height: 24),

        // Community Section Title
        const Text(
          'COMMUNITY & CHANNELS',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: AppTheme.textMuted,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 12),

        // WhatsApp Channel Card
        _SocialCard(
          title: 'WhatsApp Channel',
          subtitle: 'Get latest 3D Models, Jerseys & Kit updates',
          icon: FontAwesomeIcons.whatsapp,
          iconColor: const Color(0xFF25D366),
          onTap: () => _openUrl(
            context,
            'https://whatsapp.com/channel/0029VbD0oGa6GcGJfGkcuw1Y',
          ),
        ),
        const SizedBox(height: 10),

        // Instagram Profile Card
        _SocialCard(
          title: 'Instagram',
          subtitle: 'Follow @Bobzie_X for the latest updates & designs',
          icon: FontAwesomeIcons.instagram,
          iconColor: const Color(0xFFE1306C),
          onTap: () => _openUrl(context, 'https://instagram.com/Bobzie_X'),
        ),
      ],
    );
  }
}

class _SocialCard extends StatelessWidget {
  const _SocialCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: AppTheme.cardColor,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: iconColor, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textMain,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: AppTheme.textSubtle,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
