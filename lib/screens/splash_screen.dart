import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.onFinish});

  final VoidCallback onFinish;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  double _progress = 0.0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _controller.forward();
    _startLoading();
  }

  void _startLoading() {
    _timer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
      setState(() {
        _progress += 0.025;
        if (_progress >= 1.0) {
          _progress = 1.0;
          _timer?.cancel();
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted) {
              widget.onFinish();
            }
          });
        }
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          Center(
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppTheme.primaryBlue.withValues(alpha: 0.15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.cardColor,
                        border: Border.all(
                          color: AppTheme.primaryBlue.withValues(alpha: 0.3),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryBlue.withValues(alpha: 0.15),
                            blurRadius: 30,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.checkroom_outlined,
                        size: 64,
                        color: AppTheme.primaryBlue,
                      ),
                    ),
                    const SizedBox(height: 28),
                    const Text(
                      'JERSEY STUDIO',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 3,
                        color: AppTheme.textMain,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '3D Kit Previewer & Converter Toolkit',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textMuted,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 48),
                    SizedBox(
                      width: 220,
                      child: Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: _progress,
                              minHeight: 6,
                              backgroundColor: AppTheme.border,
                              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Loading Engine... ${(_progress * 100).toInt()}%',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppTheme.textSubtle,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Positioned(
            bottom: 24,
            left: 0,
            right: 0,
            child: Text(
              'KIT STUDIO ENGINE',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                color: AppTheme.textSubtle,
                letterSpacing: 2,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
