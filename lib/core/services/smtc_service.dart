import '../logging/app_logger.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:smtc_windows/smtc_windows.dart';
import '../audio/audio_engine_service.dart';
import '../audio/playlist_service.dart';
import 'smtc_platform.dart';
import '../cover_art_repository.dart';
import '../../models/song.dart';

class SmtcService {
  final AudioEngineService _engineService;
  final PlaylistService _playlistService;

  SmtcPlatform? _smtc;
  StreamSubscription<PressedButton>? _buttonSubscription;

  /// Throttle position updates to avoid excessive FFI calls.
  /// Windows SMTC doesn't need 250ms precision — 1s is sufficient.
  Duration _lastReportedPosition = Duration.zero;

  /// ─── Persistent thumbnail cache ───────────────────────────────────────

  /// In-memory cache: song fileName -> thumbnail path
  final Map<String, String> _thumbnailMemoryCache = {};

  /// Disk cache directory for thumbnails
  Directory? _thumbnailCacheDir;

  /// Maximum cache size (number of thumbnails)
  static const int _maxCacheSize = 50;

  /// v0.9.5: Increased memory cache TTL from 0 to 10 minutes to avoid
  /// regenerating thumbnails on every song change when the file still exists.
  static const Duration _memoryCacheTtl = Duration(minutes: 10);

  /// Cache access timestamps for LRU eviction
  final Map<String, DateTime> _cacheAccessTimes = {};

  SmtcService(this._engineService, this._playlistService);

  /// Optionally inject an [SmtcPlatform] instance for testing.
  Future<void> init({SmtcPlatform? smtc}) async {
    if (kIsWeb || !Platform.isWindows) return;
    if (_smtc != null) return; // Idempotency check

    // Initialize thumbnail cache directory
    await _initThumbnailCache();

    try {
      smtc ??= await WindowsSmtcPlatform.create(
        config: const SMTCConfig(
          playEnabled: true,
          pauseEnabled: true,
          nextEnabled: true,
          prevEnabled: true,
          stopEnabled: true,
          fastForwardEnabled: true, // Enable for timeline seek
          rewindEnabled: true, // Enable for timeline seek
        ),
      );
      _smtc = smtc;

      // Listen to SMTC buttons
      _buttonSubscription = _smtc!.buttonPressStream.listen((final event) {
        switch (event) {
          case PressedButton.play:
            _playlistService.play();
            break;
          case PressedButton.pause:
            _engineService.pause();
            break;
          case PressedButton.next:
            _playlistService.next();
            break;
          case PressedButton.previous:
            _playlistService.previous();
            break;
          case PressedButton.stop:
            _engineService.stop();
            break;
          case PressedButton.fastForward:
            // Timeline seek forward (10s)
            _seekRelative(const Duration(seconds: 10));
            break;
          case PressedButton.rewind:
            // Timeline seek backward (10s)
            _seekRelative(const Duration(seconds: -10));
            break;
          default:
            break;
        }
      });

      // Listen to engine state to update SMTC status
      _engineService.engineState.addListener(_onEngineStateChanged);

      // Listen to playlist changes to update metadata
      _playlistService.currentIndexNotifier.addListener(
        _onPlaylistIndexChanged,
      );

      // Update timeline
      _engineService.positionNotifier.addListener(_onPositionChanged);
      _engineService.durationNotifier.addListener(_onDurationChanged);

      // Pre-warm cache for current and next few songs
      _prewarmThumbnailCache();
    } catch (e) {
      AppLogger.e('smtc.service', 'SMTC init failed', error: e);
    }
  }

  /// Initializes persistent thumbnail cache directory.
  Future<void> _initThumbnailCache() async {
    try {
      final appDir = await getApplicationCacheDirectory();
      _thumbnailCacheDir = Directory('${appDir.path}/smtc_thumbnails');
      if (!await _thumbnailCacheDir!.exists()) {
        await _thumbnailCacheDir!.create(recursive: true);
      }

      // Load existing cache index
      await _loadCacheIndex();

      // Cleanup old cache entries
      await _cleanupOldCache();

      AppLogger.d(
        'smtc.service',
        'Thumbnail cache initialized at ${_thumbnailCacheDir!.path}',
      );
    } catch (e) {
      AppLogger.w('smtc.service', 'Failed to init thumbnail cache', error: e);
    }
  }

  /// Loads cache index from disk.
  Future<void> _loadCacheIndex() async {
    if (_thumbnailCacheDir == null) return;

    final indexFile = File('${_thumbnailCacheDir!.path}/cache_index.json');
    if (await indexFile.exists()) {
      try {
        final content = await indexFile.readAsString();
        final Map<String, dynamic> index = jsonDecode(content);

        for (final entry in index.entries) {
          final path = entry.value as String;
          final file = File(path);
          if (await file.exists()) {
            _thumbnailMemoryCache[entry.key] = path;
            _cacheAccessTimes[entry.key] = DateTime.now();
          }
        }
        AppLogger.d(
          'smtc.service',
          'Loaded ${_thumbnailMemoryCache.length} cached thumbnails',
        );
      } catch (e) {
        AppLogger.w('smtc.service', 'Failed to load cache index', error: e);
      }
    }
  }

