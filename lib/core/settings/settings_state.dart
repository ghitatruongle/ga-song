import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'settings_state.freezed.dart';

/// Immutable settings state using Freezed.
///
/// This replaces the 40+ ValueNotifiers in [SettingsManager] with a single
/// immutable state object that integrates cleanly with Riverpod.
@freezed
class SettingsState with _$SettingsState {
  const factory SettingsState({
    // ─── Theme ──────────────────────────────────────────────────────
    @Default(ThemeMode.system) final ThemeMode themeMode,
    @Default(true) final bool enableBlur,
    @Default(30.0) final double blurLevel,
    @Default(false) final bool useNativeWindowEffect,
    @Default(0.7) final double windowOpacity,
    @Default(true) final bool useDynamicColor,
    @Default(Color(0xFF1DB954)) final Color customPrimaryColor,
    final Color? dynamicPrimaryColor,

    // ─── Window & Layout ────────────────────────────────────────────
    @Default(false) final bool isMiniPlayer,
    @Default(false) final bool isGridView,
    @Default(false) final bool sidebarCollapsed,
    @Default(0) final int currentTabIndex,

    // ─── Equalizer ──────────────────────────────────────────────────
    @Default([0.0, 0.0, 0.0, 0.0, 0.0]) final List<double> eqBands,
    @Default(0) final int eqBassLevel,
    @Default('Normal') final String eqPreset,

    // ─── Audio Effects ──────────────────────────────────────────────
    @Default(3.0) final double crossfadeDuration,
    @Default(0) final int crossfadeCurve, // 0=linear, 1=exponential, 2=sCurve
    @Default(-12.0) final double normalizationLevel,
    @Default(false) final bool normalizationEnabled,
    @Default(1.0) final double pitchShift,
    @Default(0.0) final double reverbMix,
    @Default(0.5) final double reverbRoomSize,
    @Default(0.5) final double reverbDamp,
    @Default(1.0) final double compressionRatio,
    @Default(-6.0) final double compThreshold,
    @Default(10.0) final double compAttack,
    @Default(100.0) final double compRelease,
    @Default(2.0) final double compKneeWidth,
    @Default(0.0) final double compMakeupGain,

    // ─── Sort & Filter ──────────────────────────────────────────────
    @Default(0) final int sortMode,
    @Default(true) final bool sortAscending,

    // ─── Desktop Lyrics ─────────────────────────────────────────────
    @Default(false) final bool desktopLyricsEnabled,
    @Default(24.0) final double desktopLyricsFontSize,
    @Default(0.9) final double desktopLyricsOpacity,
    @Default(false) final bool desktopLyricsClickThrough,

    // ─── In-app Lyric ──────────────────────────────────────────────
    @Default(1.0) final double lyricFontSize,

    // ─── Visualizer ─────────────────────────────────────────────────
    @Default(true) final bool visualizerEnabled,
    @Default(0) final int visualizerShape,

    // ─── Hotkeys & Media ────────────────────────────────────────────
    @Default({}) final Map<String, String> customHotkeys,
    @Default(true) final bool mediaKeyEnabled,

    // ─── Feedback (Phase 4) ──────────────────────────────────────────
    @Default(false) final bool soundFeedbackEnabled,

    // ─── Other ──────────────────────────────────────────────────────
    @Default(true) final bool minimizeToTray,
    @Default(1.0) final double sensitivity,
    final String? customBackgroundImage,
  }) = _SettingsState;
}
