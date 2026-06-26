import 'package:flutter/foundation.dart';
import 'package:ga_song/core/audio/audio_effect_service.dart';

/// Mock implementation of [AudioEffectService] for testing.
/// Uses `implements` instead of `extends` to avoid SoLoud native dependency.
class MockAudioEffectService implements AudioEffectService {
  @override
  ValueNotifier<int> bassLevelNotifier = ValueNotifier(0);
  @override
  ValueNotifier<double> crossfadeDurationNotifier = ValueNotifier(3.0);
  @override
  ValueNotifier<double> normalizationLevelNotifier = ValueNotifier(0.0);
  @override
  ValueNotifier<double> pitchShiftNotifier = ValueNotifier(1.0);
  @override
  ValueNotifier<double> reverbMixNotifier = ValueNotifier(0.0);
  @override
  ValueNotifier<double> compressionRatioNotifier = ValueNotifier(1.0);
  @override
  ValueNotifier<double> reverbRoomSizeNotifier = ValueNotifier(0.5);
  @override
  ValueNotifier<double> reverbDampNotifier = ValueNotifier(0.5);
  @override
  ValueNotifier<double> compThresholdNotifier = ValueNotifier(-6.0);
  @override
  ValueNotifier<double> compAttackNotifier = ValueNotifier(10.0);
  @override
  ValueNotifier<double> compReleaseNotifier = ValueNotifier(100.0);
  @override
  ValueNotifier<double> compKneeWidthNotifier = ValueNotifier(2.0);
  @override
  ValueNotifier<double> compMakeupGainNotifier = ValueNotifier(0.0);

  bool _normalizationEnabled = false;

  @override
  void setBassLevel(int level) {
    bassLevelNotifier.value = level.clamp(0, 100);
  }

  @override
  void applyAllEqualizer(List<double> bands) {
    // No-op in mock
  }

  @override
  void setNormalizationLevel(double level) {
    normalizationLevelNotifier.value = level.clamp(-24.0, 0.0);
  }

  @override
  void enableNormalization(bool enabled) {
    _normalizationEnabled = enabled;
  }

  @override
  double calculateNormalizationGain(double trackPeakDb) {
    if (!_normalizationEnabled) return 1.0;
    final targetDb = normalizationLevelNotifier.value;
    final gainDb = targetDb - trackPeakDb;
    if (gainDb <= -24.0) return 0.0;
    // Convert dB to linear: 10^(gainDb/20)
    return _dbToLinear(gainDb);
  }

  double _dbToLinear(double db) {
    if (db <= -24.0) return 0.0;
    if (db >= 24.0) return 15.85; // clamp max gain
    // Simple approximation
    return (1.0 + db / 20.0).clamp(0.0, 15.85);
  }

  @override
  void setPitchShift(double pitch) {
    pitchShiftNotifier.value = pitch.clamp(0.5, 2.0);
  }

  @override
  void setReverbMix(double mix) {
    reverbMixNotifier.value = mix.clamp(0.0, 1.0);
  }

  @override
  void setReverbRoomSize(double size) {
    reverbRoomSizeNotifier.value = size.clamp(0.0, 1.0);
  }

  @override
  void setReverbDamp(double damp) {
    reverbDampNotifier.value = damp.clamp(0.0, 1.0);
  }

  @override
  void setCompressionRatio(double ratio) {
    compressionRatioNotifier.value = ratio.clamp(1.0, 10.0);
  }

  @override
  void setCompThreshold(double threshold) {
    compThresholdNotifier.value = threshold.clamp(-80.0, 0.0);
  }

  @override
  void setCompAttack(double attack) {
    compAttackNotifier.value = attack.clamp(0.0, 100.0);
  }

  @override
  void setCompRelease(double release) {
    compReleaseNotifier.value = release.clamp(0.0, 1000.0);
  }

  @override
  void setCompKneeWidth(double knee) {
    compKneeWidthNotifier.value = knee.clamp(0.0, 40.0);
  }

  @override
  void setCompMakeupGain(double gain) {
    compMakeupGainNotifier.value = gain.clamp(-40.0, 40.0);
  }

  @override
  void setCrossfadeDuration(double seconds) {
    crossfadeDurationNotifier.value = seconds.clamp(0.0, 10.0);
  }

  @override
  void dispose() {
    bassLevelNotifier.dispose();
    crossfadeDurationNotifier.dispose();
    normalizationLevelNotifier.dispose();
    pitchShiftNotifier.dispose();
    reverbMixNotifier.dispose();
    compressionRatioNotifier.dispose();
    reverbRoomSizeNotifier.dispose();
    reverbDampNotifier.dispose();
    compThresholdNotifier.dispose();
    compAttackNotifier.dispose();
    compReleaseNotifier.dispose();
    compKneeWidthNotifier.dispose();
    compMakeupGainNotifier.dispose();
  }

  // Handle any other methods not explicitly overridden
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
