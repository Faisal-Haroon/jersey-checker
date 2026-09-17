import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../theme/app_theme.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({
    super.key,
    required this.selectedIndex,
    required this.onSelectTab,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelectTab;

  void _showPrivacyPolicyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppTheme.border),
        ),
        title: const Row(
          children: [
            Icon(Icons.privacy_tip_outlined, color: AppTheme.primaryBlue),
            SizedBox(width: 10),
            Text('Privacy Policy', style: TextStyle(color: AppTheme.textMain, fontSize: 18)),
          ],
        ),
        content: const SingleChildScrollView(
          child: Text(
            'Jersey Studio respects your privacy.\n\n'
            '• All 3D model processing and texture rendering happens locally on your device.\n'
            '• We do not collect or upload any personal files or textures to external servers.\n'
            '• Storage permissions are used solely for loading GLB models and saving custom texture showcase screenshots.',
            style: TextStyle(fontSize: 13, color: AppTheme.textMuted, height: 1.4),
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _shareApp(BuildContext context) {
    // ignore: deprecated_member_use
    Share.share(
      'Check out Jersey Studio! Preview custom 3D models & convert PNG jersey textures for mobile games.',
      subject: 'Jersey Studio App',
    );
  }

  void _rateApp(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Thank you for rating Jersey Studio! ⭐⭐⭐⭐⭐'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final drawerWidth = MediaQuery.of(context).size.width * 0.72;

    return SizedBox(
      width: drawerWidth,
      child: Drawer(
        backgroundColor: AppTheme.cardColor,
        child: SafeArea(
          child: Column(
            children: [
              // Drawer Header
              Container(
                padding: const EdgeInsets.all(20),
                width: double.infinity,
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: AppTheme.border)),
                  color: AppTheme.cardColor,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.background,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: const Icon(
                        Icons.checkroom_outlined,
                        color: AppTheme.primaryBlue,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Jersey Studio',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textMain,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      '3D Kit Previewer & Converter',
                      style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              
              // Navigation Links
              _DrawerTile(
                icon: Icons.home_outlined,
                selectedIcon: Icons.home,
                title: 'Home',
                isSelected: selectedIndex == 0,
                onTap: () {
                  Navigator.pop(context);
                  onSelectTab(0);
                },
              ),
              _DrawerTile(
                icon: Icons.view_in_ar_outlined,
                selectedIcon: Icons.view_in_ar,
                title: '3D Studio Tester',
                isSelected: selectedIndex == 1,
                onTap: () {
                  Navigator.pop(context);
                  onSelectTab(1);
                },
              ),
              _DrawerTile(
                icon: Icons.swap_horiz_outlined,
                selectedIcon: Icons.swap_horiz,
                title: 'PNG Converter',
                isSelected: selectedIndex == 2,
                onTap: () {
                  Navigator.pop(context);
                  onSelectTab(2);
                },
              ),
              _DrawerTile(
                icon: Icons.person_outline_rounded,
                selectedIcon: Icons.person_rounded,
                title: 'Community Hub',
                isSelected: selectedIndex == 3,
                onTap: () {
                  Navigator.pop(context);
                  onSelectTab(3);
                },
              ),
              
              const Divider(color: AppTheme.border, indent: 16, endIndent: 16),
              
              // Extra Options
              _DrawerTile(
                icon: Icons.privacy_tip_outlined,
                selectedIcon: Icons.privacy_tip,
                title: 'Privacy Policy',
                isSelected: false,
                onTap: () {
                  Navigator.pop(context);
                  _showPrivacyPolicyDialog(context);
                },
              ),
              _DrawerTile(
                icon: Icons.share_outlined,
                selectedIcon: Icons.share,
                title: 'Share with Friends',
                isSelected: false,
                onTap: () {
                  Navigator.pop(context);
                  _shareApp(context);
                },
              ),
              _DrawerTile(
                icon: Icons.star_rate_outlined,
                selectedIcon: Icons.star_rate,
                title: 'Rate Us',
                isSelected: false,
                onTap: () {
                  Navigator.pop(context);
                  _rateApp(context);
                },
              ),

              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

class _DrawerTile extends StatelessWidget {
  const _DrawerTile({
    required this.icon,
    required this.selectedIcon,
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      child: ListTile(
        dense: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        tileColor: isSelected ? AppTheme.primaryBlue.withValues(alpha: 0.12) : Colors.transparent,
        leading: Icon(
          isSelected ? selectedIcon : icon,
          color: isSelected ? AppTheme.primaryBlue : AppTheme.textMuted,
          size: 20,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? AppTheme.primaryBlue : AppTheme.textMain,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 13,
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}
