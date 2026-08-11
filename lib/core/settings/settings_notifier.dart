import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'settings_state.dart';
import '../settings_manager.dart';
import '../../providers/service_providers.dart';

/// Riverpod notifier for app settings.
///
/// Reacts to underlying [ValueNotifier]s in [SettingsManager]: whenever any
/// setting changes via the manager (or directly via notifier mutations),
/// the [SettingsState] exposed by this notifier is rebuilt automatically.
/// Setters are thin pass-throughs — the manager remains the source of truth
/// for persistence.
class SettingsNotifier extends Notifier<SettingsState> {
  late SettingsManager _manager;
  final List<VoidCallback> _disposers = [];
  Timer? _refreshTimer;

  @override
  SettingsState build() {
    _manager = ref.watch(settingsManagerProvider);
    _subscribeToManager();
    ref.onDispose(_unsubscribeFromManager);
    return _stateFromManager(_manager);
  }

  void _subscribeToManager() {
    // Defensive: clear any prior subscriptions in case build() re-runs
    // (e.g. during hot reload or test reuse). Without this, the same
    // notifier would accumulate N listener registrations over N rebuilds.
    for (final d in _disposers) {
      d();
    }
    _disposers.clear();
    for (final notifier in _manager.allNotifiers) {
      notifier.addListener(_debouncedRefresh);
      _disposers.add(() => notifier.removeListener(_debouncedRefresh));
    }
  }

