import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/ad_service.dart';

/// A robust, reusable banner ad widget that:
/// - Reserves layout space (50dp) to prevent layout jumps.
/// - Loads the ad once in [initState] and does NOT recreate on widget rebuilds.
/// - Uses a strictly capped single 45s retry on initial failure (prevents request flooding).
/// - Properly disposes of the [BannerAd] and timers when removed from the widget tree.
/// - Respects safe areas and failure states gracefully.
class AppBannerWidget extends StatefulWidget {
  const AppBannerWidget({
    super.key,
    this.topPadding = 16.0,
    this.bottomPadding = 8.0,
  });

  final double topPadding;
  final double bottomPadding;

  @override
  State<AppBannerWidget> createState() => _AppBannerWidgetState();
}

class _AppBannerWidgetState extends State<AppBannerWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;
  bool _isFailed = false;
  bool _hasRetried = false;
  Timer? _retryTimer;

  @override
  void initState() {
    super.initState();
    _initBanner();
  }

  void _initBanner() {
    if (!Platform.isAndroid && !Platform.isIOS) {
      _isFailed = true;
      return;
    }

    _bannerAd = BannerAd(
      adUnitId: AdService.bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          _retryTimer?.cancel();
          _retryTimer = null;
          if (mounted) {
            setState(() {
              _isLoaded = true;
              _isFailed = false;
            });
          }
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('[AppBannerWidget] Banner failed to load: $error');
          ad.dispose();
          _bannerAd = null;
          if (mounted) {
            setState(() {
              _isLoaded = false;
              _isFailed = true;
            });

            // Guaranteed single retry latch: strictly 1 retry after 45s cooldown
            // Total maximum requests per session = 2 (Zero risk of request loops)
            if (!_hasRetried) {
              _hasRetried = true;
              _retryTimer?.cancel();
              _retryTimer = Timer(const Duration(seconds: 45), () {
                if (mounted && !_isLoaded) {
                  debugPrint('[AppBannerWidget] Executing single safe retry (45s cooldown)...');
                  _initBanner();
                }
              });
            }
          }
        },
      ),
    );

    _bannerAd!.load();
  }

  @override
  void dispose() {
    _retryTimer?.cancel();
    _retryTimer = null;
    _bannerAd?.dispose();
    _bannerAd = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isFailed || (!Platform.isAndroid && !Platform.isIOS)) {
      return const SizedBox.shrink();
    }

    final bannerHeight = AdSize.banner.height.toDouble();
    final bannerWidth = AdSize.banner.width.toDouble();

    return Padding(
      padding: EdgeInsets.only(
        top: widget.topPadding,
        bottom: widget.bottomPadding,
      ),
      child: Center(
        child: SizedBox(
          width: bannerWidth,
          height: bannerHeight,
          child: _isLoaded && _bannerAd != null
              ? AdWidget(ad: _bannerAd!)
              : const SizedBox.shrink(),
        ),
      ),
    );
  }
}

/// A 300×250 Medium Rectangle (MREC) ad widget.
/// GAM auto-serves MREC creative when [AdSize.mediumRectangle] is requested.
class AppMrecWidget extends StatefulWidget {
  const AppMrecWidget({
    super.key,
    this.topPadding = 12.0,
    this.bottomPadding = 4.0,
  });

  final double topPadding;
  final double bottomPadding;

  @override
  State<AppMrecWidget> createState() => _AppMrecWidgetState();
}

class _AppMrecWidgetState extends State<AppMrecWidget> {
  BannerAd? _ad;
  bool _isLoaded = false;
  bool _isFailed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    if (!Platform.isAndroid && !Platform.isIOS) {
      _isFailed = true;
      return;
    }
    _ad = BannerAd(
      adUnitId: AdService.bannerAdUnitId,
      size: AdSize.mediumRectangle,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (mounted) setState(() => _isLoaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('[AppMrecWidget] MREC failed: $error');
          ad.dispose();
          _ad = null;
          if (mounted) setState(() => _isFailed = true);
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _ad?.dispose();
    _ad = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isFailed || (!Platform.isAndroid && !Platform.isIOS)) {
      return const SizedBox.shrink();
    }
    if (!_isLoaded || _ad == null) return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.only(
        top: widget.topPadding,
        bottom: widget.bottomPadding,
      ),
      child: Center(
        child: Container(
          width: 300,
          height: 250,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
          ),
          clipBehavior: Clip.antiAlias,
          child: AdWidget(ad: _ad!),
        ),
      ),
    );
  }
}
