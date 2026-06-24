import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_soloud/flutter_soloud.dart';

/// Handles audio effects (Equalizer, Bass, Normalization, PitchShift,
/// Reverb, Compressor) via flutter_soloud global filters.
class AudioEffectService {
  final _soloud = SoLoud.instance;

  final ValueNotifier<int> bassLevelNotifier = ValueNotifier(0);
  final ValueNotifier<double> crossfadeDurationNotifier = ValueNotifier(3.0);
  final ValueNotifier<int> crossfadeCurveNotifier = ValueNotifier(0); // 0=linear, 1=exponential, 2=sCurve
  final ValueNotifier<double> normalizationLevelNotifier = ValueNotifier(0.0);
  final ValueNotifier<double> pitchShiftNotifier = ValueNotifier(1.0);
  final ValueNotifier<double> reverbMixNotifier = ValueNotifier(0.0);
  final ValueNotifier<double> compressionRatioNotifier = ValueNotifier(1.0);

  // Advanced reverb params
  final ValueNotifier<double> reverbRoomSizeNotifier = ValueNotifier(0.5);
  final ValueNotifier<double> reverbDampNotifier = ValueNotifier(0.5);

  // Advanced compressor params
  final ValueNotifier<double> compThresholdNotifier = ValueNotifier(-6.0);
  final ValueNotifier<double> compAttackNotifier = ValueNotifier(10.0);
  final ValueNotifier<double> compReleaseNotifier = ValueNotifier(100.0);
  final ValueNotifier<double> compKneeWidthNotifier = ValueNotifier(2.0);
  final ValueNotifier<double> compMakeupGainNotifier = ValueNotifier(0.0);

  bool _bassActive = false;
  bool _eqInitialized = false;
  bool _normalizationEnabled = false;
  bool _pitchActive = false;
  bool _reverbActive = false;
  bool _compressorActive = false;

  AudioEffectService();

  // ─── Bass Boost ────────────────────────────────────────────────────────────

  void setBassLevel(int level) {
    final clamped = level.clamp(0, 100);
    bassLevelNotifier.value = clamped;

    if (!_soloud.isInitialized) return;

    try {
      final bassFilter = _soloud.filters.bassBoostFilter;

      if (!_bassActive) {
        bassFilter.activate();
        _bassActive = true;
      }

      if (clamped == 0) {
        bassFilter.wet.value = 0.0;
      } else {
        bassFilter.wet.value = 1.0;
        bassFilter.boost.value = (clamped / 100.0) * 10.0;
      }
    } catch (e) {
      debugPrint('setBassLevel error: $e');
    }
  }

  // ─── Equalizer (5-band EQ) ───────────────────────────────────────────────

  void applyAllEqualizer(List<double> bands) {
    if (!_soloud.isInitialized) return;
    if (bands.length != 5) return;

    try {
      final eq = _soloud.filters.parametricEqFilter;

      if (!_eqInitialized) {
        eq.activate();
        eq.numBands.value = 5.0;
        _eqInitialized = true;
      }

      final allZero = bands.every((b) => b.abs() < 0.05);
      if (allZero) {
        eq.wet.value = 0.0;
        return;
      }

      eq.wet.value = 1.0;

      for (int i = 0; i < 5; i++) {
        eq.bandGain(i).value = _uiValueToEqGain(bands[i]);
      }
    } catch (e) {
      debugPrint('applyAllEqualizer error: $e');
    }
  }

  static double _uiValueToEqGain(double uiValue) {
    if (uiValue <= 0) {
      return (1.0 + uiValue).clamp(0.0, 1.0);
    }
    return (1.0 + uiValue * 3.0).clamp(1.0, 4.0);
  }

  // ─── Volume Normalization ───────────────────────────────────────────────────

  void setNormalizationLevel(double level) {
    normalizationLevelNotifier.value = level.clamp(-24.0, 0.0);
    _normalizationEnabled = level > -24.0;
  }

  void enableNormalization(bool enabled) {
    _normalizationEnabled = enabled;
  }

  double calculateNormalizationGain(double trackPeakDb) {
    if (!_normalizationEnabled) return 1.0;
    final targetDb = normalizationLevelNotifier.value;
    final gainDb = targetDb - trackPeakDb;
    return _dbToLinear(gainDb);
  }

  double _dbToLinear(double db) {
    if (db <= -24.0) return 0.0;
    if (db >= 0.0) return 1.0;
    return pow(10.0, db / 20.0).toDouble();
  }

  // ─── Pitch Shift (Real) ────────────────────────────────────────────────────

  void setPitchShift(double pitch) {
    final clamped = pitch.clamp(0.5, 2.0);
    pitchShiftNotifier.value = clamped;

    if (!_soloud.isInitialized) return;

    try {
      final filter = _soloud.filters.pitchShiftFilter;

      if (!_pitchActive) {
        filter.activate();
        _pitchActive = true;
      }

      // Bypass when pitch is default (1.0)
      if ((clamped - 1.0).abs() < 0.01) {
        filter.wet.value = 0.0;
      } else {
        filter.wet.value = 1.0;
        filter.shift.value = clamped;
      }
    } catch (e) {
      debugPrint('setPitchShift error: $e');
    }
  }

