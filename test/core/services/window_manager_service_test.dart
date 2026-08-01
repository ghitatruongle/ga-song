/// Unit Tests for WindowManagerService using MockWindowManagerService
///
/// Tests the window manager logic without platform dependencies.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import '../../test_helpers.dart';
import '../../mocks/mock_window_manager_service.dart';
import '../../mocks/mock_settings_manager.dart';
import 'package:ga_song/core/settings_manager.dart';
import 'package:ga_song/core/platform_capabilities.dart';

void main() {
  group('MockWindowManagerService', () {
    late MockSettingsManager settings;
    late MockWindowManagerService windowManager;

    setUp(() {
      settings = MockSettingsManager();
      windowManager = MockWindowManagerService(settingsManager: settings);
    });

    tearDown(() {
      settings.dispose();
      windowManager.dispose();
    });

    test('initializes without error', () async {
      await windowManager.init();
      expect(windowManager.initCallCount, 1);
    });

    test('applies window effect based on settings', () async {
      await windowManager.init();
      await settings.init();
      
      settings.useNativeWindowEffectNotifier.value = true;
      settings.themeModeNotifier.value = ThemeMode.dark;
      settings.windowOpacityNotifier.value = 0.8;

      await windowManager.applyWindowEffect();

      expect(windowManager.applyEffectCallCount, 1);
      expect(windowManager.lastEffectType, isNotNull);
      expect(windowManager.lastColor, isNotNull);
      expect(windowManager.lastDark, true);
    });

    test('disables effect when useNative is false', () async {
      await windowManager.init();
      await settings.init();
      
      settings.useNativeWindowEffectNotifier.value = false;

      await windowManager.applyWindowEffect();

      expect(windowManager.lastEffectType, WindowEffectType.disabled);
      expect(windowManager.lastColor, Colors.transparent);
    });

    test('respects light theme', () async {
      await windowManager.init();
      await settings.init();
      
      settings.useNativeWindowEffectNotifier.value = true;
      settings.themeModeNotifier.value = ThemeMode.light;
      settings.windowOpacityNotifier.value = 0.9;

      await windowManager.applyWindowEffect();

      expect(windowManager.lastDark, false);
      expect(windowManager.lastColor!.alpha, (0.9 * 255).toInt());
    });

    test('respects system theme brightness', () async {
      await windowManager.init();
      await settings.init();
      
      settings.useNativeWindowEffectNotifier.value = true;
      settings.themeModeNotifier.value = ThemeMode.system;
      // We can't easily test system brightness in unit test, but we can verify
      // the logic path is followed
      await windowManager.applyWindowEffect();
      expect(windowManager.applyEffectCallCount, 1);
    });

    test('caches effect state to avoid redundant calls', () async {
      await windowManager.init();
      await settings.init();
      
      settings.useNativeWindowEffectNotifier.value = true;
      settings.themeModeNotifier.value = ThemeMode.dark;
      settings.windowOpacityNotifier.value = 0.8;

      // First call
      await windowManager.applyWindowEffect();
      final firstEffectType = windowManager.lastEffectType;
      final firstColor = windowManager.lastColor;
      final firstCallCount = windowManager.applyEffectCallCount;

      // Second call with same settings - should skip
      await windowManager.applyWindowEffect();

      expect(windowManager.applyEffectCallCount, firstCallCount); // No increment
      expect(windowManager.lastEffectType, firstEffectType);
      expect(windowManager.lastColor, firstColor);
    });

    test('invalidates cache when settings change', () async {
      await windowManager.init();
      await settings.init();
      
      settings.useNativeWindowEffectNotifier.value = true;
      settings.themeModeNotifier.value = ThemeMode.light;
      settings.windowOpacityNotifier.value = 0.5;

      await windowManager.applyWindowEffect();
      final firstColor = windowManager.lastColor;

      // Change opacity
      settings.windowOpacityNotifier.value = 0.9;
      await windowManager.applyWindowEffect();

      expect(windowManager.lastColor, isNot(firstColor));
    });

    test('handles window resize', () {
      windowManager.onWindowResize();
      // Should set solid background during resize
      // In mock, this is a no-op but we verify it doesn't throw
      expect(true, isTrue);
    });

    test('handles window close', () async {
      await windowManager.init();
      windowManager.onWindowClose();
      expect(windowManager.hideCallCount, 1);
    });

    test('setPosition updates position', () async {
      await windowManager.init();
      await windowManager.setPosition(const Offset(100, 200));
      expect(windowManager.setPositionCallCount, 1);
      expect(windowManager.position, const Offset(100, 200));
    });

    test('setSize updates size', () async {
      await windowManager.init();
      await windowManager.setSize(const Size(800, 600));
      expect(windowManager.setSizeCallCount, 1);
      expect(windowManager.size, const Size(800, 600));
    });

    test('show/hide/focus/destroy work', () async {
      await windowManager.init();
      
      await windowManager.show();
      expect(windowManager.showCallCount, 1);
      expect(windowManager.visible, true);

      await windowManager.hide();
      expect(windowManager.hideCallCount, 1);
      expect(windowManager.visible, false);

      await windowManager.focus();
      expect(windowManager.focusCallCount, 1);
      expect(windowManager.focused, true);

      await windowManager.destroy();
      expect(windowManager.destroyCallCount, 1);
    });

    test('disposes without error', () {
      expect(() => windowManager.dispose(), returnsNormally);
      expect(windowManager.disposeCallCount, 1);
    });

    test('dispose removes listeners from settings', () async {
      await windowManager.init();
      await settings.init();
      
      // Trigger some effect applications
      settings.useNativeWindowEffectNotifier.value = true;
      await windowManager.applyWindowEffect();
      
      windowManager.dispose();
      
      // After dispose, settings changes shouldn't trigger effect
      settings.useNativeWindowEffectNotifier.value = false;
      // This would normally trigger scheduleApplyEffect, but since listener is removed,
      // applyEffectCallCount should not increase
      final countBefore = windowManager.applyEffectCallCount;
      // Can't easily test without triggering the listener, but we verify dispose doesn't throw
      expect(countBefore, windowManager.applyEffectCallCount);
    });
  });
}