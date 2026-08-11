import 'package:flutter/services.dart';

import '../settings_manager.dart';
import '../logging/app_logger.dart';

class FeedbackService {
  final SettingsManager _settings;
  bool _canVibrate = false;

  FeedbackService(this._settings) {
    _init();
  }

  Future<void> _init() async {
    try {
      _canVibrate = true; // Can't easily check async, just assume yes for now
    } catch (e) {
      AppLogger.w('Feedback', 'Failed to check haptics support: $e');
    }
  }

  Future<void> playClick() async {
    if (_settings.soundFeedbackEnabledNotifier.value) {
      // SystemSound.play returns a Future that can throw (MissingPlugin
      // on some desktop configs) — await + swallow so it never becomes an
      // unhandled async exception.
      try {
        await SystemSound.play(SystemSoundType.click);
      } catch (_) {}
    }

    if (_settings.hapticFeedbackEnabledNotifier.value && _canVibrate) {
      try {
        await HapticFeedback.lightImpact();
      } catch (e, st) {
        AppLogger.w(
          'Feedback',
          'Failed to play haptic: $e',
          error: e,
          stack: st,
        );
      }
    }
  }

  Future<void> playMedium() async {
    if (_settings.hapticFeedbackEnabledNotifier.value && _canVibrate) {
      try {
        await HapticFeedback.mediumImpact();
      } catch (e, st) {
        AppLogger.w(
          'Feedback',
          'Failed to play haptic: $e',
          error: e,
          stack: st,
        );
      }
    }
  }

  Future<void> playHeavy() async {
    if (_settings.hapticFeedbackEnabledNotifier.value && _canVibrate) {
      try {
        await HapticFeedback.heavyImpact();
      } catch (e, st) {
        AppLogger.w(
          'Feedback',
          'Failed to play haptic: $e',
          error: e,
          stack: st,
        );
      }
    }
  }
}