  /// Saves cache index to disk.
  Future<void> _saveCacheIndex() async {
    if (_thumbnailCacheDir == null) return;

    try {
      final indexFile = File('${_thumbnailCacheDir!.path}/cache_index.json');
      final index = <String, String>{};
      for (final entry in _thumbnailMemoryCache.entries) {
        index[entry.key] = entry.value;
      }
      await indexFile.writeAsString(jsonEncode(index));
    } catch (e) {
      AppLogger.w('smtc.service', 'Failed to save cache index', error: e);
    }
  }

  /// Cleans up old cache entries (LRU eviction).
  Future<void> _cleanupOldCache() async {
    if (_thumbnailCacheDir == null) return;

    // Remove files not in memory cache
    try {
      final files = await _thumbnailCacheDir!.list().toList();
      for (final file in files) {
        if (file is File && !_thumbnailMemoryCache.containsValue(file.path)) {
          await file.delete();
        }
      }
    } catch (e) {
      AppLogger.w('smtc.service', 'Cache cleanup failed', error: e);
    }

    // Enforce max size (LRU)
    while (_thumbnailMemoryCache.length > _maxCacheSize) {
      final oldest = _cacheAccessTimes.entries
          .reduce((final a, final b) => a.value.isBefore(b.value) ? a : b)
          .key;

      final path = _thumbnailMemoryCache.remove(oldest);
      _cacheAccessTimes.remove(oldest);

      if (path != null) {
        try {
          await File(path).delete();
        } catch (e) {
          // Ignore
        }
      }
    }

    await _saveCacheIndex();
  }

  /// Gets thumbnail path with persistent caching.
  /// v0.9.5: Added TTL check and file-existence validation before re-caching.
  Future<String?> _getCachedThumbnail(final Song song) async {
    final cacheKey = song.fileName.replaceAll(
      RegExp(r'\.(mp3|flac|wav|m4a)$'),
      '.png',
    );

    // Check memory cache first with TTL
    if (_thumbnailMemoryCache.containsKey(cacheKey)) {
      final path = _thumbnailMemoryCache[cacheKey]!;
      final file = File(path);
      final lastAccess = _cacheAccessTimes[cacheKey];
      final now = DateTime.now();
      // Valid if file exists AND cache is less than _memoryCacheTtl old
      if (await file.exists() &&
          (lastAccess == null ||
              now.difference(lastAccess) < _memoryCacheTtl)) {
        _cacheAccessTimes[cacheKey] = now;
        return path;
      } else {
        // Expired or missing — evict from memory
        _thumbnailMemoryCache.remove(cacheKey);
        _cacheAccessTimes.remove(cacheKey);
      }
    }

    // Check disk cache (persistent, no TTL)
    if (_thumbnailCacheDir != null) {
      final diskPath = '${_thumbnailCacheDir!.path}/$cacheKey';
      final diskFile = File(diskPath);
      if (await diskFile.exists()) {
        _thumbnailMemoryCache[cacheKey] = diskPath;
        _cacheAccessTimes[cacheKey] = DateTime.now();
        await _saveCacheIndex();
        return diskPath;
      }
    }

    // Generate thumbnail
    return _generateAndCacheThumbnail(song, cacheKey);
  }

  /// Generates thumbnail and caches it.
  Future<String?> _generateAndCacheThumbnail(
    final Song song,
    final String cacheKey,
  ) async {
    if (_thumbnailCacheDir == null) return null;

    String? resolvedPath;
    try {
      if (song.isBuiltIn) {
        resolvedPath = await CoverArtRepository.findCoverAssetPath(song);
      } else {
        resolvedPath = await CoverArtRepository.findLocalCoverPath(song);
      }

      if (resolvedPath == null) return null;

      final diskPath = '${_thumbnailCacheDir!.path}/$cacheKey';
      final diskFile = File(diskPath);

      if (song.isBuiltIn) {
        final data = await rootBundle.load(resolvedPath);
        await diskFile.writeAsBytes(
          data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
          flush: true,
        );
      } else {
        final imageFile = File(resolvedPath);
        if (await imageFile.exists()) {
          await imageFile.copy(diskPath);
        } else {
          return null;
        }
      }

      // Update caches
      _thumbnailMemoryCache[cacheKey] = diskPath;
      _cacheAccessTimes[cacheKey] = DateTime.now();

      // Enforce cache size limit
      await _cleanupOldCache();
      await _saveCacheIndex();

      return diskPath;
    } catch (e) {
      AppLogger.w('smtc.service', 'thumbnail generation failed', error: e);
      return null;
    }
  }

