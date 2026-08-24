import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:system_tray/system_tray.dart';
import '../audio/audio_engine_service.dart';
import '../audio/playlist_service.dart';
import '../logging/app_logger.dart';
import '../../ui/visualizer/visualizer_controller.dart';

class SystemTrayService {
  SystemTrayService({
    final AudioEngineService? audioEngineService,
    final PlaylistService? playlistService,
  }) : _engine = audioEngineService,
       _playlist = playlistService;

  final AudioEngineService? _engine;
  final PlaylistService? _playlist;
  SystemTray? _systemTray;

  // Device bug fix: AppWindow()'s constructor in the system_tray plugin
  // calls `InitAppWindow` on a MethodChannel synchronously. On Android
  // (and iOS / web) that channel has no implementation, which throws
  // `MissingPluginException` before we ever get to `init()`. Use lazy
  // initialization so the platform-channel call only fires on desktop.
  late final AppWindow _appWindow = _isDesktop ? AppWindow() : _noOpAppWindow;
  late final Menu _menu = _isDesktop ? Menu() : _noOpMenu;

  // ─── Icon caching ──────────────────────────────────────────────────────

  String? _cachedIconPath;
  Uint8List? _cachedIconBytes;
  static const _iconCacheDuration = Duration(days: 7);

  // ─── Event-driven updates ──────────────────────────────────────────────
  // Uses addListener (returns void) — we store WeakReferences via
  // a helper to allow removal. Listeners are added/removed by reference
  final Set<VoidCallback> _trayListeners = {};

  // ─── Live tooltip ──────────────────────────────────────────────────────

  Timer? _tooltipUpdateTimer;
  String? _lastTooltipText;