  // ─── Reverb / Freeverb (Real) ──────────────────────────────────────────────

  void setReverbMix(double mix) {
    final clamped = mix.clamp(0.0, 1.0);
    reverbMixNotifier.value = clamped;

    if (!_soloud.isInitialized) return;

    try {
      final filter = _soloud.filters.freeverbFilter;

      if (!_reverbActive) {
        filter.activate();
        _reverbActive = true;
      }

      if (clamped < 0.01) {
        filter.wet.value = 0.0;
      } else {
        filter.wet.value = clamped;
        filter.roomSize.value = reverbRoomSizeNotifier.value;
        filter.damp.value = reverbDampNotifier.value;
      }
    } catch (e) {
      debugPrint('setReverbMix error: $e');
    }
  }

  void setReverbRoomSize(double size) {
    reverbRoomSizeNotifier.value = size.clamp(0.0, 1.0);
    if (!_soloud.isInitialized || !_reverbActive) return;
    try {
      _soloud.filters.freeverbFilter.roomSize.value = reverbRoomSizeNotifier.value;
    } catch (e) {
      debugPrint('setReverbRoomSize error: $e');
    }
  }

  void setReverbDamp(double damp) {
    reverbDampNotifier.value = damp.clamp(0.0, 1.0);
    if (!_soloud.isInitialized || !_reverbActive) return;
    try {
      _soloud.filters.freeverbFilter.damp.value = reverbDampNotifier.value;
    } catch (e) {
      debugPrint('setReverbDamp error: $e');
    }
  }

  // ─── Compressor (Real) ─────────────────────────────────────────────────────

  void setCompressionRatio(double ratio) {
    final clamped = ratio.clamp(1.0, 10.0);
    compressionRatioNotifier.value = clamped;

    if (!_soloud.isInitialized) return;

    try {
      final filter = _soloud.filters.compressorFilter;

      if (!_compressorActive) {
        filter.activate();
        _compressorActive = true;
      }

      // Bypass when ratio is 1:1 (no compression)
      if ((clamped - 1.0).abs() < 0.01) {
        filter.wet.value = 0.0;
      } else {
        filter.wet.value = 1.0;
        filter.ratio.value = clamped;
        filter.threshold.value = compThresholdNotifier.value;
        filter.attackTime.value = compAttackNotifier.value;
        filter.releaseTime.value = compReleaseNotifier.value;
        filter.kneeWidth.value = compKneeWidthNotifier.value;
        filter.makeupGain.value = compMakeupGainNotifier.value;
      }
    } catch (e) {
      debugPrint('setCompressionRatio error: $e');
    }
  }

  void setCompThreshold(double threshold) {
    compThresholdNotifier.value = threshold.clamp(-80.0, 0.0);
    if (!_soloud.isInitialized || !_compressorActive) return;
    try {
      _soloud.filters.compressorFilter.threshold.value = compThresholdNotifier.value;
    } catch (e) {
      debugPrint('compressor threshold error: $e');
    }
  }

  void setCompAttack(double attack) {
    compAttackNotifier.value = attack.clamp(0.0, 100.0);
    if (!_soloud.isInitialized || !_compressorActive) return;
    try {
      _soloud.filters.compressorFilter.attackTime.value = compAttackNotifier.value;
    } catch (e) {
      debugPrint('compressor attack error: $e');
    }
  }

  void setCompRelease(double release) {
    compReleaseNotifier.value = release.clamp(0.0, 1000.0);
    if (!_soloud.isInitialized || !_compressorActive) return;
    try {
      _soloud.filters.compressorFilter.releaseTime.value = compReleaseNotifier.value;
    } catch (e) {
      debugPrint('compressor release error: $e');
    }
  }

  void setCompKneeWidth(double knee) {
    compKneeWidthNotifier.value = knee.clamp(0.0, 40.0);
    if (!_soloud.isInitialized || !_compressorActive) return;
    try {
      _soloud.filters.compressorFilter.kneeWidth.value = compKneeWidthNotifier.value;
    } catch (e) {
      debugPrint('compressor kneeWidth error: $e');
    }
  }

  void setCompMakeupGain(double gain) {
    compMakeupGainNotifier.value = gain.clamp(-40.0, 40.0);
    if (!_soloud.isInitialized || !_compressorActive) return;
    try {
      _soloud.filters.compressorFilter.makeupGain.value = compMakeupGainNotifier.value;
    } catch (e) {
      debugPrint('compressor makeupGain error: $e');
    }
  }

  // ─── Crossfade ─────────────────────────────────────────────────────────────

  void setCrossfadeDuration(double seconds) {
    crossfadeDurationNotifier.value = seconds.clamp(0.0, 10.0);
  }

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
}
