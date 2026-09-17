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
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: [
        // Premium Header
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppTheme.cardColor,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppTheme.border),
            boxShadow: [
              BoxShadow(
                color: AppTheme.textMuted.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'KIT STUDIO',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primaryBlue,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Welcome',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.textMain,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        
        // Simple Grid for Tools
        Row(
          children: [
            Expanded(
              child: _SimpleToolCard(
                title: '3D Studio',
                icon: Icons.view_in_ar_rounded,
                color: AppTheme.primaryBlue,
                onTap: onOpen3DStudio,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _SimpleToolCard(
                title: 'Converter',
                icon: Icons.swap_horiz_rounded,
                color: const Color(0xFF10B981),
                onTap: onOpenConverter,
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),

        // Session Overview
        const Text(
          'SESSION',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: AppTheme.textMuted,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.border),
          ),
          child: Column(
            children: [
              _StatusRow(
                icon: Icons.checkroom_rounded,
                label: 'Active Texture',
                value: testerJersey != null ? testerJersey!.name : 'None',
              ),
              const Divider(color: AppTheme.border, height: 24),
              _StatusRow(
                icon: Icons.folder_zip_rounded,
                label: 'Converted Files',
                value: '$convertedCount',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SimpleToolCard extends StatelessWidget {
  const _SimpleToolCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: AppTheme.cardColor,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textMain,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.textMuted),
        const SizedBox(width: 12),
        Text(
          label,
          style: const TextStyle(fontSize: 14, color: AppTheme.textMuted),
        ),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textMain,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
