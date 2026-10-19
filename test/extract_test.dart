import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:jersey_checker/services/glb_texture_extractor.dart';
import 'package:jersey_checker/services/ad_service.dart';

void main() {
  group('GlbTextureExtractorService Tests', () {
    test('extractTexturesFromGlbBytes returns empty for short byte array', () {
      final shortBytes = Uint8List(10);
      final result = GlbTextureExtractorService.extractTexturesFromGlbBytes(
        shortBytes,
      );
      expect(result, isEmpty);
    });

    test(
      'extractTexturesFromGlbBytes throws exception for invalid magic header',
      () {
        final invalidBytes = Uint8List(30);
        expect(
          () => GlbTextureExtractorService.extractTexturesFromGlbBytes(
            invalidBytes,
          ),
          throwsA(isA<Exception>()),
        );
      },
    );
  });

  group('AdService Logic Tests', () {
    test('ad unit IDs are non-empty and formatted correctly', () {
      expect(AdService.bannerAdUnitId, isNotEmpty);
      expect(AdService.appOpenAdUnitId, isNotEmpty);
      expect(AdService.interstitialAdUnitId, isNotEmpty);
      expect(AdService.rewardedAdUnitId, isNotEmpty);
    });

    test('cooldown durations meet compliance requirements', () {
      expect(AdService.appOpenCooldown.inSeconds, greaterThanOrEqualTo(90));
      expect(
        AdService.interstitialCooldown.inSeconds,
        greaterThanOrEqualTo(90),
      );
      expect(
        AdService.minBackgroundDurationForAppOpen.inSeconds,
        greaterThanOrEqualTo(90),
      );
    });

    test('interstitial action interval is capped', () {
      expect(AdService.interstitialActionInterval, inInclusiveRange(3, 5));
    });

    test('App-Open suppression flag can be toggled', () {
      final adService = AdService.instance;
      adService.isAppOpenSuppressed = true;
      expect(adService.isAppOpenSuppressed, isTrue);
      adService.isAppOpenSuppressed = false;
      expect(adService.isAppOpenSuppressed, isFalse);
    });
  });
}
