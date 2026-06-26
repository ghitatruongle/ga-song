import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart';
import '../settings_manager.dart';
import '../platform_capabilities.dart';

/// Converts [WindowEffectType] (platform-caps enum) to [WindowEffect] (flutter_acrylic).
WindowEffect _toWindowEffect(WindowEffectType type) {
  switch (type) {
    case WindowEffectType.disabled:
      return WindowEffect.disabled;
    case WindowEffectType.solid:
      return WindowEffect.solid;
    case WindowEffectType.transparent:
      return WindowEffect.transparent;
    case WindowEffectType.acrylic:
      return WindowEffect.acrylic;
    case WindowEffectType.mica:
      return WindowEffect.mica;
    case WindowEffectType.tabbed:
      return WindowEffect.tabbed;
    case WindowEffectType.titlebar:
      return WindowEffect.titlebar;
    case WindowEffectType.sidebar:
      return WindowEffect.sidebar;
    case WindowEffectType.hudWindow:
      return WindowEffect.hudWindow;
  }
}

class WindowManagerService with WindowListener {
  WindowManagerService({SettingsManager? settingsManager})
      : _settings = settingsManager;

  final SettingsManager? _settings;
  // ─── Debounce & resize state ──────────────────────────────────────────────

  Timer? _effectDebounce;
  Timer? _resizeDebounce;
  bool _isResizing = false;

  // ─── Effect state cache — avoids redundant DWM calls ─────────────────────

  WindowEffectType? _cachedEffectType;
  Color? _cachedColor;
  bool? _cachedDark;

  // ─── Init ────────────────────────────────────────────────────────────────

  Future<void> init() async {
    if (kIsWeb ||
        (!kIsWeb &&
            !(defaultTargetPlatform == TargetPlatform.windows ||
                defaultTargetPlatform == TargetPlatform.linux ||
                defaultTargetPlatform == TargetPlatform.macOS))) {
      return;
    }

    try {
      await Window.initialize();
      await windowManager.ensureInitialized();

      const windowOptions = WindowOptions(
        size: Size(1000, 700),
        minimumSize: Size(800, 600),
        center: true,
        backgroundColor: Colors.transparent,
        skipTaskbar: false,
        titleBarStyle: TitleBarStyle.hidden,
      );

      windowManager.waitUntilReadyToShow(windowOptions, () async {
        if (!kDebugMode) {
          try {
            await windowManager.setPreventClose(true);
          } catch (e) {
            debugPrint(
                'Wayland/Linux fallback: setPreventClose not supported. $e');
          }
        }

        // Restore previous window position if available
        final savedPosition = _settings?.savedWindowPosition;
        if (savedPosition != null) {
          try {
            await windowManager.setPosition(savedPosition);
          } catch (e) {
            debugPrint('Failed to restore window position: $e');
          }
        }

        // Restore the saved window size
        final savedSize = _settings?.savedWindowSize;
        if (savedSize != null) {
          try {
            await windowManager.setSize(savedSize);
          } catch (e) {
            debugPrint('Failed to restore window size: $e');
          }
        }

        try {
          await windowManager.show();
          await windowManager.focus();
        } catch (e) {
          debugPrint('Failed to show/focus window: $e');
        }

        _applyWindowEffect();
      });
    } catch (e) {
      debugPrint(
          'Window manager initialization failed (possible Wayland unsupported feature): $e');
    }

    // Always listen to window events for resize handling
    windowManager.addListener(this);

    // Subscribe to settings changes — debounced to avoid flicker
    _settings
        ?.useNativeWindowEffectNotifier
        .addListener(_scheduleApplyEffect);
    _settings
        ?.windowOpacityNotifier
        .addListener(_scheduleApplyEffect);
    _settings
        ?.themeModeNotifier
        .addListener(_scheduleApplyEffect);
  }

  // ─── Debounced effect application ────────────────────────────────────────

  /// Schedules [Window.setEffect] with a 100ms debounce.
  /// Prevents flicker when multiple settings change in rapid succession
  /// (e.g., dragging opacity slider, toggling theme + native effect at once).
  void _scheduleApplyEffect() {
    _effectDebounce?.cancel();
    _effectDebounce = Timer(const Duration(milliseconds: 100), () {
      _applyWindowEffect();
    });
  }

