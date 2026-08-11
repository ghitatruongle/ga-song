/// Mock implementation of [SettingsManager] for testing.
/// Provides controlled settings without SharedPreferences dependency.
library;

import 'dart:async';
import 'dart:ui' show Locale, Offset, Size;
import 'package:flutter/material.dart' show Color, ThemeMode;
import 'package:flutter/foundation.dart';
import 'package:ga_song/core/settings_manager.dart';

class MockSettingsManager implements SettingsManager {
  // ─── Audio Settings ────────────────────────────────────────────────
  @override
  final ValueNotifier<List<double>> eqBandsNotifier = ValueNotifier(
    List.filled(10, 0),
  );
  @override
  final ValueNotifier<int> eqBassNotifier = ValueNotifier(0);
  @override
  final ValueNotifier<double> crossfadeDurationNotifier = ValueNotifier(3);
  @override
  final ValueNotifier<int> crossfadeCurveNotifier = ValueNotifier(0);
  @override
  final ValueNotifier<double> normalizationLevelNotifier = ValueNotifier(-14);
  @override
  final ValueNotifier<bool> normalizationEnabledNotifier = ValueNotifier(false);
  @override
  final ValueNotifier<double> pitchShiftNotifier = ValueNotifier(1);
  @override
  final ValueNotifier<double> reverbMixNotifier = ValueNotifier(0);
  @override
  final ValueNotifier<double> compressionRatioNotifier = ValueNotifier(1);
  @override
  final ValueNotifier<bool> visualizerEnabledNotifier = ValueNotifier(true);
  final ValueNotifier<double> lyricsFontSizeNotifier = ValueNotifier(16);

  @override
  final ValueNotifier<bool> enableBlurNotifier = ValueNotifier(true);
  @override
  final ValueNotifier<double> blurLevelNotifier = ValueNotifier(0);
  @override
  final ValueNotifier<bool> isMiniPlayerNotifier = ValueNotifier(false);
  @override
  final ValueNotifier<bool> isGridViewNotifier = ValueNotifier(false);
  @override
  final ValueNotifier<String?> customBackgroundImageNotifier = ValueNotifier(
    '',
  );
  @override
  final ValueNotifier<int> visualizerShapeNotifier = ValueNotifier(0);
  @override
  final ValueNotifier<bool> sidebarCollapsedNotifier = ValueNotifier(false);
  @override
  final ValueNotifier<bool> desktopLyricsEnabledNotifier = ValueNotifier(false);
  @override
  final ValueNotifier<double> desktopLyricsFontSizeNotifier = ValueNotifier(0);
  @override
  final ValueNotifier<double> desktopLyricsOpacityNotifier = ValueNotifier(0.9);
  @override
  final ValueNotifier<bool> desktopLyricsClickThroughNotifier = ValueNotifier(
    false,
  );
  @override
  final ValueNotifier<double> sensitivityNotifier = ValueNotifier(1);
  @override
  final ValueNotifier<double> lyricFontSizeNotifier = ValueNotifier(1);
  @override
  final ValueNotifier<int> currentTabIndexNotifier = ValueNotifier(0);
  @override
  final ValueNotifier<String> eqPresetNotifier = ValueNotifier('Normal');
  @override
  final ValueNotifier<double> reverbRoomSizeNotifier = ValueNotifier(0.5);
  @override
  final ValueNotifier<double> reverbDampNotifier = ValueNotifier(0.5);
  @override
  final ValueNotifier<double> compThresholdNotifier = ValueNotifier(-6);
  @override
  final ValueNotifier<double> compAttackNotifier = ValueNotifier(10);
  @override
  final ValueNotifier<double> compReleaseNotifier = ValueNotifier(100);
  @override
  final ValueNotifier<double> compKneeWidthNotifier = ValueNotifier(2);
  @override
  final ValueNotifier<double> compMakeupGainNotifier = ValueNotifier(0);
  @override
  final ValueNotifier<int> sortModeNotifier = ValueNotifier(0);
  @override
  final ValueNotifier<bool> sortAscendingNotifier = ValueNotifier(true);
  @override
  final ValueNotifier<bool> soundFeedbackEnabledNotifier = ValueNotifier(false);
  @override
  final ValueNotifier<bool> hapticFeedbackEnabledNotifier = ValueNotifier(true);

