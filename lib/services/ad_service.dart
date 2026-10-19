import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Centralized Google Ad Manager (GAM) Service.
///
/// Manages ad lifecycles, mutual exclusion across full-screen ads, frequency caps,
/// cooldowns, and safe app-lifecycle transitions.
class AdService with WidgetsBindingObserver {
  AdService._();
  static final AdService instance = AdService._();

  // ─── GAM Ad Unit IDs ──────────────────────────────────────────────────────
  // DEBUG = Google's official test IDs | RELEASE = Production GAM IDs

  static String get bannerAdUnitId => kDebugMode
      ? 'ca-app-pub-3940256099942544/6300978111'
      : '/22893901953/ca-mb-app-pub-2509511211458165-tag/uswa_com.bobziex.jerseychecker_banner';

  static String get appOpenAdUnitId => kDebugMode
      ? 'ca-app-pub-3940256099942544/9257395921'
      : '/22893901953/ca-mb-app-pub-2509511211458165-tag/uswa_com.bobziex.jerseychecker_Openapp';

  static String get interstitialAdUnitId => kDebugMode
      ? 'ca-app-pub-3940256099942544/1033173712'
      : '/22893901953/ca-mb-app-pub-2509511211458165-tag/uswa_com.bobziex.jerseychecker_interstitial';

  static String get rewardedAdUnitId => kDebugMode
      ? 'ca-app-pub-3940256099942544/5224354917'
      : '/22893901953/ca-mb-app-pub-2509511211458165-tag/uswa_com.bobziex.jerseychecker_Rewarded';

  // ─── Full-Screen Concurrency Guard ───────────────────────────────────────
  bool _isShowingFullScreenAd = false;
  bool get isShowingFullScreenAd => _isShowingFullScreenAd;

  DateTime? _lastFullScreenAdDismissedAt;

  // ─── App Open Ad State ───────────────────────────────────────────────────
  AppOpenAd? _appOpenAd;
  bool _appOpenReady = false;
  bool _appOpenLoading = false;
  DateTime? _lastAppOpenShownAt;
  DateTime? _appPausedAt;
  final List<VoidCallback> _appOpenLoadListeners = [];

  /// Cooldown between App-Open impressions on resume (standard 90 seconds).
  static const Duration appOpenCooldown = Duration(seconds: 90);

  /// Minimum time app must stay in background before qualifying for App-Open ad on resume (standard 90 seconds).
  static const Duration minBackgroundDurationForAppOpen = Duration(seconds: 90);

  /// Flag to suppress App-Open ad during sensitive/critical flows (file pickers, modals).
  bool isAppOpenSuppressed = false;

  // ─── Interstitial Ad State ───────────────────────────────────────────────
  InterstitialAd? _interstitialAd;
  bool _interstitialReady = false;
  bool _interstitialLoading = false;
  int _interstitialActionCount = 0;
  DateTime? _lastInterstitialShownAt;

  /// Cooldown between Interstitial impressions (default: 90 seconds).
  static const Duration interstitialCooldown = Duration(seconds: 90);

  /// Action interval: show at most 1 interstitial per 3 meaningful actions.
  static const int interstitialActionInterval = 3;

  // ─── Rewarded Ad State ───────────────────────────────────────────────────
  RewardedAd? _rewardedAd;
  bool _rewardedReady = false;
  bool _rewardedLoading = false;

  // ─── Initialization ──────────────────────────────────────────────────────
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  Future<void> initialize() async {
    if (_isInitialized) return;
    if (!Platform.isAndroid && !Platform.isIOS) return;

    try {
      await MobileAds.instance.initialize();
      _isInitialized = true;
      WidgetsBinding.instance.addObserver(this);

      // Controlled preloading
      loadAppOpenAd();
      loadInterstitialAd();
      loadRewardedAd();
    } catch (e) {
      debugPrint('[AdService] MobileAds initialization failed: $e');
    }
  }

