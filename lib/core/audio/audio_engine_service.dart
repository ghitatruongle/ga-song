import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:path_provider/path_provider.dart';
import '../logging/app_logger.dart';
import '../performance_probe.dart';
import '../platform_capabilities.dart';

enum AudioEngineState { idle, loading, playing, paused, stopped, error }

/// Internal cache entry with LRU access tracking.
class _CacheEntry {
  _CacheEntry(this.source, this.accessOrder);
  final AudioSource source;
  int accessOrder;
}

// ─── Constants ───────────────────────────────────────────────────────────────

/// Number of crossfade volume-stepping iterations.
const int _kCrossfadeSteps = 20;

/// Crossfade curve types for volume interpolation.
enum CrossfadeCurve {
  /// Linear interpolation (equal power)
  linear,

  /// Exponential curve (faster start, slower end)
  exponential,

  /// S-curve (smooth start and end)
  sCurve,
}

/// Maximum diff (ms) before positionNotifier fires an update.
/// Windows: 50ms tolerance; other platforms: 80ms.
const int _kPositionEpsilonDesktop = 50;
const int _kPositionEpsilonMobile = 80;

// ─── Service ─────────────────────────────────────────────────────────────────

/// Handles low-level audio playback, source caching, and SoLoud interactions.
///
/// This service manages:
/// - Audio source loading and LRU caching with platform-aware limits
/// - Playback controls (play, pause, resume, stop, seek)
/// - Volume control with normalization gain support
/// - Crossfade between tracks
/// - Position tracking with adaptive timer intervals
///
/// The LRU cache evicts least-recently-used sources when the cache exceeds
/// the platform limit (50 on desktop, 20 on Android).
class AudioEngineService with WidgetsBindingObserver {
  final _soloud = SoLoud.instance;

  // ─── LRU Cache ───────────────────────────────────────────────────────────
  final Map<String, _CacheEntry> _sourceCache = {};
  final Map<String, Future<AudioSource?>> _sourceLoadFutures = {};

  /// Tracks last-access timestamps for LRU eviction.
  int _cacheAccessCounter = 0;
  int _totalCacheHits = 0;
  int _totalCacheMisses = 0;

  SoundHandle? _currentHandle;
  SoundHandle? _crossfadeHandle;
  AudioSource? _currentSource;
  StreamSubscription<void>? _songEndSub;

  final ValueNotifier<AudioEngineState> engineState = ValueNotifier(
    AudioEngineState.idle,
  );
  final ValueNotifier<Duration> positionNotifier = ValueNotifier(Duration.zero);
  final ValueNotifier<Duration> durationNotifier = ValueNotifier(Duration.zero);
  final ValueNotifier<double> volumeNotifier = ValueNotifier(1);

  // Stream for when a song ends naturally
  final _songCompletedController = StreamController<void>.broadcast();
  Stream<void> get onSongCompleted => _songCompletedController.stream;

  Timer? _positionTimer;
  bool _isTimerPaused = true;
  bool _isDisposed = false;
  bool _isCrossfading = false;
  bool _isPlayingNext = false;

  double _volume = 1;
  double _normalizationGain = 1;

  AudioEngineService() {
    // P3.4: Register for app lifecycle events so the position timer can be
    // paused when the app is backgrounded (saves wakeups / battery) and
    // resumed when the app returns to the foreground (only if a song is
    // actively playing).
    WidgetsBinding.instance.addObserver(this);
  }

  // ─── Async Warmup ──────────────────────────────────────────────────────────

  bool _isWarmedUp = false;
  Completer<void>? _warmupCompleter;

