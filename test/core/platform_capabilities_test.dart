import 'package:flutter_test/flutter_test.dart';
import 'package:ga_song/core/platform_capabilities.dart';

/// Verifies that enabling the Android "Reduce Lag"
/// override pins every performance knob to its LOWEST value, regardless of
/// the real detected tier (AC: "mọi getter trả giá trị ≤ low-tier").
///
/// Tests run on the host (desktop), so the real `deviceTier` is high — a
/// perfect setup: with the override ON every knob must drop to the low-tier
/// value, with it OFF they must stay at the host's normal values.
void main() {
  final caps = PlatformCapabilities.instance;

  setUp(() {
    caps.reduceLagOverride = false;
  });

  tearDown(() {
    caps.reduceLagOverride = false;
  });

  group('Reduce Lag override', () {
    test('effectiveTier forces low while deviceTier stays real', () {
      expect(caps.effectiveTier, caps.deviceTier);
      caps.reduceLagOverride = true;
      expect(caps.effectiveTier, DeviceTier.low);
      // The real detected tier is untouched — only the effective one is pinned.
      expect(caps.deviceTier, isNot(DeviceTier.low));
    });

    test('int knobs drop to documented low-tier values when ON', () {
      final expectations = <String, (int Function(), int)>{
        'maxAudioSourceCacheEntries': (
          () => caps.maxAudioSourceCacheEntries,
          6,
        ),
        'maxCoverArtCacheEntries': (() => caps.maxCoverArtCacheEntries, 12),
        'maxParticleCount': (() => caps.maxParticleCount, 30),
        'maxStarCount': (() => caps.maxStarCount, 40),
        'preloadConcurrency': (() => caps.preloadConcurrency, 1),
        'visualizerFrameBudgetMs': (() => caps.visualizerFrameBudgetMs, 33),
        'maxConcurrentImageDecodes': (() => caps.maxConcurrentImageDecodes, 2),
      };

      for (final entry in expectations.entries) {
        caps.reduceLagOverride = true;
        final (getter, low) = entry.value;
        expect(
          getter(),
          low,
          reason: '${entry.key} should equal its low-tier value',
        );
      }
    });

    test('positionTimerInterval slows to 600ms when ON', () {
      caps.reduceLagOverride = true;
      expect(caps.positionTimerInterval, const Duration(milliseconds: 600));
    });

    test('backgroundBlurSigma drops to 8 when ON', () {
      caps.reduceLagOverride = true;
      expect(caps.backgroundBlurSigma, 8);
    });

    test('boolean flags disable when ON', () {
      final flags = <String, bool Function()>{
        'allowHighQualityBlur': () => caps.allowHighQualityBlur,
        'allowStarfieldBackground': () => caps.allowStarfieldBackground,
        'allowShimmerLoading': () => caps.allowShimmerLoading,
        'allowPageTransitions': () => caps.allowPageTransitions,
        'enableBackgroundScanning': () => caps.enableBackgroundScanning,
      };

      caps.reduceLagOverride = true;
      for (final entry in flags.entries) {
        expect(entry.value(), isFalse, reason: '${entry.key} should be off');
      }
    });

    test('turning OFF restores normal values', () {
      final normalParticles = caps.maxParticleCount;
      final normalBudget = caps.visualizerFrameBudgetMs;
      final normalTransitions = caps.allowPageTransitions;

      caps.reduceLagOverride = true;
      expect(caps.maxParticleCount, lessThan(normalParticles));
      caps.reduceLagOverride = false;

      expect(caps.maxParticleCount, normalParticles);
      expect(caps.visualizerFrameBudgetMs, normalBudget);
      expect(caps.allowPageTransitions, normalTransitions);
    });
  });
}
