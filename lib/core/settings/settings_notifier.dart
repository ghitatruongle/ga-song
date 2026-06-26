import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'settings_state.dart';
import '../settings_manager.dart';
import '../../providers/service_providers.dart';

/// Riverpod notifier for app settings.
///
/// Wraps the existing [SettingsManager] to provide a clean Riverpod interface
/// while maintaining backward compatibility during migration.
class SettingsNotifier extends Notifier<SettingsState> {
  late SettingsManager _manager;

  @override
  SettingsState build() {
    _manager = ref.watch(settingsManagerProvider);
    return _stateFromManager(_manager);
  }

  /// Creates a [SettingsState] from the current [SettingsManager] values.
  SettingsState _stateFromManager(SettingsManager m) {
    return SettingsState(
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

      // Visualizer
      visualizerEnabled: m.visualizerEnabledNotifier.value,
      visualizerShape: m.visualizerShapeNotifier.value,

      // Hotkeys & Media
      customHotkeys: Map<String, String>.from(m.customHotkeysNotifier.value),
      mediaKeyEnabled: m.mediaKeyEnabledNotifier.value,

      // Other
      minimizeToTray: m.minimizeToTrayNotifier.value,
      sensitivity: m.sensitivityNotifier.value,
      customBackgroundImage: m.customBackgroundImageNotifier.value,
    );
  }

  /// Refreshes the state from the underlying [SettingsManager].
  void refresh() {
    state = _stateFromManager(_manager);
  }

  // ─── Theme Methods ──────────────────────────────────────────────────

  Future<void> setThemeMode(ThemeMode mode) async {
    await _manager.setThemeMode(mode);
    state = state.copyWith(themeMode: mode);
  }

  Future<void> setEnableBlur(bool enable) async {
    await _manager.setEnableBlur(enable);
    state = state.copyWith(enableBlur: enable);
  }

  Future<void> setBlurLevel(double level) async {
    final clamped = level.clamp(0.0, 100.0);
    await _manager.setBlurLevel(clamped);
    state = state.copyWith(blurLevel: clamped);
  }

  Future<void> setUseNativeWindowEffect(bool enable) async {
    await _manager.setUseNativeWindowEffect(enable);
    state = state.copyWith(useNativeWindowEffect: enable);
  }

  Future<void> setWindowOpacity(double opacity) async {
    final clamped = opacity.clamp(0.1, 1.0);
    await _manager.setWindowOpacity(clamped);
    state = state.copyWith(windowOpacity: clamped);
  }

  Future<void> setUseDynamicColor(bool useDynamic) async {
    await _manager.setUseDynamicColor(useDynamic);
    state = state.copyWith(useDynamicColor: useDynamic);
  }

  Future<void> setCustomPrimaryColor(Color color) async {
    await _manager.setCustomPrimaryColor(color);
    state = state.copyWith(customPrimaryColor: color);
  }

  // ─── Window & Layout Methods ────────────────────────────────────────

  void setIsMiniPlayer(bool isMini) {
    _manager.setIsMiniPlayer(isMini);
    state = state.copyWith(isMiniPlayer: isMini);
  }

  Future<void> setIsGridView(bool isGrid) async {
    await _manager.setIsGridView(isGrid);
    state = state.copyWith(isGridView: isGrid);
  }

  Future<void> setSidebarCollapsed(bool collapsed) async {
    await _manager.setSidebarCollapsed(collapsed);
    state = state.copyWith(sidebarCollapsed: collapsed);
  }

  void setCurrentTabIndex(int index) {
    _manager.currentTabIndexNotifier.value = index;
    state = state.copyWith(currentTabIndex: index);
  }

  // ─── Equalizer Methods ──────────────────────────────────────────────

  Future<void> setEqBand(int index, double value) async {
    await _manager.setEqBand(index, value);
    final newBands = List<double>.from(state.eqBands);
    newBands[index] = value.clamp(-1.0, 1.0);
    state = state.copyWith(eqBands: newBands);
  }

  Future<void> setEqBass(int level) async {
    await _manager.setEqBass(level);
    state = state.copyWith(eqBassLevel: level.clamp(0, 100));
  }

  Future<void> applyEqPreset(String preset) async {
    await _manager.applyEqPreset(preset);
    state = state.copyWith(
      eqPreset: preset,
      eqBands: List<double>.from(_manager.eqBandsNotifier.value),
      eqBassLevel: _manager.eqBassNotifier.value,
    );
  }

  // ─── Audio Effects Methods ──────────────────────────────────────────

  Future<void> setCrossfadeDuration(double duration) async {
    await _manager.setCrossfadeDuration(duration);
    state = state.copyWith(crossfadeDuration: duration.clamp(0.0, 10.0));
  }

  Future<void> setCrossfadeCurve(int curve) async {
    await _manager.setCrossfadeCurve(curve);
    state = state.copyWith(crossfadeCurve: curve.clamp(0, 2));
  }

  Future<void> setNormalizationLevel(double level) async {
    await _manager.setNormalizationLevel(level);
    state = state.copyWith(normalizationLevel: level.clamp(-24.0, 0.0));
  }

  Future<void> setNormalizationEnabled(bool enabled) async {
    await _manager.setNormalizationEnabled(enabled);
    state = state.copyWith(normalizationEnabled: enabled);
  }

  Future<void> setPitchShift(double pitch) async {
    await _manager.setPitchShift(pitch);
    state = state.copyWith(pitchShift: pitch.clamp(0.5, 2.0));
  }