  /// Initializes SoLoud and warms up the audio engine asynchronously.
  /// This should be called early during app startup (before first paint)
  /// to avoid blocking the UI thread when the user first plays a song.
  /// Returns a future that completes when warmup is done.
  Future<void> warmupAsync() async {
    // Prevent multiple concurrent warmups
    if (_isWarmedUp) return;
    if (_warmupCompleter != null) return _warmupCompleter!.future;

    _warmupCompleter = Completer<void>();

    try {
      AppLogger.i('audio.engine_service', 'Starting async warmup...');

      // Initialize SoLoud if not already done.
      // Bounded: on some low-end Android devices the native (miniaudio)
      // init can block for a long time; surface a timeout instead of
      // hanging startup/playback forever.
      if (!_soloud.isInitialized) {
        await _soloud.init().timeout(const Duration(seconds: 12));
      }

      _isWarmedUp = true;
      _warmupCompleter!.complete();

      AppLogger.i('audio.engine_service', 'Async warmup completed');
    } catch (e, stack) {
      AppLogger.e(
        'audio.engine_service',
        'Async warmup failed',
        error: e,
        stack: stack,
      );
      _warmupCompleter!.completeError(e, stack);
    } finally {
      _warmupCompleter = null;
    }
  }

  /// Checks if the engine has been warmed up.
  bool get isWarmedUp => _isWarmedUp;

  /// Ensures the engine is warmed up before playback.
  /// Call this before playAsset if you want to guarantee warmup is done.
  Future<void> ensureWarmedUp() async {
    if (!_isWarmedUp) {
      await warmupAsync();
    }
  }

  // ─── App Lifecycle ────────────────────────────────────────────────────────

