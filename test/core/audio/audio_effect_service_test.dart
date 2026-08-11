import 'package:flutter_test/flutter_test.dart';
import '../../mocks/mock_audio_effect_service.dart';

void main() {
  group('AudioEffectService (via MockAudioEffectService)', () {
    late MockAudioEffectService service;

    setUp(() {
      service = MockAudioEffectService();
    });

    tearDown(() {
      service.dispose();
    });

    // ─── Bass Level ────────────────────────────────────────────────────

    group('setBassLevel', () {
      test('updates bassLevelNotifier', () {
        service.setBassLevel(50);
        expect(service.bassLevelNotifier.value, 50);
      });

      test('clamps to 0 minimum', () {
        service.setBassLevel(-10);
        expect(service.bassLevelNotifier.value, 0);
      });

      test('clamps to 100 maximum', () {
        service.setBassLevel(150);
        expect(service.bassLevelNotifier.value, 100);
      });

      test('accepts boundary value 0', () {
        service.setBassLevel(0);
        expect(service.bassLevelNotifier.value, 0);
      });

      test('accepts boundary value 100', () {
        service.setBassLevel(100);
        expect(service.bassLevelNotifier.value, 100);
      });
    });

    // ─── Crossfade Duration ────────────────────────────────────────────

    group('setCrossfadeDuration', () {
      test('updates crossfadeDurationNotifier', () {
        service.setCrossfadeDuration(5);
        expect(service.crossfadeDurationNotifier.value, 5.0);
      });

      test('clamps to 0 minimum', () {
        service.setCrossfadeDuration(-1);
        expect(service.crossfadeDurationNotifier.value, 0.0);
      });

      test('clamps to 10 maximum', () {
        service.setCrossfadeDuration(15);
        expect(service.crossfadeDurationNotifier.value, 10.0);
      });

      test('accepts zero', () {
        service.setCrossfadeDuration(0);
        expect(service.crossfadeDurationNotifier.value, 0.0);
      });
    });

    // ─── Normalization ─────────────────────────────────────────────────

    group('setNormalizationLevel', () {
      test('updates normalizationLevelNotifier', () {
        service.setNormalizationLevel(-12);
        expect(service.normalizationLevelNotifier.value, -12.0);
      });

      test('clamps to -24 minimum', () {
        service.setNormalizationLevel(-30);
        expect(service.normalizationLevelNotifier.value, -24.0);
      });

      test('clamps to 0 maximum', () {
        service.setNormalizationLevel(5);
        expect(service.normalizationLevelNotifier.value, 0.0);
      });
    });

    group('calculateNormalizationGain', () {
      test('returns 1.0 when normalization is disabled', () {
        service.enableNormalization(false);
        final gain = service.calculateNormalizationGain(-12);
        expect(gain, 1.0);
      });

      test('returns gain when normalization is enabled', () {
        service.enableNormalization(true);
        service.setNormalizationLevel(-12);
        final gain = service.calculateNormalizationGain(-12);
        expect(gain, 1.0);
      });

      test('returns >1.0 when track is quieter than target', () {
        service.enableNormalization(true);
        service.setNormalizationLevel(-12);
        final gain = service.calculateNormalizationGain(-18);
        expect(gain, greaterThan(1.0));
      });

      test('returns <1.0 when track is louder than target', () {
        service.enableNormalization(true);
        service.setNormalizationLevel(-12);
        final gain = service.calculateNormalizationGain(-6);
        expect(gain, lessThan(1.0));
      });
    });

    // ─── Pitch Shift ───────────────────────────────────────────────────

    group('setPitchShift', () {
      test('updates pitchShiftNotifier', () {
        service.setPitchShift(1.5);
        expect(service.pitchShiftNotifier.value, 1.5);
      });

      test('clamps to 0.5 minimum', () {
        service.setPitchShift(0.1);
        expect(service.pitchShiftNotifier.value, 0.5);
      });

      test('clamps to 2.0 maximum', () {
        service.setPitchShift(3);
        expect(service.pitchShiftNotifier.value, 2.0);
      });
    });

    // ─── Reverb ────────────────────────────────────────────────────────

    group('setReverbMix', () {
      test('updates reverbMixNotifier', () {
        service.setReverbMix(0.5);
        expect(service.reverbMixNotifier.value, 0.5);
      });

      test('clamps to 0 minimum', () {
        service.setReverbMix(-0.5);
        expect(service.reverbMixNotifier.value, 0.0);
      });

      test('clamps to 1 maximum', () {
        service.setReverbMix(1.5);
        expect(service.reverbMixNotifier.value, 1.0);
      });
    });

    group('setReverbRoomSize', () {
      test('updates reverbRoomSizeNotifier', () {
        service.setReverbRoomSize(0.7);
        expect(service.reverbRoomSizeNotifier.value, 0.7);
      });

      test('clamps to 0-1 range', () {
        service.setReverbRoomSize(-0.1);
        expect(service.reverbRoomSizeNotifier.value, 0.0);
        service.setReverbRoomSize(1.5);
        expect(service.reverbRoomSizeNotifier.value, 1.0);
      });
    });

    group('setReverbDamp', () {
      test('updates reverbDampNotifier', () {
        service.setReverbDamp(0.3);
        expect(service.reverbDampNotifier.value, 0.3);
      });
    });

    // ─── Compressor ────────────────────────────────────────────────────

    group('setCompressionRatio', () {
      test('updates compressionRatioNotifier', () {
        service.setCompressionRatio(4);
        expect(service.compressionRatioNotifier.value, 4.0);
      });

      test('clamps to 1.0 minimum', () {
        service.setCompressionRatio(0.5);
        expect(service.compressionRatioNotifier.value, 1.0);
      });

      test('clamps to 10.0 maximum', () {
        service.setCompressionRatio(15);
        expect(service.compressionRatioNotifier.value, 10.0);
      });
    });

    group('setCompThreshold', () {
      test('updates compThresholdNotifier', () {
        service.setCompThreshold(-20);
        expect(service.compThresholdNotifier.value, -20.0);
      });

      test('clamps to -80 to 0 range', () {
        service.setCompThreshold(-100);
        expect(service.compThresholdNotifier.value, -80.0);
        service.setCompThreshold(10);
        expect(service.compThresholdNotifier.value, 0.0);
      });
    });

    group('setCompAttack', () {
      test('updates compAttackNotifier', () {
        service.setCompAttack(50);
        expect(service.compAttackNotifier.value, 50.0);
      });

      test('clamps to 0-100 range', () {
        service.setCompAttack(-5);
        expect(service.compAttackNotifier.value, 0.0);
        service.setCompAttack(150);
        expect(service.compAttackNotifier.value, 100.0);
      });
    });

    group('setCompRelease', () {
      test('updates compReleaseNotifier', () {
        service.setCompRelease(500);
        expect(service.compReleaseNotifier.value, 500.0);
      });

      test('clamps to 0-1000 range', () {
        service.setCompRelease(-10);
        expect(service.compReleaseNotifier.value, 0.0);
        service.setCompRelease(1500);
        expect(service.compReleaseNotifier.value, 1000.0);
      });
    });

    group('setCompKneeWidth', () {
      test('updates compKneeWidthNotifier', () {
        service.setCompKneeWidth(10);
        expect(service.compKneeWidthNotifier.value, 10.0);
      });

      test('clamps to 0-40 range', () {
        service.setCompKneeWidth(-1);
        expect(service.compKneeWidthNotifier.value, 0.0);
        service.setCompKneeWidth(50);
        expect(service.compKneeWidthNotifier.value, 40.0);
      });
    });

    group('setCompMakeupGain', () {
      test('updates compMakeupGainNotifier', () {
        service.setCompMakeupGain(6);
        expect(service.compMakeupGainNotifier.value, 6.0);
      });

      test('clamps to -40 to 40 range', () {
        service.setCompMakeupGain(-50);
        expect(service.compMakeupGainNotifier.value, -40.0);
        service.setCompMakeupGain(50);
        expect(service.compMakeupGainNotifier.value, 40.0);
      });
    });

    // ─── Notifier Defaults ─────────────────────────────────────────────

    group('default values', () {
      test('bassLevelNotifier defaults to 0', () {
        expect(service.bassLevelNotifier.value, 0);
      });

      test('crossfadeDurationNotifier defaults to 3.0', () {
        expect(service.crossfadeDurationNotifier.value, 3.0);
      });

      test('normalizationLevelNotifier defaults to 0.0', () {
        expect(service.normalizationLevelNotifier.value, 0.0);
      });

      test('pitchShiftNotifier defaults to 1.0', () {
        expect(service.pitchShiftNotifier.value, 1.0);
      });

      test('reverbMixNotifier defaults to 0.0', () {
        expect(service.reverbMixNotifier.value, 0.0);
      });

      test('compressionRatioNotifier defaults to 1.0', () {
        expect(service.compressionRatioNotifier.value, 1.0);
      });

      test('reverbRoomSizeNotifier defaults to 0.5', () {
        expect(service.reverbRoomSizeNotifier.value, 0.5);
      });

      test('reverbDampNotifier defaults to 0.5', () {
        expect(service.reverbDampNotifier.value, 0.5);
      });

      test('compThresholdNotifier defaults to -6.0', () {
        expect(service.compThresholdNotifier.value, -6.0);
      });

      test('compAttackNotifier defaults to 10.0', () {
        expect(service.compAttackNotifier.value, 10.0);
      });

      test('compReleaseNotifier defaults to 100.0', () {
        expect(service.compReleaseNotifier.value, 100.0);
      });

      test('compKneeWidthNotifier defaults to 2.0', () {
        expect(service.compKneeWidthNotifier.value, 2.0);
      });

      test('compMakeupGainNotifier defaults to 0.0', () {
        expect(service.compMakeupGainNotifier.value, 0.0);
      });
    });

    // ─── Dispose ───────────────────────────────────────────────────────

    group('dispose', () {
      test('disposes all notifiers without throwing', () {
        final s = MockAudioEffectService();
        expect(() => s.dispose(), returnsNormally);
      });
    });
  });
}
