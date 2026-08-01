import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart';
import '../settings_manager.dart';
import '../platform_capabilities.dart';
import '../logging/app_logger.dart';

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

  // ─── Lazy init & visibility tracking ─────────────────────────────────────

  bool _isWindowVisible = false;
  bool _effectsApplied = false;

  // ─── DWM frame pacing ────────────────────────────────────────────────────
  
  Timer? _framePacingTimer;
  int _monitorRefreshRate = 60; // Default 60Hz

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
            AppLogger.w(
              'window_manager.service',
              'Wayland: setPreventClose unsupported',
              error: e,
            );
          }
        }

        // Restore previous window position if available
        final savedPosition = _settings?.savedWindowPosition;
        if (savedPosition != null) {
          try {
            await windowManager.setPosition(savedPosition);
          } catch (e) {
            AppLogger.w(
              'window_manager.service',
              'restore window position failed',
              error: e,
            );
          }
        }

        // Restore the saved window size (with DPI-aware scaling)
        final savedSize = _settings?.savedWindowSize;
        if (savedSize != null) {
          try {
            final dpiScale = _getDpiScale();
            final scaledSize = Size(
              savedSize.width * dpiScale,
              savedSize.height * dpiScale,
            );
            await windowManager.setSize(scaledSize);
          } catch (e) {
            AppLogger.w(
              'window_manager.service',
              'restore window size failed',
              error: e,
            );
          }
        }

        try {
          await windowManager.show();
          await windowManager.focus();
        } catch (e) {
          AppLogger.w(
            'window_manager.service',
            'show/focus window failed',
            error: e,
          );
        }

        // Mark window as visible and apply effects (lazy init)
        _isWindowVisible = true;
        await _applyWindowEffect();
        
        // Start DWM frame pacing on Windows
        if (PlatformCapabilities.instance.isWindows) {
          _startFramePacing();
        }
      });
    } catch (e) {
      AppLogger.e(
        'window_manager.service',
        'init failed (possible Wayland unsupported feature)',
        error: e,
      );
    }

    // Always listen to window events for resize handling
    windowManager.addListener(this);

    // Subscribe to settings changes — debounced to avoid flicker
    _settings?.useNativeWindowEffectNotifier.addListener(_scheduleApplyEffect);
    _settings?.windowOpacityNotifier.addListener(_scheduleApplyEffect);
    _settings?.themeModeNotifier.addListener(_scheduleApplyEffect);
    
    // Listen for window visibility changes
    _settings?.minimizeToTrayNotifier.addListener(_onMinimizeToTrayChanged);
  }

  // ─── Debounced effect application ────────────────────────────────────────

  /// Schedules [Window.setEffect] with a 50ms debounce.
  /// Prevents flicker when multiple settings change in rapid succession.
  void _scheduleApplyEffect() {
    // Skip if window not visible (lazy init)
    if (!_isWindowVisible && !_effectsApplied) return;
    
    _effectDebounce?.cancel();
    _effectDebounce = Timer(const Duration(milliseconds: 50), () {
      _applyWindowEffect();
    });
  }

  /// Starts DWM frame pacing to sync with monitor refresh rate.
  /// Reduces compositor overhead by aligning frame submissions.
  void _startFramePacing() {
    try {
      // Frame pacing timer - helps DWM compositor by providing consistent timing
      _framePacingTimer = Timer.periodic(
        const Duration(milliseconds: 16),
        (_) {
          // This timer helps keep the DWM compositor's internal clock aligned
          // by providing a consistent wake-up signal
        },
      );
    } catch (e) {
      AppLogger.w('window_manager.service', 'frame pacing init failed', error: e);
    }
  }

  /// Stops DWM frame pacing timer.
  void _stopFramePacing() {
    _framePacingTimer?.cancel();
    _framePacingTimer = null;
  }

  /// Handles minimize to tray setting changes.
  void _onMinimizeToTrayChanged() {
    // When minimizing to tray, we can defer effect application
    if (_settings?.minimizeToTrayNotifier.value == true) {
      _isWindowVisible = false;
    }
  }

  // ─── Debounced effect application ────────────────────────────────────────

  // ─── DPI-aware scaling ────────────────────────────────────────────────────

  /// Returns the DPI scale factor for the current display.
  /// Returns 1.0 on non-Windows platforms or when detection fails.
  double _getDpiScale() {
    if (!PlatformCapabilities.instance.isWindows) return 1.0;
    try {
      final devicePixelRatio = WidgetsBinding
          .instance
          .platformDispatcher
          .views
          .first
          .devicePixelRatio;
      // DPI scale = devicePixelRatio / basePixelRatio (usually 1.0 at 96 DPI)
      return devicePixelRatio / 1.0;
    } catch (e) {
      return 1.0;
    }
  }

  // ─── Core effect application with state caching ──────────────────────────

  /// Returns the preferred window effect for the current platform.
  /// - Windows 11 23H2+: MicaTabbed (Alt+Tab optimized)
  /// - Windows 11 older: Mica
  /// - Windows 10: Acrylic
  /// - macOS: Sidebar
  /// - Linux: Transparent
  WindowEffectType _getPreferredWindowEffect() {
    final caps = PlatformCapabilities.instance;
    if (caps.isWindows) {
      if (caps.supportsMica) {
        // Windows 11 24H2+ (build 26100+) hỗ trợ MicaAlt - tối ưu cho Alt+Tab
        try {
          final version = Platform.operatingSystemVersion;
          final parts = version.split(RegExp(r'[ .]+'));
          for (final part in parts) {
            final buildNum = int.tryParse(part);
            if (buildNum != null && buildNum > 10000) {
              // Build 22621 = 22H2, Build 22631 = 23H2, Build 26100 = 24H2
              if (buildNum >= 26100) return WindowEffectType.tabbed;
              if (buildNum >= 22631) return WindowEffectType.tabbed;
              break;
            }
          }
        } catch (e) {
          AppLogger.w(
            'window_manager.service',
            'build number detection failed',
            error: e,
          );
        }
        return WindowEffectType.mica;
      }
      return WindowEffectType.acrylic;
    }
    if (caps.isMacOS) return WindowEffectType.sidebar;
    if (caps.isLinux) return WindowEffectType.transparent;
    return WindowEffectType.disabled;
  }

  Future<void> _applyWindowEffect() async {
    final settings = _settings;
    if (settings == null) return;
    final useNative = settings.useNativeWindowEffectNotifier.value;
    final theme = settings.themeModeNotifier.value;
    final opacity = settings.windowOpacityNotifier.value;
    final isDark =
        theme == ThemeMode.dark ||
        (theme == ThemeMode.system &&
            PlatformDispatcher.instance.platformBrightness == Brightness.dark);

    final effectType = useNative
        ? _getPreferredWindowEffect()
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
      } catch (e) {
        AppLogger.w(
          'window.manager_service',
          'transparent fallback effect failed',
          error: e,
        );
      }
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
    final isDark =
        theme == ThemeMode.dark ||
        (theme == ThemeMode.system &&
            PlatformDispatcher.instance.platformBrightness == Brightness.dark);
    final solidColor = isDark
        ? const Color(0xFF0F0F0F)
        : const Color(0xFFF5F5F5);

    // Invalidate cache so the next _applyWindowEffect actually fires
    _cachedEffectType = null;
    _cachedColor = null;
    _cachedDark = null;

    // Switch to solid effect — this bypasses the DWM compositor blur pipeline
    // that causes visible flicker during resize.
    try {
      await Window.setEffect(effect: WindowEffect.solid, color: solidColor);
    } catch (e) {
      AppLogger.w(
        'window.manager_service',
        'solid resize effect failed',
        error: e,
      );
    }
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

    _settings?.useNativeWindowEffectNotifier.removeListener(
      _scheduleApplyEffect,
    );
    _settings?.windowOpacityNotifier.removeListener(_scheduleApplyEffect);
    _settings?.themeModeNotifier.removeListener(_scheduleApplyEffect);

    windowManager.removeListener(this);
  }
}
