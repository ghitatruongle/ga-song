/// Mock implementation of [WindowManagerService] for testing.
/// Provides controlled window behavior without platform dependencies.

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ga_song/core/platform_capabilities.dart';
import 'package:ga_song/core/services/window_manager_service.dart';
import 'package:ga_song/core/settings_manager.dart';

class MockWindowManagerService implements WindowManagerService {
  @override
  final SettingsManager? settingsManager;

  bool initialized = false;
  bool disposed = false;

  // Track calls for verification
  int initCallCount = 0;
  int applyEffectCallCount = 0;
  int setPositionCallCount = 0;
  int setSizeCallCount = 0;
  int showCallCount = 0;
  int hideCallCount = 0;
  int focusCallCount = 0;
  int destroyCallCount = 0;
  int disposeCallCount = 0;

  // State
  WindowEffectType? lastEffectType;
  Color? lastColor;
  bool? lastDark;
  Offset? position;
  Size? size;
  bool visible = true;
  bool focused = false;

  MockWindowManagerService({this.settingsManager});

  @override
  Future<void> init() async {
    initCallCount++;
    initialized = true;
  }

  Future<void> applyWindowEffect() async {
    if (settingsManager != null) {
      final useNative = settingsManager!.useNativeWindowEffectNotifier.value;
      final theme = settingsManager!.themeModeNotifier.value;
      final opacity = settingsManager!.windowOpacityNotifier.value;
      final isDark = theme == ThemeMode.dark ||
          (theme == ThemeMode.system &&
              PlatformDispatcher.instance.platformBrightness == Brightness.dark);

      WindowEffectType? effectType;
      Color? bgColor;
      if (useNative) {
        final int alpha = (opacity * 255).toInt();
        bgColor = isDark
            ? Color.fromARGB(alpha, 18, 18, 18)
            : Color.fromARGB(alpha, 245, 245, 245);
        effectType = WindowEffectType.mica; // Default for mock
      } else {
        effectType = WindowEffectType.disabled;
        bgColor = Colors.transparent;
      }

      // Effect state caching — skip if nothing changed
      if (effectType == lastEffectType &&
          bgColor == lastColor &&
          isDark == lastDark) {
        return;
      }

      applyEffectCallCount++;
      lastEffectType = effectType;
      lastColor = bgColor;
      lastDark = isDark;
    }
  }

  void scheduleApplyEffect() {
    applyWindowEffect();
  }

  double _getDpiScale() => 1.0;

  WindowEffectType _getPreferredWindowEffect() => WindowEffectType.mica;

  @override
  void onWindowResize() {
    // Mock implementation
  }

  Future<void> _setSolidBackgroundDuringResize() async {}

  Future<void> _onResizeEnd() async {}

  @override
  void onWindowClose() async {
    if (initialized) {
      hideCallCount++;
      visible = false;
    }
  }

  Future<void> setPosition(Offset position) async {
    setPositionCallCount++;
    this.position = position;
  }

  Future<void> setSize(Size size) async {
    setSizeCallCount++;
    this.size = size;
  }

  Future<void> show() async {
    showCallCount++;
    visible = true;
  }

  Future<void> hide() async {
    hideCallCount++;
    visible = false;
  }

  Future<void> focus() async {
    focusCallCount++;
    focused = true;
  }

  Future<void> destroy() async {
    destroyCallCount++;
    visible = false;
  }

  @override
  void dispose() {
    disposeCallCount++;
    disposed = true;
    initialized = false;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}