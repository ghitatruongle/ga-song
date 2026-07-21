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
    @Default(ThemeMode.system) ThemeMode themeMode,
    @Default(true) bool enableBlur,
    @Default(30.0) double blurLevel,
    @Default(false) bool useNativeWindowEffect,
    @Default(0.7) double windowOpacity,
    @Default(true) bool useDynamicColor,
    @Default(Color(0xFF1DB954)) Color customPrimaryColor,
    Color? dynamicPrimaryColor,

    // ─── Window & Layout ────────────────────────────────────────────
    @Default(false) bool isMiniPlayer,
    @Default(false) bool isGridView,
    @Default(false) bool sidebarCollapsed,
    @Default(0) int currentTabIndex,

    // ─── Equalizer ──────────────────────────────────────────────────
    @Default([0.0, 0.0, 0.0, 0.0, 0.0]) List<double> eqBands,
    @Default(0) int eqBassLevel,
    @Default('Normal') String eqPreset,

    // ─── Audio Effects ──────────────────────────────────────────────
    @Default(3.0) double crossfadeDuration,
    @Default(0) int crossfadeCurve, // 0=linear, 1=exponential, 2=sCurve
    @Default(-12.0) double normalizationLevel,
    @Default(false) bool normalizationEnabled,
    @Default(1.0) double pitchShift,
    @Default(0.0) double reverbMix,
    @Default(0.5) double reverbRoomSize,
    @Default(0.5) double reverbDamp,
    @Default(1.0) double compressionRatio,
    @Default(-6.0) double compThreshold,
    @Default(10.0) double compAttack,
    @Default(100.0) double compRelease,
    @Default(2.0) double compKneeWidth,
    @Default(0.0) double compMakeupGain,

    // ─── Sort & Filter ──────────────────────────────────────────────
    @Default(0) int sortMode,
    @Default(true) bool sortAscending,

    // ─── Desktop Lyrics ─────────────────────────────────────────────
    @Default(false) bool desktopLyricsEnabled,
    @Default(24.0) double desktopLyricsFontSize,
    @Default(0.9) double desktopLyricsOpacity,
    @Default(false) bool desktopLyricsClickThrough,

    // ─── Visualizer ─────────────────────────────────────────────────
    @Default(true) bool visualizerEnabled,
    @Default(0) int visualizerShape,

    // ─── Hotkeys & Media ────────────────────────────────────────────
    @Default({}) Map<String, String> customHotkeys,
    @Default(true) bool mediaKeyEnabled,

    // ─── Feedback (Phase 4) ──────────────────────────────────────────
    @Default(false) bool soundFeedbackEnabled,

    // ─── Other ──────────────────────────────────────────────────────
    @Default(true) bool minimizeToTray,
    @Default(1.0) double sensitivity,
    String? customBackgroundImage,
  }) = _SettingsState;
}
