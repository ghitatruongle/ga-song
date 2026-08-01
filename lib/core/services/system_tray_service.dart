import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:system_tray/system_tray.dart';
import 'package:window_manager/window_manager.dart';
import '../audio/audio_engine_service.dart';
import '../audio/playlist_service.dart';
import '../logging/app_logger.dart';
import '../../models/song.dart';

class SystemTrayService {
  SystemTrayService({
    AudioEngineService? audioEngineService,
    PlaylistService? playlistService,
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
  DateTime? _iconCacheTimestamp;

  // ─── Event-driven updates ──────────────────────────────────────────────
  
  StreamSubscription<AudioEngineState>? _engineStateSubscription;
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<Duration>? _durationSubscription;
  StreamSubscription<int>? _currentSongSubscription;
  
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
      String path = await _getCachedIconPath();

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

      _systemTray!.registerSystemTrayEventHandler((eventName) {
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
      
      // Start live tooltip updates
      _startLiveTooltipUpdates();

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
    final cacheFile = File('${cacheDir.path}${Platform.pathSeparator}$cacheFileName');
    
    if (await cacheFile.exists()) {
      final stat = await cacheFile.stat();
      // Check if cache is still valid
      if (DateTime.now().difference(stat.modified) < _iconCacheDuration) {
        _cachedIconPath = cacheFile.path;
        _cachedIconBytes = await cacheFile.readAsBytes();
        _iconCacheTimestamp = stat.modified;
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
      _iconCacheTimestamp = DateTime.now();
      
      AppLogger.d('system_tray.service', 'icon extracted and cached');
      return cacheFile.path;
    } catch (e) {
      AppLogger.w('system_tray.service', 'icon extraction failed', error: e);
      // Return asset path as fallback (might not work on all platforms)
      return assetPath;
    }
  }

  /// Sets up event-driven updates from audio engine and playlist.
  /// Replaces the old polling-based _updateMenu with 500ms debounce.
  void _setupEventDrivenUpdates() {
    final engine = _engine;
    final playlist = _playlist;
    if (engine == null || playlist == null) return;

    // Listen to engine state changes
    _engineStateSubscription = Stream.periodic(
      const Duration(milliseconds: 500),
      (_) => engine.engineState.value,
    ).listen((_) => _scheduleMenuUpdate());

    // Listen to position changes (throttled to avoid excessive updates)
    _positionSubscription = Stream.periodic(
      const Duration(milliseconds: 1000),
      (_) => engine.positionNotifier.value,
    ).listen((_) => _scheduleMenuUpdate());

    // Listen to duration changes
    _durationSubscription = Stream.periodic(
      const Duration(milliseconds: 500),
      (_) => engine.durationNotifier.value,
    ).listen((_) => _scheduleMenuUpdate());

    // Listen to current song changes
    _currentSongSubscription = Stream.periodic(
      const Duration(milliseconds: 500),
      (_) => playlist.currentIndexNotifier.value,
    ).listen((_) => _scheduleMenuUpdate());
  }

  /// Schedules a menu update (debounced to 200ms).
  Timer? _menuUpdateDebounce;
  void _scheduleMenuUpdate() {
    _menuUpdateDebounce?.cancel();
    _menuUpdateDebounce = Timer(const Duration(milliseconds: 200), () {
      _buildMenu();
    });
  }

  /// Builds and sets the system tray context menu with current playback info.
  Future<void> _buildMenu() async {
    if (_systemTray == null) return;

    final engineService = _engine;
    final playlistService = _playlist;
    if (engineService == null || playlistService == null) return;

    final isPlaying =
        engineService.engineState.value == AudioEngineState.playing;
    final position = engineService.positionNotifier.value;
    final duration = engineService.durationNotifier.value;

    // Format position/duration cho progress display
    final positionStr = _formatDuration(position);
    final durationStr = _formatDuration(duration);
    final progressPercent = duration.inSeconds > 0
        ? (position.inSeconds / duration.inSeconds * 100).clamp(0, 100)
        : 0.0;

    await _menu.buildFrom([
      // Progress bar (displayed as text)
      MenuItemLabel(
        label: '$positionStr / $durationStr (${progressPercent.toInt()}%)',
        onClicked: null,
      ),
      MenuSeparator(),
      MenuItemLabel(label: 'Show', onClicked: (menuItem) => _appWindow.show()),
      MenuItemLabel(label: 'Hide', onClicked: (menuItem) => _appWindow.hide()),
      MenuSeparator(),
      MenuItemLabel(
        label: isPlaying ? 'Pause' : 'Play',
        onClicked: (menuItem) {
          if (isPlaying) {
            engineService.pause();
          } else {
            playlistService.play();
          }
        },
      ),
      MenuItemLabel(
        label: 'Next',
        onClicked: (menuItem) => playlistService.next(),
      ),
      MenuItemLabel(
        label: 'Previous',
        onClicked: (menuItem) => playlistService.previous(),
      ),
      MenuSeparator(),
      MenuItemLabel(
        label: 'Exit',
        onClicked: (menuItem) async {
          await windowManager.destroy();
        },
      ),
    ]);

    await _systemTray!.setContextMenu(_menu);
  }

  /// Format Duration thành chuỗi mm:ss
  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void _updateMenu() {
    _scheduleMenuUpdate();
  }

  /// Starts live tooltip updates (every 2 seconds when playing).
  void _startLiveTooltipUpdates() {
    _tooltipUpdateTimer?.cancel();
    _tooltipUpdateTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _updateTooltip();
    });
  }

  /// Updates system tray tooltip with current track info.
  Future<void> _updateTooltip() async {
    if (_systemTray == null || _engine == null) return;

    final engine = _engine!;
    final isPlaying = engine.engineState.value == AudioEngineState.playing;
    if (!isPlaying) return;

    final position = _formatDuration(engine.positionNotifier.value);
    final duration = _formatDuration(engine.durationNotifier.value);
    final song = _playlist?.currentSong;
    
    String tooltip;
    if (song != null) {
      final artist = song.artist ?? 'Unknown Artist';
      tooltip = '${song.name} - $artist\n$position / $duration';
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
    // Cancel all subscriptions
    _engineStateSubscription?.cancel();
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    _currentSongSubscription?.cancel();
    _menuUpdateDebounce?.cancel();
    _tooltipUpdateTimer?.cancel();

    // Clear caches
    _cachedIconPath = null;
    _cachedIconBytes = null;
    _iconCacheTimestamp = null;
    _lastTooltipText = null;

    try {
      _systemTray?.destroy();
    } catch (e) {
      AppLogger.w('system_tray.service', 'dispose failed', error: e);
    }
  }
}