  /// Reacts to OS-level lifecycle transitions (background / foreground).
  ///
  /// On background (paused/hidden/inactive/detached) we cancel the position
  /// timer; on resume we restart it only if playback is still active. This
  /// wires the existing `_isTimerPaused` flag to the real OS signal without
  /// introducing new state.
  @override
  void didChangeAppLifecycleState(final AppLifecycleState state) {
    if (_isDisposed) return;
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.inactive:
        _pausePositionTimer();
        // Android: aggressive cache cleanup on background to save memory
        if (PlatformCapabilities.instance.aggressiveMemoryCleanup) {
          _aggressiveCacheCleanup();
        }
        // BUG FIX (v0.9.5): Must break here — without it, execution falls
        // through to detached and calls _soloud.deinit() while the app is
        // merely backgrounded (still alive, just not visible). That kills
        // the audio engine mid-playback and requires a full restart on resume.
        break;
      case AppLifecycleState.detached:
        // v0.9.5: Release SoLoud resources when process is about to be killed
        if (PlatformCapabilities.instance.isAndroid) {
          _pausePositionTimer();
          _soloud.deinit();
        }
        // Must break — falling through to `resumed` would restart the
        // position timer after deinit and call getPosition() on a dead engine.
        break;
      case AppLifecycleState.resumed:
        // Only restart the position timer if we were actively playing
        // before backgrounding. If the user had paused, the engineState
        // is already AudioEngineState.paused and we leave it alone.
        if (engineState.value == AudioEngineState.playing) {
          _startPositionTimer();
        }
    }
  }

  /// Aggressive cache cleanup for low-end Android devices.
  /// Evicts 50% of cache to free memory when app goes to background.
  /// Protects the currently-playing source and properly disposes native handles.
  void _aggressiveCacheCleanup() {
    if (_sourceCache.isEmpty) return;

    final targetSize = (_sourceCache.length * 0.5).ceil();
    final entries = _sourceCache.entries.toList()
      ..sort(
        (final a, final b) =>
            a.value.accessOrder.compareTo(b.value.accessOrder),
      );

    // Find the currently-playing source path to protect it
    String? currentSourcePath;
    if (_currentSource != null) {
      for (final entry in _sourceCache.entries) {
        if (entry.value.source == _currentSource) {
          currentSourcePath = entry.key;
          break;
        }
      }
    }

    int evictedCount = 0;
    for (final entry in entries) {
      if (evictedCount >= targetSize) break;
      // Skip the currently-playing source
      if (entry.key == currentSourcePath) continue;

      _sourceCache.remove(entry.key);
      // Dispose native SoLoud handle to prevent memory leak
      try {
        _soloud.disposeSource(entry.value.source);
      } catch (e) {
        // Source may already be disposed; ignore
      }
      PerformanceProbe.instance.recordEviction();
      evictedCount++;
    }

    AppLogger.d(
      'audio.engine_service',
      'Aggressive cache cleanup: evicted $evictedCount entries',
    );
  }

  // ─── Position Timer ────────────────────────────────────────────────────────

  void _schedulePositionTick() {
    _positionTimer?.cancel();
    if (_isDisposed || _isTimerPaused) return;
    // P2.1: Adaptive interval — 500ms on Android, 250ms on desktop.
    // Reduces unnecessary wake-ups on mobile without noticeably affecting UX.
    final interval = PlatformCapabilities.instance.positionTimerInterval;
    _positionTimer = Timer(interval, () {
      _tick();
      _schedulePositionTick();
    });
  }

  void _startPositionTimer() {
    if (_isTimerPaused) {
      _isTimerPaused = false;
      _schedulePositionTick();
    }
  }

  void _pausePositionTimer() {
    _isTimerPaused = true;
    _positionTimer?.cancel();
  }

  void _tick() {
    if (_isDisposed) return;
    final handle = _currentHandle;
    if (handle == null) return;
    if (!_soloud.isInitialized) return;

    try {
      final pos = _soloud.getPosition(handle);
      // P2: Epsilon check — chỉ notify khi delta > threshold
      // Giảm ~50% rebuild cho position listeners
      final epsilon = PlatformCapabilities.instance.isWindows
          ? _kPositionEpsilonDesktop
          : _kPositionEpsilonMobile;
      final delta = (pos.inMilliseconds - positionNotifier.value.inMilliseconds)
          .abs();
      if (delta > epsilon) {
        positionNotifier.value = pos;
      }
    } catch (e, stack) {
      AppLogger.e(
        'audio.engine_service',
        'position tick failed',
        error: e,
        stack: stack,
      );
    }
  }

  // ─── Source Management & Caching ───────────────────────────────────────────

  Future<AudioSource?> ensureSource(final String assetPath) {
    final normalizedPath = assetPath.replaceAll(r'\', '/');
    final cached = _sourceCache[normalizedPath];
    if (cached != null) {
      _totalCacheHits++;
      // Update LRU access order
      cached.accessOrder = ++_cacheAccessCounter;
      return SynchronousFuture<AudioSource?>(cached.source);
    }

    _totalCacheMisses++;
    return _sourceLoadFutures.putIfAbsent(normalizedPath, () async {
      try {
        final Uint8List data;
        if (normalizedPath.startsWith('assets/')) {
          // Load asset bytes on main thread (required by rootBundle)
          final bytes = await rootBundle.load(normalizedPath);
          data = bytes.buffer.asUint8List(
            bytes.offsetInBytes,
            bytes.lengthInBytes,
          );
        } else {
          // Load local file bytes
          var file = File(normalizedPath);
          if (!await file.exists() && normalizedPath.contains('local_songs')) {
            final fileName = normalizedPath.split('/').last;
            final appDir = await getApplicationDocumentsDirectory();
            final resolvedPath = '${appDir.path}/local_songs/$fileName';
            final resolvedFile = File(resolvedPath);
            if (await resolvedFile.exists()) {
              file = resolvedFile;
              AppLogger.i(
                'audio.engine_service',
                'Resolved local song sandbox path to: $resolvedPath',
              );
            }
          }

          if (!await file.exists()) {
            throw Exception('Local file not found at $normalizedPath');
          }
          data = await file.readAsBytes();
        }

        // Decode audio via SoLoud (native C++ — runs off main thread internally)
        final source = await _soloud.loadMem(normalizedPath, data);

        // Enforce LRU cache max size
        _evictIfNeeded();

        _sourceCache[normalizedPath] = _CacheEntry(
          source,
          ++_cacheAccessCounter,
        );
        // Track cache size for performance profiling
        PerformanceProbe.instance.recordCacheSize(_sourceCache.length);
        return source;
      } catch (e, stack) {
        AppLogger.e(
          'audio.engine_service',
          'Source load failed for $normalizedPath',
          error: e,
          stack: stack,
        );
        return null;
      } finally {
        _sourceLoadFutures.remove(normalizedPath);
      }
    });
  }

  /// Evict least-recently-used entries when cache exceeds the max limit.
  void _evictIfNeeded() {
    final maxEntries = PlatformCapabilities.instance.maxAudioSourceCacheEntries;
    if (_sourceCache.length <= maxEntries) return;

    // Sort by access order (oldest first) and remove excess
    final entries = _sourceCache.entries.toList()
      ..sort(
        (final a, final b) =>
            a.value.accessOrder.compareTo(b.value.accessOrder),
      );

    final toRemove = entries.take(_sourceCache.length - maxEntries);
    for (final entry in toRemove) {
      final removed = _sourceCache.remove(entry.key);
      if (removed != null) {
        PerformanceProbe.instance.recordEviction();
        try {
          _soloud.disposeSource(removed.source);
        } catch (e, stack) {
          AppLogger.e(
            'audio.engine_service',
            'source dispose failed during eviction',
            error: e,
            stack: stack,
          );
        }
      }
    }
  }

  Future<void> preload(final String assetPath) async {
    // Defer to next microtask to avoid blocking UI frames during batch preloads.
    await Future<void>.delayed(Duration.zero);
    PerformanceProbe.instance.recordPreload();
    await ensureSource(assetPath);
  }

  Future<void> evictSources(final Set<String> keepAssetPaths) async {
    final normalizedKeepPaths = keepAssetPaths
        .map((final path) => path.replaceAll(r'\', '/'))
        .toSet();
    final toRemove = _sourceCache.keys
        .where((final path) => !normalizedKeepPaths.contains(path))
        .toList();
    for (final path in toRemove) {
      final entry = _sourceCache.remove(path);
      if (entry == null) continue;
      PerformanceProbe.instance.recordEviction();
      try {
        await _soloud.disposeSource(entry.source);
      } catch (e, stack) {
        AppLogger.e(
          'audio.engine_service',
          'source dispose failed during eviction',
          error: e,
          stack: stack,
        );
      }
    }
  }

  // ─── Playback Controls ─────────────────────────────────────────────────────

  // C1 fix: Completer lock to prevent overlapping cleanup/play.
  Completer<void>? _cleanupLock;

  /// In-flight playAsset marker. `_isPlayingNext` alone was a silent DROP:
  /// on slow devices a previous load can take >10s, and any play request
  /// arriving meanwhile (deep link, next-song, user tap) returned instantly
  /// without playing anything and without any log. Now we WAIT for the
  /// in-flight play to finish, then proceed (latest request wins).
  Completer<void>? _playInFlightCompleter;

  Future<void> playAsset(
    final String assetPath, {
    final double? normalizationGain,
  }) async {
    // Re-entrancy guard: wait (bounded by the in-flight play itself) instead
    // of silently dropping concurrent play requests.
    while (_playInFlightCompleter != null) {
      await _playInFlightCompleter!.future;
    }
    _isPlayingNext = true;
    final inFlight = Completer<void>();
    _playInFlightCompleter = inFlight;
    final playSw = Stopwatch()..start();

    engineState.value = AudioEngineState.loading;
    if (normalizationGain != null) {
      _normalizationGain = normalizationGain;
    }

    try {
      // C1 fix: Wait for any in-flight cleanup to finish first
      if (_cleanupLock != null && !_cleanupLock!.isCompleted) {
        await _cleanupLock!.future;
      }

      await _cleanupCurrent();

      // Ensure the audio engine is initialized before loading/playing.
      // Startup is deferred (main.dart) so init may still be in flight;
      // ensureWarmedUp waits for it (bounded) or throws → error state.
      if (!_soloud.isInitialized) {
        await ensureWarmedUp();
      }

      final source = await ensureSource(assetPath);
      if (source == null) {
        engineState.value = AudioEngineState.error;
        return;
      }

      final dur = _soloud.getLength(source);
      durationNotifier.value = dur;
      positionNotifier.value = Duration.zero;

      _currentHandle = _soloud.play(
        source,
        volume: _volume * _normalizationGain,
      );
      _currentSource = source;

      engineState.value = AudioEngineState.playing;
      _startPositionTimer();

      AppLogger.i(
        'audio.engine_service',
        'playAsset OK in ${playSw.elapsedMilliseconds}ms: $assetPath',
      );

      // Subscribe to song-end event — cancel any prior subscription first
      await _songEndSub?.cancel();
      _songEndSub = null;
      _songEndSub = source.allInstancesFinished.listen((_) {
        if (!_isDisposed && !_isPlayingNext) {
          engineState.value = AudioEngineState.stopped;
          if (!_isCrossfading && !_songCompletedController.isClosed) {
            _songCompletedController.add(null);
          }
        }
      });
    } catch (e, stack) {
      AppLogger.e(
        'audio.engine_service',
        'playAsset failed',
        error: e,
        stack: stack,
      );
      engineState.value = AudioEngineState.error;
    } finally {
      _isPlayingNext = false;
      _playInFlightCompleter = null;
      inFlight.complete();
    }
  }

  Future<void> resume() async {
    final handle = _currentHandle;
    final crossHandle = _crossfadeHandle;
    final hadAnyHandle = handle != null || crossHandle != null;

    if (handle != null) {
      try {
        if (_soloud.getPause(handle)) {
          _soloud.setPause(handle, false);
        }
      } catch (e, stack) {
        AppLogger.e(
          'audio.engine_service',
          'resume failed',
          error: e,
          stack: stack,
        );
      }
    }
    if (crossHandle != null) {
      try {
        if (_soloud.getPause(crossHandle)) {
          _soloud.setPause(crossHandle, false);
        }
      } catch (e, stack) {
        AppLogger.e(
          'audio.engine_service',
          'resume crossfade failed',
          error: e,
          stack: stack,
        );
      }
    }
    if (hadAnyHandle) {
      engineState.value = AudioEngineState.playing;
      _startPositionTimer();
    }
  }

  Future<void> pause() async {
    final handle = _currentHandle;
    if (handle != null) {
      try {
        _soloud.setPause(handle, true);
      } catch (e, stack) {
        AppLogger.e(
          'audio.engine_service',
          'pause failed',
          error: e,
          stack: stack,
        );
      }
    }
    final crossHandle = _crossfadeHandle;
    if (crossHandle != null) {
      try {
        _soloud.setPause(crossHandle, true);
      } catch (e, stack) {
        AppLogger.e(
          'audio.engine_service',
          'pause crossfade failed',
          error: e,
          stack: stack,
        );
      }
    }
    engineState.value = AudioEngineState.paused;
    _pausePositionTimer();
  }

  Future<void> stop() async {
    await _cleanupCurrent();
    positionNotifier.value = Duration.zero;
    engineState.value = AudioEngineState.stopped;
    _pausePositionTimer();
  }

  Future<void> seek(final Duration position) async {
    final handle = _currentHandle;
    if (handle == null) return;
    try {
      _soloud.seek(handle, position);
      positionNotifier.value = position;
    } catch (e, stack) {
      AppLogger.e(
        'audio.engine_service',
        'seek failed',
        error: e,
        stack: stack,
      );
    }
  }

  // ─── Volume & Crossfade ────────────────────────────────────────────────────

  void setVolume(final double volume) {
    _volume = volume.clamp(0.0, 1.0);
    volumeNotifier.value = _volume;
    _applyVolume();
  }

  void setNormalizationGain(final double gain) {
    _normalizationGain = gain;
    _applyVolume();
  }

  void _applyVolume() {
    try {
      if (_currentHandle != null) {
        _soloud.setVolume(_currentHandle!, _volume * _normalizationGain);
      }
    } catch (e, stack) {
      AppLogger.e(
        'audio.engine_service',
        'applyVolume failed',
        error: e,
        stack: stack,
      );
    }
  }

  Timer? _crossfadeTimer;

  Future<void> crossfadeTo(
    final String nextAssetPath,
    final double crossfadeDuration, {
    final double? nextNormalizationGain,
    final CrossfadeCurve curve = CrossfadeCurve.linear,
  }) async {
    if (_isCrossfading) return;
    if (crossfadeDuration <= 0) {
      await playAsset(nextAssetPath, normalizationGain: nextNormalizationGain);
      return;
    }

    _isCrossfading = true;
    final stepDuration = Duration(
      milliseconds: (crossfadeDuration * 1000 / _kCrossfadeSteps).round(),
    );
    final targetVolume = _volume * (nextNormalizationGain ?? 1.0);
    final currentFullVolume = _volume * _normalizationGain;

    try {
      // Same deferred-init guard as playAsset.
      if (!_soloud.isInitialized) {
        await ensureWarmedUp();
      }

      final nextSource = await ensureSource(nextAssetPath);
      if (nextSource == null) {
        _isCrossfading = false;
        return;
      }

      _crossfadeHandle = _soloud.play(nextSource, volume: 0);

      // Use a Completer so the caller can await crossfade completion
      final completer = Completer<void>();
      int currentStep = 0;

      _crossfadeTimer?.cancel();
      _crossfadeTimer = Timer.periodic(stepDuration, (final timer) {
        // Pause-aware: skip step if paused
        if (engineState.value == AudioEngineState.paused) return;

        if (_isDisposed || !_isCrossfading) {
          timer.cancel();
          _crossfadeTimer = null;
          if (!completer.isCompleted) completer.complete();
          return;
        }

        currentStep++;
        try {
          // Calculate progress (0.0 → 1.0)
          final progress = currentStep / _kCrossfadeSteps;

          // Apply curve transformation
          final curvedProgress = _applyCrossfadeCurve(progress, curve);

          if (_currentHandle != null) {
            // Fade out current song
            final fadeOutVolume = currentFullVolume * (1.0 - curvedProgress);
            _soloud.setVolume(_currentHandle!, fadeOutVolume.clamp(0.0, 1.0));
          }
          if (_crossfadeHandle != null) {
            // Fade in next song
            final fadeInVolume = targetVolume * curvedProgress;
            _soloud.setVolume(_crossfadeHandle!, fadeInVolume.clamp(0.0, 1.0));
          }
        } catch (e, stack) {
          AppLogger.e(
            'audio.engine_service',
            'crossfade step failed',
            error: e,
            stack: stack,
          );
        }

        if (currentStep >= _kCrossfadeSteps) {
          timer.cancel();
          _crossfadeTimer = null;
          if (!completer.isCompleted) completer.complete();
        }
      });

      await completer.future;

      if (!_isDisposed && _isCrossfading) {
        await _cleanupCurrent();
        _currentHandle = _crossfadeHandle;
        _crossfadeHandle = null;
        _currentSource = nextSource;
        if (nextNormalizationGain != null) {
          _normalizationGain = nextNormalizationGain;
        }

        final dur = _soloud.getLength(nextSource);
        durationNotifier.value = dur;
        positionNotifier.value = Duration.zero;
        engineState.value = AudioEngineState.playing;
        _startPositionTimer();

        // Subscribe to song-end event — cancel any prior subscription first
        await _songEndSub?.cancel();
        _songEndSub = null;
        _songEndSub = nextSource.allInstancesFinished.listen((_) {
          if (!_isDisposed && !_isPlayingNext) {
            engineState.value = AudioEngineState.stopped;
            if (!_isCrossfading && !_songCompletedController.isClosed) {
              _songCompletedController.add(null);
            }
          }
        });
      }
    } catch (e, stack) {
      AppLogger.e(
        'audio.engine_service',
        'crossfade failed',
        error: e,
        stack: stack,
      );
    } finally {
      _isCrossfading = false;
      _crossfadeHandle = null;
    }
  }

  // ─── Cleanup ───────────────────────────────────────────────────────────────

  Future<void> _cleanupCurrent() async {
    if (_cleanupLock != null && !_cleanupLock!.isCompleted) {
      await _cleanupLock!.future;
      return;
    }
    // C1 fix: Use Completer lock to prevent overlapping cleanup
    _cleanupLock = Completer<void>();
    try {
      // Cancel subscription FIRST to prevent the ended-event from firing
      // during handle.stop() — this was the root cause of orphaned listeners.
      final sub = _songEndSub;
      _songEndSub = null;
      await sub?.cancel();

      final handle = _currentHandle;
      _currentHandle = null;
      _currentSource = null;

      if (handle != null) {
        try {
          _soloud.stop(handle);
        } catch (e, stack) {
          AppLogger.e(
            'audio.engine_service',
            'cleanup handle failed',
            error: e,
            stack: stack,
          );
        }
      }

      final crossHandle = _crossfadeHandle;
      _crossfadeHandle = null;
      _isCrossfading = false;
      _crossfadeTimer?.cancel();
      _crossfadeTimer = null;
      if (crossHandle != null) {
        try {
          _soloud.stop(crossHandle);
        } catch (e, stack) {
          AppLogger.e(
            'audio.engine_service',
            'cleanup crossfade handle failed',
            error: e,
            stack: stack,
          );
        }
      }
    } finally {
      _cleanupLock!.complete();
    }
  }

  Future<void> _disposeAllCached() async {
    for (final entry in _sourceCache.values) {
      try {
        await _soloud.disposeSource(entry.source);
      } catch (e, stack) {
        AppLogger.e(
          'audio.engine_service',
          'dispose cached source failed',
          error: e,
          stack: stack,
        );
      }
    }
    _sourceCache.clear();
    _sourceLoadFutures.clear();
  }

  // ─── Crossfade Curve ──────────────────────────────────────────────────────

  /// Apply crossfade curve transformation to progress value.
  ///
  /// Input: progress (0.0 → 1.0, linear)
  /// Output: curved value (0.0 → 1.0)
  double _applyCrossfadeCurve(
    final double progress,
    final CrossfadeCurve curve,
  ) {
    switch (curve) {
      case CrossfadeCurve.linear:
        return progress;

      case CrossfadeCurve.exponential:
        // Exponential: faster start, slower end
        // Uses x² curve for smoother transition
        return progress * progress;

      case CrossfadeCurve.sCurve:
        // S-curve: smooth start and end
        // Uses smoothstep function: 3x² - 2x³
        return progress * progress * (3.0 - 2.0 * progress);
    }
  }

  // ─── Diagnostics ───────────────────────────────────────────────────────────

  /// Returns cache performance metrics for debugging/profiling.
  Map<String, dynamic> get cacheDiagnostics => {
    'cacheSize': _sourceCache.length,
    'maxCacheSize': PlatformCapabilities.instance.maxAudioSourceCacheEntries,
    'hits': _totalCacheHits,
    'misses': _totalCacheMisses,
    'hitRate': _totalCacheHits + _totalCacheMisses > 0
        ? (_totalCacheHits / (_totalCacheHits + _totalCacheMisses) * 100)
              .toStringAsFixed(1)
        : 'N/A',
    'loadFutures': _sourceLoadFutures.length,
  };

  Future<void> dispose() async {
    // P3.4: Unregister from lifecycle events before tearing down state.
    WidgetsBinding.instance.removeObserver(this);
    _isDisposed = true;

    final sub = _songEndSub;
    _songEndSub = null;
    await sub?.cancel();

    _positionTimer?.cancel();
    _crossfadeTimer?.cancel();
    _crossfadeTimer = null;

    await _songCompletedController.close();
    await _cleanupCurrent();
    await _disposeAllCached();

    engineState.dispose();
    positionNotifier.dispose();
    durationNotifier.dispose();
    volumeNotifier.dispose();
  }

  // ─── Memory relief when window hidden (tray/minimize) ────────────────────

  /// Releases decoded audio buffers except the currently-playing source.
  /// Called when the window is hidden to tray / minimized so background
  /// playback stops accumulating RAM (each decoded track ≈ 30-40MB).
  Future<void> releaseMemoryWhenHidden() async {
    if (_isDisposed) return;
    try {
      final currentSource = _currentSource;
      final toRemove = _sourceCache.entries
          .where((final e) => e.value.source != currentSource)
          .map((final e) => e.key)
          .toList();
      for (final key in toRemove) {
        final entry = _sourceCache.remove(key);
        if (entry == null) continue;
        try {
          await _soloud.disposeSource(entry.source);
        } catch (_) {
          // Source may already be disposed; ignore
        }
        PerformanceProbe.instance.recordEviction();
      }
      _sourceLoadFutures.clear();
      AppLogger.d(
        'audio.engine_service',
        'Hidden-window memory relief: evicted ${toRemove.length} sources',
      );
    } catch (e, stack) {
      AppLogger.e(
        'audio.engine_service',
        'hidden-window memory relief failed',
        error: e,
        stack: stack,
      );
    }
  }
}