  /// Pre-warms cache for current and upcoming songs.
  void _prewarmThumbnailCache() {
    // Schedule in background to avoid blocking init
    Future.microtask(() async {
      final songs = _playlistService.playlist;
      final currentIndex = _playlistService.currentIndex;
      if (currentIndex < 0 || songs.isEmpty) return;

      // Cache current + next 3 songs
      for (int i = 0; i < 4 && currentIndex + i < songs.length; i++) {
        await _getCachedThumbnail(songs[currentIndex + i]);
      }
    });
  }

  /// Seeks relative to current position.
  void _seekRelative(final Duration offset) {
    final currentPos = _engineService.positionNotifier.value;
    final newPos = currentPos + offset;
    final clampedPos = newPos < Duration.zero ? Duration.zero : newPos;
    _engineService.seek(clampedPos);
    _lastReportedPosition = clampedPos;
  }

  void _onEngineStateChanged() {
    if (_smtc == null) return;
    try {
      final state = _engineService.engineState.value;
      switch (state) {
        case AudioEngineState.playing:
          _smtc!.setPlaybackStatus(PlaybackStatus.playing);
          break;
        case AudioEngineState.paused:
          _smtc!.setPlaybackStatus(PlaybackStatus.paused);
          break;
        case AudioEngineState.stopped:
        case AudioEngineState.error:
          _smtc!.setPlaybackStatus(PlaybackStatus.stopped);
          break;
        default:
          break;
      }
    } catch (e) {
      AppLogger.w('smtc.service', 'SMTC state update failed', error: e);
    }
  }

  void _onPlaylistIndexChanged() {
    if (_smtc == null) return;
    _updatePlaylistMetadata();
  }

  Future<void> _updatePlaylistMetadata() async {
    final song = _playlistService.currentSong;
    if (song != null) {
      String? thumbnailPath;

      // Try to get cached thumbnail (persistent cache)
      try {
        thumbnailPath = await _getCachedThumbnail(song);
      } catch (e) {
        // Thumbnail is optional - continue without it
        AppLogger.d('smtc.service', 'thumbnail not available', error: e);
      }

      // Re-check _smtc after await — dispose() may have set it to null
      if (_smtc == null) return;

      try {
        _smtc!.updateMetadata(
          MusicMetadata(
            title: song.name,
            artist: song.artist ?? 'Unknown Artist',
            thumbnail: thumbnailPath,
          ),
        );
        _lastReportedPosition = Duration.zero;
        _onDurationChanged();
      } catch (e) {
        AppLogger.w('smtc.service', 'metadata update failed', error: e);
      }
    } else {
      if (_smtc == null) return;
      try {
        _smtc!.clearMetadata();
      } catch (e) {
        AppLogger.w('smtc.service', 'clearMetadata failed', error: e);
      }
    }
  }

  void _onPositionChanged() {
    if (_smtc == null) return;
    final pos = _engineService.positionNotifier.value;
    // Throttle: only update SMTC when position changes by ≥1 second
    final diff = (pos - _lastReportedPosition).abs();
    if (diff.inMilliseconds < 900) return;
    _lastReportedPosition = pos;
    try {
      _smtc!.setPosition(pos);
    } catch (e) {
      AppLogger.w('smtc.service', 'position update failed', error: e);
    }
  }

  void _onDurationChanged() {
    if (_smtc == null) return;
    try {
      final duration = _engineService.durationNotifier.value;
      _smtc!.setEndTime(duration);
    } catch (e) {
      AppLogger.w('smtc.service', 'duration update failed', error: e);
    }
  }

  void dispose() {
    // Only remove listeners if SMTC was successfully initialized
    // (init() adds these listeners only after _smtc is set)
    if (_smtc != null) {
      try {
        _buttonSubscription?.cancel();
      } catch (e) {
        AppLogger.w('smtc.service', 'dispose failed', error: e);
      }
      try {
        _engineService.engineState.removeListener(_onEngineStateChanged);
        _playlistService.currentIndexNotifier.removeListener(
          _onPlaylistIndexChanged,
        );
        _engineService.positionNotifier.removeListener(_onPositionChanged);
        _engineService.durationNotifier.removeListener(_onDurationChanged);
      } catch (e, stack) {
        AppLogger.e('smtc.service', 'operation failed', error: e, stack: stack);
      }
      try {
        _smtc?.dispose();
      } catch (e) {
        AppLogger.w('smtc.service', 'dispose failed', error: e);
      }

      // Save cache index on dispose
      _saveCacheIndex();
    }
  }
}