  // ─── Core effect application with state caching ──────────────────────────

  Future<void> _applyWindowEffect() async {
    final settings = _settings;
    if (settings == null) return;
    final useNative = settings.useNativeWindowEffectNotifier.value;
    final theme = settings.themeModeNotifier.value;
    final opacity = settings.windowOpacityNotifier.value;
    final isDark = theme == ThemeMode.dark ||
        (theme == ThemeMode.system &&
            PlatformDispatcher.instance.platformBrightness == Brightness.dark);

    final effectType = useNative
        ? PlatformCapabilities.instance.preferredWindowEffect
        : WindowEffectType.disabled;

    // Compute background color
    Color bgColor;
    if (useNative) {
      final int alpha = (opacity * 255).toInt();
      bgColor = isDark
          ? Color.fromARGB(alpha, 18, 18, 18)
          : Color.fromARGB(alpha, 245, 245, 245);
    } else {
      bgColor = Colors.transparent;
    }

    // Effect state caching — skip if nothing changed
    if (effectType == _cachedEffectType &&
        bgColor == _cachedColor &&
        isDark == _cachedDark) {
      return;
    }

    _cachedEffectType = effectType;
    _cachedColor = bgColor;
    _cachedDark = isDark;

    try {
      if (useNative) {
        await Window.setEffect(
          effect: _toWindowEffect(effectType),
          color: bgColor,
          dark: isDark,
        );
      } else {
        await Window.setEffect(effect: WindowEffect.disabled);
      }
    } catch (_) {
      // Fallback to transparent if effect unsupported
      try {
        await Window.setEffect(
          effect: WindowEffect.transparent,
          color: bgColor,
          dark: isDark,
        );
      } catch (_) {}
    }
  }

  // ─── Resize handling — prevent acrylic flicker ───────────────────────────

  @override
  void onWindowResize() {
    if (!_isResizing) {
      _isResizing = true;
      _setSolidBackgroundDuringResize();
    }
    _resizeDebounce?.cancel();
    _resizeDebounce = Timer(const Duration(milliseconds: 400), () {
      _onResizeEnd();
    });
  }

  /// Temporarily switches to a solid background during resize to prevent DWM
  /// compositor flicker. Uses [WindowEffect.solid] which paints a solid color
  /// without the blur/transparency pipeline that causes flicker.
  Future<void> _setSolidBackgroundDuringResize() async {
    final theme = _settings?.themeModeNotifier.value ?? ThemeMode.system;
    final isDark = theme == ThemeMode.dark ||
        (theme == ThemeMode.system &&
            PlatformDispatcher.instance.platformBrightness == Brightness.dark);
    final solidColor = isDark ? const Color(0xFF0F0F0F) : const Color(0xFFF5F5F5);

    // Invalidate cache so the next _applyWindowEffect actually fires
    _cachedEffectType = null;
    _cachedColor = null;
    _cachedDark = null;

    // Switch to solid effect — this bypasses the DWM compositor blur pipeline
    // that causes visible flicker during resize.
    try {
      await Window.setEffect(
        effect: WindowEffect.solid,
        color: solidColor,
      );
    } catch (_) {}
  }

  /// Restores the native window effect after a resize completes.
  Future<void> _onResizeEnd() async {
    _isResizing = false;
    await _applyWindowEffect();
  }

  // ─── Window close ────────────────────────────────────────────────────────

  @override
  void onWindowClose() async {
    final bool isPreventClose = await windowManager.isPreventClose();
    if (isPreventClose) {
      if ((_settings?.minimizeToTrayNotifier.value) ?? false) {
        await windowManager.hide();
      } else {
        await windowManager.destroy();
      }
    }
  }

  // ─── Cleanup ─────────────────────────────────────────────────────────────

  void dispose() {
    _effectDebounce?.cancel();
    _resizeDebounce?.cancel();

    _settings
        ?.useNativeWindowEffectNotifier
        .removeListener(_scheduleApplyEffect);
    _settings
        ?.windowOpacityNotifier
        .removeListener(_scheduleApplyEffect);
    _settings
        ?.themeModeNotifier
        .removeListener(_scheduleApplyEffect);

    windowManager.removeListener(this);
  }
}