  // ─── UI Settings ───────────────────────────────────────────────────
  @override
  final ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier(
    ThemeMode.system,
  );
  @override
  final ValueNotifier<Locale> localeNotifier = ValueNotifier(
    const Locale('vi'),
  );
  @override
  final ValueNotifier<bool> useDynamicColorNotifier = ValueNotifier(false);
  @override
  final ValueNotifier<Color> customPrimaryColorNotifier = ValueNotifier(
    const Color(0xFF1DB954),
  );
  @override
  final ValueNotifier<Color?> dynamicPrimaryColorNotifier = ValueNotifier(null);
  @override
  final ValueNotifier<bool> useNativeWindowEffectNotifier = ValueNotifier(true);
  @override
  final ValueNotifier<double> windowOpacityNotifier = ValueNotifier(0.9);
  @override
  final ValueNotifier<bool> minimizeToTrayNotifier = ValueNotifier(true);
  @override
  final ValueNotifier<bool> autoHidePlayerBarNotifier = ValueNotifier(true);
  @override
  final ValueNotifier<bool> showLyricsInMiniPlayerNotifier = ValueNotifier(
    true,
  );

  // ─── Playback Settings ─────────────────────────────────────────────
  @override
  final ValueNotifier<bool> mediaKeyEnabledNotifier = ValueNotifier(true);
  @override
  final ValueNotifier<Duration?> sleepTimerDurationNotifier = ValueNotifier(
    null,
  );
  final ValueNotifier<bool> stopAtEndOfSongNotifier = ValueNotifier(false);
  final ValueNotifier<double> volumeNotifier = ValueNotifier(1);

  // ─── Sleep Timer v2 Settings ───────────────────────────────────────
  @override
  final ValueNotifier<int> sleepTimerDurationPresetNotifier = ValueNotifier(0);
  @override
  final ValueNotifier<Duration> sleepTimerCustomDurationNotifier =
      ValueNotifier(const Duration(minutes: 30));
  @override
  final ValueNotifier<int> sleepTimerFadeOutDurationNotifier = ValueNotifier(
    30,
  );
  @override
  final ValueNotifier<bool> sleepTimerStopAtEndOfSongNotifier = ValueNotifier(
    false,
  );
  @override
  final ValueNotifier<bool> sleepTimerFadeOutEnabledNotifier = ValueNotifier(
    true,
  );

  // ─── Hotkey Settings ───────────────────────────────────────────────
  @override
  final ValueNotifier<Map<String, String>> customHotkeysNotifier =
      ValueNotifier({});

  // ─── Window State ──────────────────────────────────────────────────
  @override
  Offset? get savedWindowPosition => const Offset(100, 100);
  set savedWindowPosition(final Offset? value) {}
  @override
  Size? get savedWindowSize => const Size(1000, 700);
  set savedWindowSize(final Size? value) {}

  // ─── State ─────────────────────────────────────────────────────────

  @override
  Future<void> init() async {}

  Future<void> resetToDefaults() async {
    eqBandsNotifier.value = List.filled(10, 0);
    eqBassNotifier.value = 0;
    crossfadeDurationNotifier.value = 3.0;
    crossfadeCurveNotifier.value = 0;
    normalizationLevelNotifier.value = -14.0;
    normalizationEnabledNotifier.value = false;
    pitchShiftNotifier.value = 1.0;
    reverbMixNotifier.value = 0.0;
    compressionRatioNotifier.value = 1.0;
    visualizerEnabledNotifier.value = true;
    lyricsFontSizeNotifier.value = 16.0;
    themeModeNotifier.value = ThemeMode.system;
    localeNotifier.value = const Locale('vi');
    useDynamicColorNotifier.value = false;
    customPrimaryColorNotifier.value = const Color(0xFF1DB954);
    dynamicPrimaryColorNotifier.value = null;
    useNativeWindowEffectNotifier.value = true;
    windowOpacityNotifier.value = 0.9;
    minimizeToTrayNotifier.value = true;
    autoHidePlayerBarNotifier.value = true;
    showLyricsInMiniPlayerNotifier.value = true;
    mediaKeyEnabledNotifier.value = true;
    sleepTimerDurationNotifier.value = null;
    stopAtEndOfSongNotifier.value = false;
    volumeNotifier.value = 1.0;
    customHotkeysNotifier.value = {};
    sleepTimerDurationPresetNotifier.value = 0;
    sleepTimerCustomDurationNotifier.value = const Duration(minutes: 30);
    sleepTimerFadeOutDurationNotifier.value = 30;
    sleepTimerStopAtEndOfSongNotifier.value = false;
    sleepTimerFadeOutEnabledNotifier.value = true;
  }

