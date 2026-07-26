import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ga_song/core/settings/settings_state.dart';

void main() {
  group('SettingsState', () {
    test('creates with default values', () {
      const state = SettingsState();

      expect(state.themeMode, ThemeMode.system);
      expect(state.enableBlur, true);
      expect(state.blurLevel, 30.0);
      expect(state.useDynamicColor, true);
      expect(state.customPrimaryColor, const Color(0xFF1DB954));
      expect(state.isMiniPlayer, false);
      expect(state.isGridView, false);
      expect(state.sidebarCollapsed, false);
      expect(state.currentTabIndex, 0);
      expect(state.visualizerEnabled, true);
      expect(state.visualizerShape, 0);
      expect(state.minimizeToTray, true);
      expect(state.sensitivity, 1.0);
      expect(state.mediaKeyEnabled, true);
      expect(state.customBackgroundImage, null);
    });

    test('copyWith updates specific fields', () {
      const state = SettingsState();
      final modified = state.copyWith(
        themeMode: ThemeMode.dark,
        enableBlur: false,
        blurLevel: 50.0,
        isMiniPlayer: true,
      );

      expect(modified.themeMode, ThemeMode.dark);
      expect(modified.enableBlur, false);
      expect(modified.blurLevel, 50.0);
      expect(modified.isMiniPlayer, true);

      // Unchanged fields remain
      expect(modified.useDynamicColor, true);
      expect(modified.customPrimaryColor, const Color(0xFF1DB954));
    });

    test('supports == and hashCode', () {
      const state1 = SettingsState();
      const state2 = SettingsState();

      expect(state1, equals(state2));
      expect(state1.hashCode, equals(state2.hashCode));
    });

    test('different values are not equal', () {
      const state1 = SettingsState();
      final state2 = state1.copyWith(themeMode: ThemeMode.dark);

      expect(state1, isNot(equals(state2)));
    });

    test('value equality works with colors', () {
      const state1 = SettingsState(customPrimaryColor: Color(0xFF1DB954));
      const state2 = SettingsState(customPrimaryColor: Color(0xFF1DB954));

      expect(state1, equals(state2));
    });

    test('value equality works with lists', () {
      const state1 = SettingsState(eqBands: [0.0, 0.5, 0.0, -0.5, 0.0]);
      const state2 = SettingsState(eqBands: [0.0, 0.5, 0.0, -0.5, 0.0]);

      expect(state1, equals(state2));
    });

    test('toString contains state values', () {
      const state = SettingsState();
      final str = state.toString();

      expect(str, contains('SettingsState'));
      expect(str, contains('themeMode'));
      expect(str, contains('enableBlur'));
    });

    test('copyWith with multiple fields', () {
      const state = SettingsState();
      final modified = state.copyWith(
        themeMode: ThemeMode.dark,
        enableBlur: false,
        blurLevel: 50.0,
        useNativeWindowEffect: true,
        windowOpacity: 0.5,
        isGridView: true,
        sidebarCollapsed: true,
        visualizerEnabled: false,
      );

      expect(modified.themeMode, ThemeMode.dark);
      expect(modified.enableBlur, false);
      expect(modified.blurLevel, 50.0);
      expect(modified.useNativeWindowEffect, true);
      expect(modified.windowOpacity, 0.5);
      expect(modified.isGridView, true);
      expect(modified.sidebarCollapsed, true);
      expect(modified.visualizerEnabled, false);
    });
  });
}
