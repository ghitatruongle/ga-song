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
WindowEffect _toWindowEffect(final WindowEffectType type) {
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
  WindowManagerService({final SettingsManager? settingsManager})
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

  // ─── DPI & HiDPI tracking ────────────────────────────────────────────────

  final double _currentDpiScale = 1;

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

        // Restore the saved window size
        final savedSize = _settings?.savedWindowSize;
        if (savedSize != null) {
          try {
            await windowManager.setSize(savedSize);
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

  /// Schedules [Window.setEffect] with a 25ms debounce (v0.9.5: reduced from 50ms).
  /// Prevents flicker when multiple settings change in rapid succession.
  void _scheduleApplyEffect() {
    // Skip if window not visible (lazy init)
    if (!_isWindowVisible && !_effectsApplied) return;

    _effectDebounce?.cancel();
    _effectDebounce = Timer(const Duration(milliseconds: 25), () {
      _applyWindowEffect();
    });
  }

  /// Handles minimize to tray setting changes.
  void _onMinimizeToTrayChanged() {
    // Track window visibility based on minimize-to-tray setting
    final isMinimizeToTray = _settings?.minimizeToTrayNotifier.value ?? false;
    if (!isMinimizeToTray) {
      // When switching FROM tray mode, re-enable effects
      _isWindowVisible = true;
      _effectsApplied = false;
      _scheduleApplyEffect();
    }
  }

  // ─── Debounced effect application ────────────────────────────────────────

  // ─── DPI-aware scaling ────────────────────────────────────────────────────

  /// Returns the current DPI scale without re-querying.
  double get currentDpiScale => _currentDpiScale;

  // ─── Core effect application with state caching ──────────────────────────

  /// Returns the preferred window effect for the current platform.
  /// - Windows 11 with opacity 100%: MicaTabbed (Alt+Tab optimized) / Mica
  /// - Windows with transparency (opacity < 100%): Acrylic — like macOS,
  ///   acrylic actually blurs the desktop below so content "shows through".
  /// - Windows 10: Acrylic
  /// - macOS: Sidebar
  /// - Linux: Transparent
  WindowEffectType _getPreferredWindowEffect() {
    final caps = PlatformCapabilities.instance;
    if (caps.isWindows) {
      // Transparency mode: always use Acrylic so the window really looks
      // see-through (Mica only tints, it does not blur the underlying area).
      final isTransparentMode =
          (_settings?.windowOpacityNotifier.value ?? 1.0) < 0.99;
      if (isTransparentMode) return WindowEffectType.acrylic;
      if (caps.supportsMica) {
        // Windows 11 24H2+ (build 26100+) hỗ trợ MicaAlt - tối ưu cho Alt+Tab
        try {
          final version = Platform.operatingSystemVersion;
          final parts = version.split(RegExp('[ .]+'));
          for (final part in parts) {
            final buildNum = int.tryParse(part);
            if (buildNum != null && buildNum > 10000) {
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
    } catch (e) {
      // Log the primary effect failure before trying transparent fallback.
      AppLogger.w(
        'window.manager_service',
        'primary effect failed ($effectType), trying transparent fallback',
        error: e,
      );
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
          'transparent fallback effect also failed',
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
    _resizeDebounce = Timer(const Duration(milliseconds: 300), () {
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

  /// Saves current window position and size to settings.
  /// Called periodically and on window move/resize.
  Future<void> _saveWindowState() async {
    final settings = _settings;
    if (settings == null) return;
    // Don't persist mini-player window geometry — onWindowMove/onWindowResize
    // fire while the user drags the 320x320 mini window, and persisting that
    // size would corrupt the restored main-window size after exiting mini mode.
    if (_isMacMiniPlayerMode) return;
    try {
      final position = await windowManager.getPosition();
      final size = await windowManager.getSize();
      final isMaximized = await windowManager.isMaximized();
      final isFullScreen = await windowManager.isFullScreen();
      await settings.setSavedWindowPosition(position);
      await settings.setSavedWindowState(size, isMaximized, isFullScreen);
    } catch (e) {
      AppLogger.w(
        'window_manager.service',
        'save window state failed',
        error: e,
      );
    }
  }

  // ─── Window close ────────────────────────────────────────────────────────

  @override
  Future<void> onWindowClose() async {
    final bool isPreventClose = await windowManager.isPreventClose();
    if (isPreventClose) {
      // Flush debounced settings (EQ, blur, opacity...) BEFORE the app goes
      // away — the settings manager is never disposed (services are created
      // in main() and overridden into Riverpod), so its 300ms debounce would
      // otherwise drop the last changes made by the user.
      onHiddenToTray?.call();
      _settings?.flushPendingWrites();

      // Save window state before any close/hide action
      await _saveWindowState();

      if (_settings?.minimizeToTrayNotifier.value ?? false) {
        _isWindowVisible = false;
        onWindowHiddenChanged?.call(true);
        await windowManager.hide();
      } else {
        await windowManager.destroy();
      }
    }
  }

  // ─── Window move — debounce state save ───────────────────────────────────

  @override
  void onWindowMove() {
    // Debounce saves during drag to avoid excessive SharedPreferences writes
    _stateSaveDebounce?.cancel();
    _stateSaveDebounce = Timer(
      const Duration(milliseconds: 200),
      _saveWindowState,
    );
  }

  // ─── Hidden / minimized → memory relief ────────────────────────────────

  /// Fired when the window is hidden (tray) or minimized so the app can
  /// release decoded audio caches while running in the background.
  VoidCallback? onHiddenToTray;

  /// Fired with the window's visibility state so the visualizer can stop
  /// its ticker while the desktop window is minimized or hidden.
  void Function(bool hidden)? onWindowHiddenChanged;

  // Note: window_manager 0.5.1 emits onWindowMinimize / onWindowRestore but
  // NOT onWindowShow / onWindowHide, so tray show/hide is wired through the
  // system_tray_service menu directly (VisualizerController.setWindowHidden).

  @override
  void onWindowMinimize() {
    onHiddenToTray?.call();
    onWindowHiddenChanged?.call(true);
  }

  @override
  void onWindowRestore() {
    _isWindowVisible = true;
    onWindowHiddenChanged?.call(false);
    _scheduleApplyEffect();
  }

  // ─── macOS Mini Player Pinned Mode ──────────────────────────────────────

  bool _isMacMiniPlayerMode = false;
  bool get isMacMiniPlayerMode => _isMacMiniPlayerMode;
  final ValueNotifier<bool> macMiniPlayerNotifier = ValueNotifier(false);

  Future<void> toggleMacMiniPlayerMode() async {
    if (!PlatformCapabilities.instance.isMacOS) return;
    if (_isMacMiniPlayerMode) {
      await exitMacMiniPlayerMode();
    } else {
      await enterMacMiniPlayerMode();
    }
  }

  Future<void> enterMacMiniPlayerMode() async {
    if (_isMacMiniPlayerMode) return;
    // Save current geometry BEFORE flipping the flag — _saveWindowState()
    // skips saving once mini mode is active, so this must happen first.
    await _saveWindowState();
    _isMacMiniPlayerMode = true;
    macMiniPlayerNotifier.value = true;
    try {
      await windowManager.setAlwaysOnTop(true);
      await windowManager.setMinimumSize(const Size(280, 280));
      await windowManager.setSize(const Size(320, 320));
    } catch (e) {
      AppLogger.w(
        'window_manager.service',
        'enter mini player failed',
        error: e,
      );
    }
  }

  Future<void> exitMacMiniPlayerMode() async {
    if (!_isMacMiniPlayerMode) return;
    // Capture the pre-mini size while the flag is still set, so the resize
    // events fired during restore don't overwrite it via _saveWindowState.
    final savedSize = _settings?.savedWindowSize ?? const Size(1000, 700);
    _isMacMiniPlayerMode = false;
    macMiniPlayerNotifier.value = false;
    try {
      await windowManager.setAlwaysOnTop(false);
      await windowManager.setMinimumSize(const Size(800, 600));
      await windowManager.setSize(savedSize);
    } catch (e) {
      AppLogger.w(
        'window_manager.service',
        'exit mini player failed',
        error: e,
      );
    }
  }

  Timer? _stateSaveDebounce;

  void startDragging() {
    windowManager.startDragging();
  }

  // ─── Cleanup ─────────────────────────────────────────────────────────────

  void dispose() {
    _effectDebounce?.cancel();
    _resizeDebounce?.cancel();
    _stateSaveDebounce?.cancel();
    macMiniPlayerNotifier.dispose();

    _settings?.useNativeWindowEffectNotifier.removeListener(
      _scheduleApplyEffect,
    );
    _settings?.windowOpacityNotifier.removeListener(_scheduleApplyEffect);
    _settings?.themeModeNotifier.removeListener(_scheduleApplyEffect);
    _settings?.minimizeToTrayNotifier.removeListener(_onMinimizeToTrayChanged);

    windowManager.removeListener(this);
  }
}