  @override
  void dispose() {
    eqBandsNotifier.dispose();
    eqBassNotifier.dispose();
    crossfadeDurationNotifier.dispose();
    crossfadeCurveNotifier.dispose();
    normalizationLevelNotifier.dispose();
    normalizationEnabledNotifier.dispose();
    pitchShiftNotifier.dispose();
    reverbMixNotifier.dispose();
    compressionRatioNotifier.dispose();
    visualizerEnabledNotifier.dispose();
    lyricsFontSizeNotifier.dispose();
    themeModeNotifier.dispose();
    localeNotifier.dispose();
    useDynamicColorNotifier.dispose();
    customPrimaryColorNotifier.dispose();
    dynamicPrimaryColorNotifier.dispose();
    useNativeWindowEffectNotifier.dispose();
    windowOpacityNotifier.dispose();
    minimizeToTrayNotifier.dispose();
    autoHidePlayerBarNotifier.dispose();
    showLyricsInMiniPlayerNotifier.dispose();
    mediaKeyEnabledNotifier.dispose();
    sleepTimerDurationNotifier.dispose();
    stopAtEndOfSongNotifier.dispose();
    volumeNotifier.dispose();
    customHotkeysNotifier.dispose();
    sleepTimerDurationPresetNotifier.dispose();
    sleepTimerCustomDurationNotifier.dispose();
    sleepTimerFadeOutDurationNotifier.dispose();
    sleepTimerStopAtEndOfSongNotifier.dispose();
    sleepTimerFadeOutEnabledNotifier.dispose();
  }

  @override
  List<ValueNotifier<dynamic>> get allNotifiers => <ValueNotifier<dynamic>>[
    themeModeNotifier,
    enableBlurNotifier,
    blurLevelNotifier,
    isMiniPlayerNotifier,
    useNativeWindowEffectNotifier,
    windowOpacityNotifier,
    isGridViewNotifier,
    customBackgroundImageNotifier,
    visualizerShapeNotifier,
    minimizeToTrayNotifier,
    autoHidePlayerBarNotifier,
    visualizerEnabledNotifier,
    useDynamicColorNotifier,
    sidebarCollapsedNotifier,
    desktopLyricsEnabledNotifier,
    desktopLyricsFontSizeNotifier,
    desktopLyricsOpacityNotifier,
    desktopLyricsClickThroughNotifier,
    sensitivityNotifier,
    showLyricsInMiniPlayerNotifier,
    customPrimaryColorNotifier,
    dynamicPrimaryColorNotifier,
    eqBandsNotifier,
    eqBassNotifier,
    crossfadeDurationNotifier,
    crossfadeCurveNotifier,
    normalizationLevelNotifier,
    normalizationEnabledNotifier,
    pitchShiftNotifier,
    reverbMixNotifier,
    compressionRatioNotifier,
    sortModeNotifier,
    sortAscendingNotifier,
    customHotkeysNotifier,
    mediaKeyEnabledNotifier,
    sleepTimerDurationNotifier,
    sleepTimerDurationPresetNotifier,
    sleepTimerCustomDurationNotifier,
    sleepTimerFadeOutDurationNotifier,
    sleepTimerStopAtEndOfSongNotifier,
    sleepTimerFadeOutEnabledNotifier,
  ];

  @override
  dynamic noSuchMethod(final Invocation invocation) =>
      super.noSuchMethod(invocation);
}