  void _unsubscribeFromManager() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
    for (final d in _disposers) {
      d();
    }
    _disposers.clear();
  }

  /// Debounced refresh: coalesces rapid-fire notifier changes (e.g. slider
  /// drags that update 45+ listeners per pixel) into a single [SettingsState]
  /// rebuild after 16ms (~1 frame).
  void _debouncedRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer(const Duration(milliseconds: 16), () {
      _refreshTimer = null;
      state = _stateFromManager(_manager);
    });
  }

  /// Rebuilds state from the current [SettingsManager] values.
  /// Called automatically on each underlying notifier change.
  void refresh() {
    state = _stateFromManager(_manager);
  }

  /// Creates a [SettingsState] from the current [SettingsManager] values.
  SettingsState _stateFromManager(final SettingsManager m) => SettingsState(
    // Theme
    themeMode: m.themeModeNotifier.value,
    enableBlur: m.enableBlurNotifier.value,
    blurLevel: m.blurLevelNotifier.value,
    useNativeWindowEffect: m.useNativeWindowEffectNotifier.value,
    windowOpacity: m.windowOpacityNotifier.value,
    useDynamicColor: m.useDynamicColorNotifier.value,
    customPrimaryColor: m.customPrimaryColorNotifier.value,
    dynamicPrimaryColor: m.dynamicPrimaryColorNotifier.value,

    // Window & Layout
    isMiniPlayer: m.isMiniPlayerNotifier.value,
    isGridView: m.isGridViewNotifier.value,
    sidebarCollapsed: m.sidebarCollapsedNotifier.value,
    currentTabIndex: m.currentTabIndexNotifier.value,

    // Equalizer
    eqBands: List<double>.from(m.eqBandsNotifier.value),
    eqBassLevel: m.eqBassNotifier.value,
    eqPreset: m.eqPresetNotifier.value,

    // Audio Effects
    crossfadeDuration: m.crossfadeDurationNotifier.value,
    crossfadeCurve: m.crossfadeCurveNotifier.value,
    normalizationLevel: m.normalizationLevelNotifier.value,
    normalizationEnabled: m.normalizationEnabledNotifier.value,
    pitchShift: m.pitchShiftNotifier.value,
    reverbMix: m.reverbMixNotifier.value,
    reverbRoomSize: m.reverbRoomSizeNotifier.value,
    reverbDamp: m.reverbDampNotifier.value,
    compressionRatio: m.compressionRatioNotifier.value,
    compThreshold: m.compThresholdNotifier.value,
    compAttack: m.compAttackNotifier.value,
    compRelease: m.compReleaseNotifier.value,
    compKneeWidth: m.compKneeWidthNotifier.value,
    compMakeupGain: m.compMakeupGainNotifier.value,

    // Sort & Filter
    sortMode: m.sortModeNotifier.value,
    sortAscending: m.sortAscendingNotifier.value,

    // Desktop Lyrics
    desktopLyricsEnabled: m.desktopLyricsEnabledNotifier.value,
    desktopLyricsFontSize: m.desktopLyricsFontSizeNotifier.value,
    desktopLyricsOpacity: m.desktopLyricsOpacityNotifier.value,
    desktopLyricsClickThrough: m.desktopLyricsClickThroughNotifier.value,

    // In-app Lyric
    lyricFontSize: m.lyricFontSizeNotifier.value,

    // Visualizer
    visualizerEnabled: m.visualizerEnabledNotifier.value,
    visualizerShape: m.visualizerShapeNotifier.value,

    // Hotkeys & Media
    customHotkeys: Map<String, String>.from(m.customHotkeysNotifier.value),
    mediaKeyEnabled: m.mediaKeyEnabledNotifier.value,
    soundFeedbackEnabled: m.soundFeedbackEnabledNotifier.value,

    // Other
    minimizeToTray: m.minimizeToTrayNotifier.value,
    sensitivity: m.sensitivityNotifier.value,
    customBackgroundImage: m.customBackgroundImageNotifier.value,
  );

  // Setters are pass-throughs: the underlying notifier triggers [refresh]
  // via the subscription wired in [build].
  Future<void> setThemeMode(final ThemeMode mode) =>
      _manager.setThemeMode(mode);
  Future<void> setEnableBlur(final bool enable) =>
      _manager.setEnableBlur(enable);
  Future<void> setBlurLevel(final double level) => _manager.setBlurLevel(level);
  Future<void> setUseNativeWindowEffect(final bool enable) =>
      _manager.setUseNativeWindowEffect(enable);
  Future<void> setWindowOpacity(final double opacity) =>
      _manager.setWindowOpacity(opacity);
  Future<void> setUseDynamicColor(final bool useDynamic) =>
      _manager.setUseDynamicColor(useDynamic);
  Future<void> setCustomPrimaryColor(final Color color) =>
      _manager.setCustomPrimaryColor(color);
  void setIsMiniPlayer(final bool isMini) => _manager.setIsMiniPlayer(isMini);
  Future<void> setIsGridView(final bool isGrid) =>
      _manager.setIsGridView(isGrid);
  Future<void> setSidebarCollapsed(final bool collapsed) =>
      _manager.setSidebarCollapsed(collapsed);
  void setCurrentTabIndex(final int index) {
    _manager.currentTabIndexNotifier.value = index;
  }

  Future<void> setEqBand(final int index, final double value) =>
      _manager.setEqBand(index, value);
  Future<void> setEqBass(final int level) => _manager.setEqBass(level);
  Future<void> applyEqPreset(final String preset) =>
      _manager.applyEqPreset(preset);
  Future<void> setCrossfadeDuration(final double duration) =>
      _manager.setCrossfadeDuration(duration);
  Future<void> setCrossfadeCurve(final int curve) =>
      _manager.setCrossfadeCurve(curve);
  Future<void> setNormalizationLevel(final double level) =>
      _manager.setNormalizationLevel(level);
  Future<void> setNormalizationEnabled(final bool enabled) =>
      _manager.setNormalizationEnabled(enabled);
  Future<void> setPitchShift(final double pitch) =>
      _manager.setPitchShift(pitch);
  Future<void> setReverbMix(final double mix) => _manager.setReverbMix(mix);
  Future<void> setCompressionRatio(final double ratio) =>
      _manager.setCompressionRatio(ratio);
  Future<void> setReverbRoomSize(final double size) =>
      _manager.setReverbRoomSize(size);
  Future<void> setReverbDamp(final double damp) => _manager.setReverbDamp(damp);
  Future<void> setCompThreshold(final double threshold) =>
      _manager.setCompThreshold(threshold);
  Future<void> setCompAttack(final double attack) =>
      _manager.setCompAttack(attack);
  Future<void> setCompRelease(final double release) =>
      _manager.setCompRelease(release);
  Future<void> setCompKneeWidth(final double knee) =>
      _manager.setCompKneeWidth(knee);
  Future<void> setCompMakeupGain(final double gain) =>
      _manager.setCompMakeupGain(gain);
  Future<void> setSortMode(final int mode) => _manager.setSortMode(mode);
  Future<void> setSortAscending(final bool ascending) =>
      _manager.setSortAscending(ascending);
  Future<void> setDesktopLyricsEnabled(final bool enabled) =>
      _manager.setDesktopLyricsEnabled(enabled);
  Future<void> setDesktopLyricsFontSize(final double size) =>
      _manager.setDesktopLyricsFontSize(size);
  Future<void> setDesktopLyricsOpacity(final double opacity) =>
      _manager.setDesktopLyricsOpacity(opacity);
  Future<void> setDesktopLyricsClickThrough(final bool clickThrough) =>
      _manager.setDesktopLyricsClickThrough(clickThrough);
  Future<void> setVisualizerEnabled(final bool enable) =>
      _manager.setVisualizerEnabled(enable);
  Future<void> setVisualizerShape(final int shape) =>
      _manager.setVisualizerShape(shape);
  Future<void> setCustomHotkey(final String action, final String keys) =>
      _manager.setCustomHotkey(action, keys);
  Future<void> removeCustomHotkey(final String action) =>
      _manager.removeCustomHotkey(action);
  Future<void> setMediaKeyEnabled(final bool enabled) =>
      _manager.setMediaKeyEnabled(enabled);
  Future<void> setSoundFeedbackEnabled(final bool enabled) =>
      _manager.setSoundFeedbackEnabled(enabled);
  Future<void> setMinimizeToTray(final bool minimize) =>
      _manager.setMinimizeToTray(minimize);
  Future<void> setSensitivity(final double value) =>
      _manager.setSensitivity(value);
  Future<void> setLyricFontSize(final double scale) =>
      _manager.setLyricFontSize(scale);
  Future<void> setCustomBackgroundImage(final String? path) =>
      _manager.setCustomBackgroundImage(path);

  // ─── Window State (legacy setters on manager directly) ───────────
  Future<void> setSavedWindowState(
    final Size size,
    final bool isMaximized,
    final bool isFullScreen,
  ) => _manager.setSavedWindowState(size, isMaximized, isFullScreen);
  Future<void> setSavedWindowPosition(final Offset position) =>
      _manager.setSavedWindowPosition(position);
}

/// Provider for the settings notifier.
final settingsNotifierProvider =
    NotifierProvider<SettingsNotifier, SettingsState>(SettingsNotifier.new);
