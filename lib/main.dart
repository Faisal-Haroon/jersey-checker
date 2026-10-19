import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'models/selected_file.dart';
import 'screens/community_profile_screen.dart';
import 'screens/convert_mode_picker_screen.dart';
import 'screens/converter_screen.dart';
import 'screens/home_dashboard_screen.dart';
import 'screens/jersey_tester_screen.dart';
import 'screens/splash_screen.dart';
import 'services/ad_service.dart';
import 'services/integrity_service.dart';
import 'services/texture_service.dart';
import 'theme/app_theme.dart';
import 'widgets/app_drawer.dart';
import 'widgets/app_info_sheet.dart';
import 'widgets/banner_ad_widget.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  await IntegrityService.verifyPackageIntegrity();
  await AdService.instance.initialize(); // GAM ads init
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Jersey Studio',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const MainAppWrapper(),
    );
  }
}

class MainAppWrapper extends StatefulWidget {
  const MainAppWrapper({super.key});

  @override
  State<MainAppWrapper> createState() => _MainAppWrapperState();
}

class _MainAppWrapperState extends State<MainAppWrapper> {
  // Static flag: ek baar true hone ke baad activity recreate hone par bhi
  // splash dobara nahi dikhega (file picker return, orientation change, etc.)
  static bool _hasLaunched = false;

  @override
  void initState() {
    super.initState();
    if (!_hasLaunched) {
      AdService.instance.isAppOpenSuppressed = true;
    }
  }

  void _onSplashFinish() async {
    AdService.instance.isAppOpenSuppressed = false;
    await AdService.instance.showAppOpenAd(
      isColdStart: true,
      onAdShowed: () {
        // While user is watching the ad, render Main screen in the background
        if (mounted) setState(() => _hasLaunched = true);
      },
      onAdDismissed: () {
        if (mounted && !_hasLaunched) setState(() => _hasLaunched = true);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasLaunched) {
      return SplashScreen(onFinish: _onSplashFinish);
    }
    return const StudioHomePage();
  }
}

class StudioHomePage extends StatefulWidget {
  const StudioHomePage({super.key});

  @override
  State<StudioHomePage> createState() => _StudioHomePageState();
}

class _StudioHomePageState extends State<StudioHomePage> {
  int _tabIndex = 0;
  ConversionMode? _converterSelectedMode;
  SelectedJerseyFile? _testerJersey;
  final List<SelectedJerseyFile> _converterFiles = [];
  int _viewerKeyCounter = 0;

  Future<void> _pickTesterJersey() async {
    AdService.instance.isAppOpenSuppressed = true;
    try {
      final selected = await TextureService.pickSinglePng();
      if (!mounted || selected == null) return;
      setState(() {
        _testerJersey = selected;
        _viewerKeyCounter++;
      });
    } catch (e) {
      if (mounted) _showMessage(e.toString());
    } finally {
      AdService.instance.isAppOpenSuppressed = false;
    }
  }

  static const int _maxBatchFiles = 5;

  Future<void> _pickConverterFiles() async {
    AdService.instance.isAppOpenSuppressed = true;
    try {
      final selectedList = await TextureService.pickMultiplePngs();
      if (!mounted || selectedList.isEmpty) return;

      bool reachedLimit = false;
      setState(() {
        for (final item in selectedList) {
          if (_converterFiles.length >= _maxBatchFiles) {
            reachedLimit = true;
            break;
          }
          if (!_converterFiles.any((existing) => existing.name == item.name)) {
            _converterFiles.add(item);
          }
        }
      });

      if (reachedLimit || selectedList.length > _maxBatchFiles) {
        _showMessage('Maximum 5 files allowed per conversion batch.');
      }
    } catch (e) {
      if (mounted) _showMessage(e.toString());
    } finally {
      AdService.instance.isAppOpenSuppressed = false;
    }
  }

  Future<void> _pickBytesFiles() async {
    AdService.instance.isAppOpenSuppressed = true;
    try {
      final selectedList = await TextureService.pickMultipleBytesFiles();
      if (!mounted || selectedList.isEmpty) return;

      bool reachedLimit = false;
      setState(() {
        for (final item in selectedList) {
          if (_converterFiles.length >= _maxBatchFiles) {
            reachedLimit = true;
            break;
          }
          if (!_converterFiles.any((existing) => existing.name == item.name)) {
            _converterFiles.add(item);
          }
        }
      });

      if (reachedLimit || selectedList.length > _maxBatchFiles) {
        _showMessage('Maximum 5 files allowed per conversion batch.');
      }
    } catch (e) {
      if (mounted) _showMessage(e.toString());
    } finally {
      AdService.instance.isAppOpenSuppressed = false;
    }
  }