  // ─── APP OPEN AD ─────────────────────────────────────────────────────────

  bool get isAppOpenReady =>
      _appOpenReady && _appOpenAd != null && !_isShowingFullScreenAd;

  bool get isAppOpenCooldownActive {
    if (_lastAppOpenShownAt == null) return false;
    return DateTime.now().difference(_lastAppOpenShownAt!) < appOpenCooldown;
  }

  void _notifyAppOpenListeners() {
    for (final listener in List.of(_appOpenLoadListeners)) {
      try {
        listener();
      } catch (_) {}
    }
    _appOpenLoadListeners.clear();
  }

  void loadAppOpenAd() {
    if (_appOpenReady || _appOpenLoading) return;
    if (!Platform.isAndroid && !Platform.isIOS) return;

    _appOpenLoading = true;
    debugPrint(
      '[AdService] Loading App Open Ad with unit ID: $appOpenAdUnitId',
    );

    AppOpenAd.load(
      adUnitId: appOpenAdUnitId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          _appOpenAd = ad;
          _appOpenReady = true;
          _appOpenLoading = false;
          _notifyAppOpenListeners();
          debugPrint('[AdService] App Open Ad loaded successfully.');
        },
        onAdFailedToLoad: (error) {
          _appOpenAd = null;
          _appOpenReady = false;
          _appOpenLoading = false;
          _notifyAppOpenListeners();
          debugPrint(
            '[AdService] App Open Ad failed to load: code=${error.code}, message=${error.message}, domain=${error.domain}',
          );
        },
      ),
    );
  }

  /// Show App Open Ad with cooldown check and full-screen concurrency guard.
  /// On cold start, cooldown is bypassed so the user reliably gets the launch ad.
  /// If the ad is loading, it awaits up to [waitTimeout] before proceeding.
  Future<void> showAppOpenAd({
    VoidCallback? onAdShowed,
    VoidCallback? onAdDismissed,
    bool isColdStart = false,
    Duration waitTimeout = const Duration(milliseconds: 3500),
  }) async {
    debugPrint(
      '[AdService] showAppOpenAd triggered (isColdStart: $isColdStart, isShowing: $_isShowingFullScreenAd, suppressed: $isAppOpenSuppressed, ready: $_appOpenReady, loading: $_appOpenLoading)',
    );

    if (_isShowingFullScreenAd || isAppOpenSuppressed) {
      debugPrint(
        '[AdService] App Open skipped: fullScreen=$isShowingFullScreenAd, suppressed=$isAppOpenSuppressed',
      );
      onAdDismissed?.call();
      return;
    }

    // Cooldown only applies to background resume, NEVER to cold start!
    if (!isColdStart && isAppOpenCooldownActive) {
      debugPrint(
        '[AdService] App Open skipped: cooldown active (${DateTime.now().difference(_lastAppOpenShownAt!).inSeconds}s since last).',
      );
      onAdDismissed?.call();
      return;
    }

    // Check buffer from any recently dismissed full-screen ad
    if (!isColdStart &&
        _lastFullScreenAdDismissedAt != null &&
        DateTime.now().difference(_lastFullScreenAdDismissedAt!) <
            const Duration(seconds: 10)) {
      debugPrint(
        '[AdService] App Open skipped: recently dismissed full screen ad.',
      );
      onAdDismissed?.call();
      return;
    }

    // If ad is not ready and not loading, initiate loading immediately
    if (!_appOpenReady && !_appOpenLoading) {
      debugPrint('[AdService] App Open ad not loaded; initiating load now...');
      loadAppOpenAd();
    }

    // If ad is currently loading, wait for it with timeout
    if (_appOpenLoading && !_appOpenReady) {
      debugPrint(
        '[AdService] App Open ad loading in progress; awaiting up to ${waitTimeout.inMilliseconds}ms...',
      );
      final completer = Completer<void>();
      void onDone() {
        if (!completer.isCompleted) completer.complete();
      }

      _appOpenLoadListeners.add(onDone);
      await Future.any([completer.future, Future.delayed(waitTimeout)]);
      _appOpenLoadListeners.remove(onDone);
    }

    if (!_appOpenReady || _appOpenAd == null) {
      debugPrint(
        '[AdService] App Open ad not available after waiting. Proceeding.',
      );
      onAdDismissed?.call();
      if (!_appOpenLoading) loadAppOpenAd();
      return;
    }

    // Take ownership and set unavailable before showing
    final ad = _appOpenAd!;
    _appOpenAd = null;
    _appOpenReady = false;
    _isShowingFullScreenAd = true;
    _lastAppOpenShownAt = DateTime.now();

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        _isShowingFullScreenAd = true;
        debugPrint('[AdService] App Open Ad showed full-screen content.');
        onAdShowed?.call();
      },
      onAdDismissedFullScreenContent: (ad) {
        _isShowingFullScreenAd = false;
        _lastFullScreenAdDismissedAt = DateTime.now();
        ad.dispose();
        debugPrint('[AdService] App Open Ad dismissed by user.');
        onAdDismissed?.call();
        loadAppOpenAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        _isShowingFullScreenAd = false;
        _lastFullScreenAdDismissedAt = DateTime.now();
        ad.dispose();
        debugPrint('[AdService] App Open Ad failed to show: $error');
        onAdDismissed?.call();
        loadAppOpenAd();
      },
    );

    try {
      debugPrint('[AdService] Presenting App Open Ad now...');
      ad.show();
    } catch (e) {
      debugPrint('[AdService] Exception during ad.show(): $e');
      _isShowingFullScreenAd = false;
      ad.dispose();
      onAdDismissed?.call();
      loadAppOpenAd();
    }
  }

  // ─── INTERSTITIAL AD ─────────────────────────────────────────────────────

  bool get isInterstitialReady =>
      _interstitialReady && _interstitialAd != null && !_isShowingFullScreenAd;

  void loadInterstitialAd() {
    if (_interstitialReady || _interstitialLoading) return;
    if (!Platform.isAndroid && !Platform.isIOS) return;

    _interstitialLoading = true;
    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _interstitialReady = true;
          _interstitialLoading = false;
          debugPrint('[AdService] Interstitial Ad loaded.');
        },
        onAdFailedToLoad: (error) {
          _interstitialAd = null;
          _interstitialReady = false;
          _interstitialLoading = false;
          debugPrint('[AdService] Interstitial Ad failed: $error');
        },
      ),
    );
  }

  /// Triggers an interstitial at natural breaks after user actions.
  /// Follows a frequency cap (every [actionInterval] actions) and minimum 90-sec cooldown.
  void showInterstitialIfReady({
    VoidCallback? onDone,
    int actionInterval = interstitialActionInterval,
  }) {
    _interstitialActionCount++;

    // 1. Frequency cap check (e.g. every 3rd action)
    if (_interstitialActionCount % actionInterval != 0) {
      onDone?.call();
      return;
    }

    // 2. Mutual exclusion check
    if (_isShowingFullScreenAd) {
      onDone?.call();
      return;
    }

    final now = DateTime.now();

    // 3. 90-second minimum cooldown check
    if (_lastInterstitialShownAt != null &&
        now.difference(_lastInterstitialShownAt!) < interstitialCooldown) {
      debugPrint('[AdService] Interstitial skipped: cooldown active.');
      onDone?.call();
      return;
    }

    // 4. Buffer check from other full-screen ads
    if (_lastFullScreenAdDismissedAt != null &&
        now.difference(_lastFullScreenAdDismissedAt!) <
            const Duration(seconds: 15)) {
      onDone?.call();
      return;
    }

    // 5. Check readiness
    if (!_interstitialReady || _interstitialAd == null) {
      onDone?.call();
      if (!_interstitialLoading) loadInterstitialAd();
      return;
    }

    // Set ad as unavailable before showing
    final ad = _interstitialAd!;
    _interstitialAd = null;
    _interstitialReady = false;
    _isShowingFullScreenAd = true;
    _lastInterstitialShownAt = now;

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        _isShowingFullScreenAd = false;
        _lastFullScreenAdDismissedAt = DateTime.now();
        ad.dispose();
        onDone?.call();
        loadInterstitialAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        _isShowingFullScreenAd = false;
        _lastFullScreenAdDismissedAt = DateTime.now();
        ad.dispose();
        onDone?.call();
        loadInterstitialAd();
      },
    );

    ad.show();
  }

  // ─── REWARDED AD ─────────────────────────────────────────────────────────

  bool get isRewardedAdReady =>
      _rewardedReady && _rewardedAd != null && !_isShowingFullScreenAd;

  void loadRewardedAd() {
    if (_rewardedReady || _rewardedLoading) return;
    if (!Platform.isAndroid && !Platform.isIOS) return;

    _rewardedLoading = true;
    RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _rewardedReady = true;
          _rewardedLoading = false;
          debugPrint('[AdService] Rewarded Ad loaded.');
        },
        onAdFailedToLoad: (error) {
          _rewardedAd = null;
          _rewardedReady = false;
          _rewardedLoading = false;
          debugPrint('[AdService] Rewarded Ad failed: $error');
        },
      ),
    );
  }

  /// Show a Rewarded Ad when the user deliberately requests it.
  /// Guarantees [onRewarded] is invoked at most once strictly through [onUserEarnedReward].
  void showRewardedAd({
    required VoidCallback onRewarded,
    VoidCallback? onFailed,
    VoidCallback? onDismissed,
  }) {
    if (!isRewardedAdReady) {
      onFailed?.call();
      if (!_rewardedLoading) loadRewardedAd();
      return;
    }

    final ad = _rewardedAd!;
    _rewardedAd = null;
    _rewardedReady = false;
    _isShowingFullScreenAd = true;

    bool rewardGranted = false;

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        _isShowingFullScreenAd = false;
        _lastFullScreenAdDismissedAt = DateTime.now();
        ad.dispose();
        onDismissed?.call();
        loadRewardedAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        _isShowingFullScreenAd = false;
        _lastFullScreenAdDismissedAt = DateTime.now();
        ad.dispose();
        onFailed?.call();
        loadRewardedAd();
      },
    );

    ad.show(
      onUserEarnedReward: (ad, reward) {
        if (!rewardGranted) {
          rewardGranted = true;
          onRewarded();
        }
      },
    );
  }

  // ─── BANNER AD FACTORY ───────────────────────────────────────────────────

  BannerAd createBannerAd({BannerAdListener? listener}) {
    return BannerAd(
      adUnitId: bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: listener ?? const BannerAdListener(),
    );
  }

  // ─── APP LIFECYCLE OBSERVER ──────────────────────────────────────────────

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      _appPausedAt ??= DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      final pausedAt = _appPausedAt;
      _appPausedAt = null;

      if (pausedAt != null) {
        final timeInBackground = DateTime.now().difference(pausedAt);
        debugPrint(
          '[AdService] App resumed after ${timeInBackground.inSeconds}s in background.',
        );

        // Only trigger on genuine background return (exceeding standard 90 seconds)
        // and when not suppressed by file pickers, dialogs, or active full-screen ads.
        if (timeInBackground >= minBackgroundDurationForAppOpen &&
            !_isShowingFullScreenAd &&
            !isAppOpenSuppressed &&
            !isAppOpenCooldownActive) {
          showAppOpenAd();
        }
      }
    }
  }

  // ─── DISPOSAL ────────────────────────────────────────────────────────────

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _appOpenAd?.dispose();
    _appOpenAd = null;
    _appOpenReady = false;

    _interstitialAd?.dispose();
    _interstitialAd = null;
    _interstitialReady = false;

    _rewardedAd?.dispose();
    _rewardedAd = null;
    _rewardedReady = false;
  }
}