  Future<void> setReverbMix(double mix) async {
    await _manager.setReverbMix(mix);
    state = state.copyWith(reverbMix: mix.clamp(0.0, 1.0));
  }

  Future<void> setCompressionRatio(double ratio) async {
    await _manager.setCompressionRatio(ratio);
    state = state.copyWith(compressionRatio: ratio.clamp(1.0, 10.0));
  }

  Future<void> setReverbRoomSize(double size) async {
    await _manager.setReverbRoomSize(size);
    state = state.copyWith(reverbRoomSize: size.clamp(0.0, 1.0));
  }

  Future<void> setReverbDamp(double damp) async {
    await _manager.setReverbDamp(damp);
    state = state.copyWith(reverbDamp: damp.clamp(0.0, 1.0));
  }

  Future<void> setCompThreshold(double threshold) async {
    await _manager.setCompThreshold(threshold);
    state = state.copyWith(compThreshold: threshold.clamp(-80.0, 0.0));
  }

  Future<void> setCompAttack(double attack) async {
    await _manager.setCompAttack(attack);
    state = state.copyWith(compAttack: attack.clamp(0.0, 100.0));
  }

  Future<void> setCompRelease(double release) async {
    await _manager.setCompRelease(release);
    state = state.copyWith(compRelease: release.clamp(0.0, 1000.0));
  }

  Future<void> setCompKneeWidth(double knee) async {
    await _manager.setCompKneeWidth(knee);
    state = state.copyWith(compKneeWidth: knee.clamp(0.0, 40.0));
  }

  Future<void> setCompMakeupGain(double gain) async {
    await _manager.setCompMakeupGain(gain);
    state = state.copyWith(compMakeupGain: gain.clamp(-40.0, 40.0));
  }

  // ─── Sort & Filter Methods ──────────────────────────────────────────

  Future<void> setSortMode(int mode) async {
    await _manager.setSortMode(mode);
    state = state.copyWith(sortMode: mode);
  }

  Future<void> setSortAscending(bool ascending) async {
    await _manager.setSortAscending(ascending);
    state = state.copyWith(sortAscending: ascending);
  }

  // ─── Desktop Lyrics Methods ─────────────────────────────────────────

  Future<void> setDesktopLyricsEnabled(bool enabled) async {
    await _manager.setDesktopLyricsEnabled(enabled);
    state = state.copyWith(desktopLyricsEnabled: enabled);
  }

  Future<void> setDesktopLyricsFontSize(double size) async {
    await _manager.setDesktopLyricsFontSize(size);
    state = state.copyWith(desktopLyricsFontSize: size);
  }

  Future<void> setDesktopLyricsOpacity(double opacity) async {
    await _manager.setDesktopLyricsOpacity(opacity);
    state = state.copyWith(desktopLyricsOpacity: opacity);
  }

  Future<void> setDesktopLyricsClickThrough(bool clickThrough) async {
    await _manager.setDesktopLyricsClickThrough(clickThrough);
    state = state.copyWith(desktopLyricsClickThrough: clickThrough);
  }

  // ─── Visualizer Methods ─────────────────────────────────────────────

  Future<void> setVisualizerEnabled(bool enable) async {
    await _manager.setVisualizerEnabled(enable);
    state = state.copyWith(visualizerEnabled: enable);
  }

  Future<void> setVisualizerShape(int shape) async {
    await _manager.setVisualizerShape(shape);
    state = state.copyWith(visualizerShape: shape);
  }

  // ─── Hotkeys & Media Methods ────────────────────────────────────────

  Future<void> setCustomHotkey(String action, String keys) async {
    await _manager.setCustomHotkey(action, keys);
    final newHotkeys = Map<String, String>.from(state.customHotkeys);
    newHotkeys[action] = keys;
    state = state.copyWith(customHotkeys: newHotkeys);
  }

  Future<void> removeCustomHotkey(String action) async {
    await _manager.removeCustomHotkey(action);
    final newHotkeys = Map<String, String>.from(state.customHotkeys);
    newHotkeys.remove(action);
    state = state.copyWith(customHotkeys: newHotkeys);
  }

  Future<void> setMediaKeyEnabled(bool enabled) async {
    await _manager.setMediaKeyEnabled(enabled);
    state = state.copyWith(mediaKeyEnabled: enabled);
  }

  // ─── Other Methods ──────────────────────────────────────────────────

  Future<void> setMinimizeToTray(bool minimize) async {
    await _manager.setMinimizeToTray(minimize);
    state = state.copyWith(minimizeToTray: minimize);
  }

  Future<void> setSensitivity(double value) async {
    final clamped = value.clamp(0.3, 2.5);
    await _manager.setSensitivity(clamped);
    state = state.copyWith(sensitivity: clamped);
  }

  Future<void> setCustomBackgroundImage(String? path) async {
    await _manager.setCustomBackgroundImage(path);
    state = state.copyWith(customBackgroundImage: path);
  }

  // ─── Window State (not part of SettingsState, uses manager directly) ─

  Future<void> setSavedWindowState(Size size, bool isMaximized, bool isFullScreen) async {
    await _manager.setSavedWindowState(size, isMaximized, isFullScreen);
  }

  Future<void> setSavedWindowPosition(Offset position) async {
    await _manager.setSavedWindowPosition(position);
  }
}

/// Provider for the settings notifier.
///
/// This provides a clean Riverpod interface for settings while wrapping
/// the existing [SettingsManager] for backward compatibility.
final settingsNotifierProvider =
    NotifierProvider<SettingsNotifier, SettingsState>(SettingsNotifier.new);