  void _showMessage(String message) {
    final cleanMsg = message.replaceAll(
      RegExp(r'^(Exception|PlatformException|FormatException):\s*'),
      '',
    );
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(cleanMsg),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
  }

  void _openAppInfoSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => const AppInfoSheet(),
    );
  }

  Future<bool> _showExitDialog() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 340),
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
          decoration: BoxDecoration(
            color: AppTheme.cardColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppTheme.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Exit Jersey Studio?',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textMain,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Are you sure you want to close the app?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.textMuted,
                  height: 1.3,
                ),
              ),
              const AppMrecWidget(topPadding: 12, bottomPadding: 0),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(
                          color: AppTheme.border,
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Stay',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.primaryBlue,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Exit',
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
      ),
    );
    return result ?? false;
  }

  void _navigateToTab(int index) {
    setState(() {
      if (index == 2) {
        _converterSelectedMode = null;
      }
      _tabIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final titles = ['Jersey Studio', '3D Studio', 'Converter', 'Community'];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (_tabIndex == 2 && _converterSelectedMode != null) {
          setState(() => _converterSelectedMode = null);
          return;
        }
        if (_tabIndex != 0) {
          setState(() => _tabIndex = 0);
          return;
        }
        final shouldExit = await _showExitDialog();
        if (shouldExit && context.mounted) {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        drawer: AppDrawer(
          selectedIndex: _tabIndex,
          onSelectTab: _navigateToTab,
        ),
        appBar: _tabIndex == 1
            ? null
            : AppBar(
                backgroundColor: Colors.transparent,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0F2952), Color(0xFF1648A8)],
              ),
            ),
          ),
          elevation: 0,
          centerTitle: false,
          leading: (_tabIndex == 2 && _converterSelectedMode != null)
              ? IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  tooltip: 'Back to Mode Selection',
                  onPressed: () => setState(() => _converterSelectedMode = null),
                )
              : null,
          title: Text(
            _tabIndex == 2 && _converterSelectedMode != null
                ? (_converterSelectedMode == ConversionMode.pngToBytes
                    ? 'PNG → File Converter'
                    : 'File → PNG Converter')
                : titles[_tabIndex],
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 18,
              letterSpacing: -0.3,
              color: Colors.white,
            ),
          ),
          iconTheme: const IconThemeData(color: Colors.white),
          actions: [
            IconButton(
              icon: const Icon(Icons.help_outline, color: Colors.white),
              tooltip: 'App Info',
              onPressed: _openAppInfoSheet,
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: SafeArea(
          top: _tabIndex != 1,
          bottom: false,
          child: IndexedStack(
            index: _tabIndex,
            children: [
              HomeDashboardScreen(
                onOpen3DStudio: () => _navigateToTab(1),
                onOpenConverter: () => _navigateToTab(2),
              ),
              JerseyTesterScreen(
                selectedJersey: _testerJersey,
                onPickJersey: _pickTesterJersey,
                viewerKey: ValueKey(_viewerKeyCounter),
                onResetView: () => setState(() => _viewerKeyCounter++),
              ),
              _converterSelectedMode == null
                  ? ConvertModePickerScreen(
                      onSelectMode: (mode) {
                        setState(() {
                          _converterSelectedMode = mode;
                          _converterFiles.clear();
                        });
                      },
                    )
                  : ConverterScreen(
                      initialMode: _converterSelectedMode!,
                      files: _converterFiles,
                      onPickFiles: _pickConverterFiles,
                      onPickBytesFiles: _pickBytesFiles,
                      onClearAll: () => setState(_converterFiles.clear),
                      onRemoveFile: (file) =>
                          setState(() => _converterFiles.remove(file)),
                      onBack: () => setState(() => _converterSelectedMode = null),
                    ),
              const CommunityProfileScreen(),
            ],
          ),
        ),
        bottomNavigationBar: Container(
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: AppTheme.border, width: 0.8)),
          ),
          child: NavigationBar(
            selectedIndex: _tabIndex,
            onDestinationSelected: _navigateToTab,
            backgroundColor: AppTheme.cardColor,
            elevation: 0,
            indicatorColor: AppTheme.primaryBlue.withValues(alpha: 0.15),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home, color: AppTheme.primaryBlue),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.view_in_ar_outlined),
                selectedIcon: Icon(
                  Icons.view_in_ar,
                  color: AppTheme.primaryBlue,
                ),
                label: '3D Studio',
              ),
              NavigationDestination(
                icon: Icon(Icons.swap_horiz_outlined),
                selectedIcon: Icon(
                  Icons.swap_horiz,
                  color: AppTheme.primaryBlue,
                ),
                label: 'Converter',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline_rounded),
                selectedIcon: Icon(
                  Icons.person_rounded,
                  color: AppTheme.primaryBlue,
                ),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