  static bool get _isDesktop =>
      !kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux);

  /// Stand-in AppWindow for non-desktop platforms. The system_tray
  /// plugin's AppWindow exposes its methods as instance members that
  // forward to the platform channel; we never call them on mobile.
  AppWindow get _noOpAppWindow => throw StateError(
    'SystemTrayService._appWindow is unavailable on non-desktop platforms',
  );

  /// Stand-in Menu for non-desktop platforms.
  Menu get _noOpMenu => throw StateError(
    'SystemTrayService._menu is unavailable on non-desktop platforms',
  );

  Future<void> init() async {
    if (!_isDesktop) {
      // Non-desktop platforms: nothing to do. The class-level `late`
      // fields above are wired to the no-op stand-ins, so nothing
      // touches the platform channel.
      return;
    }

    try {
      _systemTray = SystemTray();
      final String path = await _getCachedIconPath();

      final iconFileCheck = File(path);
      if (!iconFileCheck.existsSync()) {
        AppLogger.i(
          'system_tray.service',
          'icon not found, skipping init: $path',
        );
        _systemTray = null;
        return;
      }

      await _systemTray!.initSystemTray(title: 'G.A - Song', iconPath: path);

      await _buildMenu();

      _systemTray!.registerSystemTrayEventHandler((final eventName) {
        if (eventName == kSystemTrayEventClick) {
          Platform.isWindows
              ? _appWindow.show()
              : _systemTray!.popUpContextMenu();
        } else if (eventName == kSystemTrayEventRightClick) {
          Platform.isWindows
              ? _systemTray!.popUpContextMenu()
              : _appWindow.show();
        }
      });

      // Set up event-driven updates (replaces polling)
      _setupEventDrivenUpdates();

      // Start live tooltip updates (runs only while playing to save idle wakeups)
      _syncTooltipTimer();
    } catch (e, stackTrace) {
      AppLogger.e('system_tray.service', 'SystemTray init failed', error: e);
      AppLogger.d('system_tray.service', 'stack', error: stackTrace);
      _systemTray = null;
    }
  }

  /// Gets icon path with memory + disk caching.
  Future<String> _getCachedIconPath() async {
    // Check memory cache first
    if (_cachedIconPath != null && _cachedIconBytes != null) {
      final cacheFile = File(_cachedIconPath!);
      if (await cacheFile.exists()) {
        AppLogger.d('system_tray.service', 'using memory cached icon');
        return _cachedIconPath!;
      }
    }

    // Check disk cache
    final cacheDir = Directory.systemTemp;
    final cacheFileName = Platform.isWindows
        ? 'ga_song_app_icon.ico'
        : 'ga_song_app_icon.png';
    final cacheFile = File(
      '${cacheDir.path}${Platform.pathSeparator}$cacheFileName',
    );

    if (await cacheFile.exists()) {
      final stat = await cacheFile.stat();
      // Check if cache is still valid
      if (DateTime.now().difference(stat.modified) < _iconCacheDuration) {
        _cachedIconPath = cacheFile.path;
        _cachedIconBytes = await cacheFile.readAsBytes();
        AppLogger.d('system_tray.service', 'using disk cached icon');
        return cacheFile.path;
      }
    }

    // Extract from assets and cache
    final assetPath = Platform.isWindows
        ? 'assets/pic/app_icon.ico'
        : 'assets/pic/app_logo.png';

    try {
      final byteData = await rootBundle.load(assetPath);
      final bytes = byteData.buffer.asUint8List(
        byteData.offsetInBytes,
        byteData.lengthInBytes,
      );

      // Write to disk cache
      await cacheFile.writeAsBytes(bytes, flush: true);

      // Update memory cache
      _cachedIconPath = cacheFile.path;
      _cachedIconBytes = bytes;

      AppLogger.d('system_tray.service', 'icon extracted and cached');
      return cacheFile.path;
    } catch (e) {
      AppLogger.w('system_tray.service', 'icon extraction failed', error: e);
      // Return asset path as fallback (might not work on all platforms)
      return assetPath;
    }
  }

  /// Sets up event-driven updates from audio engine and playlist.
  /// v0.9.5: Uses direct addListener on ValueNotifiers instead of polling
  /// Stream.periodic, eliminating redundant timers and reducing CPU wake-ups.
  void _setupEventDrivenUpdates() {
    final engine = _engine;
    final playlist = _playlist;
    if (engine == null || playlist == null) return;

    // addListener returns void; we add the same callback to each notifier
    // and store a reference so we can remove them later.
    void onEvent() {
      _scheduleMenuUpdate();
      _syncTooltipTimer();
    }

    engine.engineState.addListener(onEvent);
    engine.positionNotifier.addListener(onEvent);
    engine.durationNotifier.addListener(onEvent);
    playlist.currentIndexNotifier.addListener(onEvent);
    _trayListeners.add(onEvent);
  }

  /// Schedules a menu update (debounced to 200ms).
  Timer? _menuUpdateDebounce;
  bool _isBuildingMenu = false;
  bool _pendingRebuild = false;
  void _scheduleMenuUpdate() {
    _menuUpdateDebounce?.cancel();
    _menuUpdateDebounce = Timer(const Duration(milliseconds: 200), () {
      _buildMenu();
    });
  }

  /// Builds and sets the system tray context menu with current playback info.
  Future<void> _buildMenu() async {
    if (_systemTray == null) return;
    // Guard: if a previous build is still in flight, mark pending so we
    // re-run after it completes — avoids stale menu when rapid events fire.
    if (_isBuildingMenu) {
      _pendingRebuild = true;
      return;
    }
    _isBuildingMenu = true;

    final engineService = _engine;
    final playlistService = _playlist;
    if (engineService == null || playlistService == null) {
      _isBuildingMenu = false;
      return;
    }

    try {
      final isPlaying =
          engineService.engineState.value == AudioEngineState.playing;
      final position = engineService.positionNotifier.value;
      final duration = engineService.durationNotifier.value;

      final positionStr = _formatDuration(position);
      final durationStr = _formatDuration(duration);
      final progressPercent = duration.inSeconds > 0
          ? (position.inSeconds / duration.inSeconds * 100).clamp(0, 100)
          : 0.0;

      await _menu.buildFrom([
        MenuItemLabel(
          label: '$positionStr / $durationStr (${progressPercent.toInt()}%)',
        ),
        MenuSeparator(),
        MenuItemLabel(
          label: 'Show',
          onClicked: (final menuItem) {
            VisualizerController.setWindowHidden(false);
            _appWindow.show();
          },
        ),
        MenuItemLabel(
          label: 'Hide',
          onClicked: (final menuItem) {
            VisualizerController.setWindowHidden(true);
            _appWindow.hide();
          },
        ),
        MenuSeparator(),
        MenuItemLabel(
          label: isPlaying ? 'Pause' : 'Play',
          onClicked: (final menuItem) {
            if (isPlaying) {
              engineService.pause();
            } else {
              engineService.resume();
            }
          },
        ),
        MenuItemLabel(
          label: 'Next',
          onClicked: (final menuItem) => playlistService.next(),
        ),
        MenuItemLabel(
          label: 'Previous',
          onClicked: (final menuItem) => playlistService.previous(),
        ),
        MenuSeparator(),
        MenuItemLabel(
          label: 'Exit',
          onClicked: (final menuItem) => exit(0),
        ),
      ]);

      try {
        await _systemTray!.setContextMenu(_menu);
      } catch (e) {
        AppLogger.w(
          'system_tray.service',
          'setContextMenu failed, falling back',
          error: e,
        );
        try {
          final menu = Menu();
          await menu.buildFrom([
            MenuItemLabel(
              label: 'Exit',
              onClicked: (final menuItem) => exit(0),
            ),
          ]);
          await _systemTray!.setContextMenu(menu);
        } catch (e2) {
          AppLogger.w(
            'system_tray.service',
            'fallback setContextMenu failed',
            error: e2,
          );
        }
      }
    } finally {
      _isBuildingMenu = false;
      if (_pendingRebuild) {
        _pendingRebuild = false;
        _buildMenu();
      }
    }
  }

  /// Format Duration thành chuỗi mm:ss
  String _formatDuration(final Duration duration) {
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Starts live tooltip updates (every 2 seconds when playing).
  void _syncTooltipTimer() {
    final engine = _engine;
    if (engine == null || _systemTray == null) return;
    final isPlaying = engine.engineState.value == AudioEngineState.playing;
    if (isPlaying) {
      if (_tooltipUpdateTimer == null || !_tooltipUpdateTimer!.isActive) {
        _tooltipUpdateTimer?.cancel();
        _tooltipUpdateTimer = Timer.periodic(const Duration(seconds: 2), (_) {
          _updateTooltip();
        });
      }
    } else {
      _tooltipUpdateTimer?.cancel();
      _tooltipUpdateTimer = null;
      // Push the idle tooltip once so the tray never shows a stale track.
      unawaited(_updateTooltip());
    }
  }

  /// Updates system tray tooltip with current track info.
  Future<void> _updateTooltip() async {
    if (_systemTray == null || _engine == null) return;

    final engine = _engine;
    final isPlaying = engine.engineState.value == AudioEngineState.playing;
    if (!isPlaying) {
      // Show idle tooltip when paused
      if (_lastTooltipText != 'G.A - Song - Paused') {
        _lastTooltipText = 'G.A - Song - Paused';
        try {
          await _systemTray!.setToolTip(_lastTooltipText!);
        } catch (e) {
          AppLogger.d('system_tray.service', 'tooltip update failed', error: e);
        }
      }
      return;
    }

    final position = _formatDuration(engine.positionNotifier.value);
    final duration = _formatDuration(engine.durationNotifier.value);
    final song = _playlist?.currentSong;

    String tooltip;
    if (song != null) {
      final artist = song.artist ?? 'Unknown Artist';
      tooltip = '🎵 ${song.name} - $artist\n⏱️ $position / $duration';
    } else {
      tooltip = 'G.A - Song\n$position / $duration';
    }

    // Only update if changed (avoid flicker)
    if (tooltip != _lastTooltipText) {
      _lastTooltipText = tooltip;
      try {
        await _systemTray!.setToolTip(tooltip);
      } catch (e) {
        AppLogger.d('system_tray.service', 'tooltip update failed', error: e);
      }
    }
  }

  void dispose() {
    // v0.9.5: Remove all listener references
    for (final cb in _trayListeners) {
      _engine?.engineState.removeListener(cb);
      _engine?.positionNotifier.removeListener(cb);
      _engine?.durationNotifier.removeListener(cb);
      _playlist?.currentIndexNotifier.removeListener(cb);
    }
    _trayListeners.clear();
    _menuUpdateDebounce?.cancel();
    _tooltipUpdateTimer?.cancel();

    // Clear caches
    _cachedIconPath = null;
    _cachedIconBytes = null;
    _lastTooltipText = null;

    try {
      _systemTray?.destroy();
    } catch (e) {
      AppLogger.w('system_tray.service', 'dispose failed', error: e);
    }
  }
}
