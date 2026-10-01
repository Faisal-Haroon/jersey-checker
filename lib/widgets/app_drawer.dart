import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({
    super.key,
    required this.selectedIndex,
    required this.onSelectTab,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelectTab;

  void _openPrivacyPolicy(BuildContext context) async {
    final url = Uri.parse('https://baltistanigamer1.blogspot.com/p/jersey-checker-studio-privacy-policy.html');
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open Privacy Policy.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _shareApp(BuildContext context) {
    // ignore: deprecated_member_use
    Share.share(
      'Check out Jersey Checker Studio! Preview 3D models & extract textures easily.\n\nGet it on Play Store:\nhttps://play.google.com/store/apps/details?id=com.bobziex.jerseychecker',
      subject: 'Jersey Checker Studio App',
    );
  }

  void _rateApp(BuildContext context) async {
    final url = Uri.parse('https://play.google.com/store/apps/details?id=com.bobziex.jerseychecker');
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open Play Store. Please search for us manually!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final drawerWidth = MediaQuery.of(context).size.width * 0.72;

    return SizedBox(
      width: drawerWidth,
      child: Drawer(
        backgroundColor: AppTheme.cardColor,
        child: Column(
          children: [
            // Drawer Header
            Container(
              padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 24, 20, 26),
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF0F2952),
                    Color(0xFF1648A8),
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                    ),
                    child: Image.asset(
                      'assets/TransparentLogo.png',
                      width: 44,
                      height: 44,
                      cacheWidth: 150,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Jersey Studio',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '3D Model Viewer & Converter',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.75),
                      fontWeight: FontWeight.w500,
                    ),
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
                title: '3D Studio',
                isSelected: selectedIndex == 1,
                onTap: () {
                  Navigator.pop(context);
                  onSelectTab(1);
                },
              ),
              _DrawerTile(
                icon: Icons.swap_horiz_outlined,
                selectedIcon: Icons.swap_horiz,
                title: 'Converter',
                isSelected: selectedIndex == 2,
                onTap: () {
                  Navigator.pop(context);
                  onSelectTab(2);
                },
              ),
              _DrawerTile(
                icon: Icons.person_outline_rounded,
                selectedIcon: Icons.person_rounded,
                title: 'Community',
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
                  _openPrivacyPolicy(context);
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
