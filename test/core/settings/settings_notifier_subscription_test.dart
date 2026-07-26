import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ga_song/core/settings_manager.dart';
import 'package:ga_song/providers/service_providers.dart';

void main() {
  group('SettingsNotifier subscription behavior', () {
    late ProviderContainer container;
    late SettingsManager manager;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      manager = SettingsManager();
      await manager.init();
      container = ProviderContainer(
        overrides: [settingsManagerProvider.overrideWithValue(manager)],
      );
    });

    tearDown(() {
      container.dispose();
      manager.dispose();
    });

    test('initial state mirrors current manager values', () {
      final state = container.read(settingsNotifierProvider);
      expect(state.themeMode, manager.themeModeNotifier.value);
      expect(state.eqBands, equals(manager.eqBandsNotifier.value));
      expect(state.customHotkeys, isA<Map<String, String>>());
    });

    test('underlying notifier change triggers state rebuild', () async {
      final initialState = container.read(settingsNotifierProvider);
      expect(initialState.blurLevel, 30.0);

      // Trigger a change directly via the manager's notifier (bypass setter)
      manager.blurLevelNotifier.value = 77.0;

      // State rebuild is debounced by 16ms — wait for it to settle.
      await Future<void>.delayed(const Duration(milliseconds: 20));

      final newState = container.read(settingsNotifierProvider);
      expect(newState.blurLevel, 77.0);
      expect(
        identical(initialState, newState),
        isFalse,
        reason: 'state object should be a fresh instance after rebuild',
      );
    });

    test('setter call eventually reflects in state', () async {
      await container
          .read(settingsNotifierProvider.notifier)
          .setBlurLevel(42.0);
      // Debounced refresh — wait for it to settle.
      await Future<void>.delayed(const Duration(milliseconds: 20));
      final state = container.read(settingsNotifierProvider);
      expect(state.blurLevel, 42.0);
      expect(manager.blurLevelNotifier.value, 42.0);
    });

    test('multiple underlying notifier changes rebuild sequentially', () async {
      container.read(settingsNotifierProvider);
      manager.blurLevelNotifier.value = 10.0;
      manager.themeModeNotifier.value = ThemeMode.dark;
      manager.sensitivityNotifier.value = 2.0;

      // Debounced refresh coalesces all three changes into one rebuild.
      await Future<void>.delayed(const Duration(milliseconds: 20));

      final state = container.read(settingsNotifierProvider);
      expect(state.blurLevel, 10.0);
      expect(state.themeMode, ThemeMode.dark);
      expect(state.sensitivity, 2.0);
    });

    test('disposal removes subscriptions (no callback after dispose)', () {
      // Subscribe via initial read
      container.read(settingsNotifierProvider);

      // Dispose the container (Riverpod should clean up listeners)
      container.dispose();

      // Mutating underlying notifier after dispose must NOT throw — the
      // listener should have been removed via the subscription disposal.
      expect(() => manager.blurLevelNotifier.value = 99.0, returnsNormally);
    });
  });
}
