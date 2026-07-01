import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
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
class AudioEngineService {
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
  StreamSubscription<void>? _songEndSub;

  final ValueNotifier<AudioEngineState> engineState =
      ValueNotifier(AudioEngineState.idle);
  final ValueNotifier<Duration> positionNotifier = ValueNotifier(Duration.zero);
  final ValueNotifier<Duration> durationNotifier = ValueNotifier(Duration.zero);
  final ValueNotifier<double> volumeNotifier = ValueNotifier(1.0);

  // Stream for when a song ends naturally
  final _songCompletedController = StreamController<void>.broadcast();
  Stream<void> get onSongCompleted => _songCompletedController.stream;

  Timer? _positionTimer;
  bool _isTimerPaused = true;
  bool _isDisposed = false;
  bool _isCrossfading = false;
  bool _isPlayingNext = false;

  double _volume = 1.0;
  double _normalizationGain = 1.0;

  AudioEngineService();

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
      final delta = (pos.inMilliseconds - positionNotifier.value.inMilliseconds).abs();
      if (delta > epsilon) {
        positionNotifier.value = pos;
      }
    } catch (e, stack) { debugPrint('Error in audio_engine_service: $e\n$stack'); }
  }

  // ─── Source Management & Caching ───────────────────────────────────────────

  Future<AudioSource?> ensureSource(String assetPath) {
    final normalizedPath = assetPath.replaceAll('\\', '/');
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
          data = bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes);
        } else {
          // Load local file bytes
          final file = File(normalizedPath);
          if (!await file.exists()) {
            throw Exception('Local file not found at $normalizedPath');
          }
          data = await file.readAsBytes();
        }
        
        // Decode audio via SoLoud (native C++ — runs off main thread internally)
        final source = await _soloud.loadMem(
          normalizedPath,
          data,
        );
        
        // Enforce LRU cache max size
        _evictIfNeeded();
        
        _sourceCache[normalizedPath] = _CacheEntry(source, ++_cacheAccessCounter);
        // Track cache size for performance profiling
        PerformanceProbe.instance.recordCacheSize(_sourceCache.length);
        return source;
      } catch (e, stack) {
        debugPrint('Source load error at $normalizedPath: $e\n$stack');
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
      ..sort((a, b) => a.value.accessOrder.compareTo(b.value.accessOrder));
    
    final toRemove = entries.take(_sourceCache.length - maxEntries);
    for (final entry in toRemove) {
      final removed = _sourceCache.remove(entry.key);
      if (removed != null) {
        PerformanceProbe.instance.recordEviction();
        try {
          _soloud.disposeSource(removed.source);
        } catch (e, stack) { debugPrint('Error in audio_engine_service: $e\n$stack'); }
      }
    }
  }

  Future<void> preload(String assetPath) async {
    // Defer to next microtask to avoid blocking UI frames during batch preloads.
    await Future<void>.delayed(Duration.zero);
    PerformanceProbe.instance.recordPreload();
    await ensureSource(assetPath);
  }

  Future<void> evictSources(Set<String> keepAssetPaths) async {
    final normalizedKeepPaths = keepAssetPaths.map((path) => path.replaceAll('\\', '/')).toSet();
    final toRemove = _sourceCache.keys
        .where((path) => !normalizedKeepPaths.contains(path))
        .toList();
    for (final path in toRemove) {
      final entry = _sourceCache.remove(path);
      if (entry == null) continue;
      PerformanceProbe.instance.recordEviction();
      try {
        await _soloud.disposeSource(entry.source);
      } catch (e, stack) { debugPrint('Error in audio_engine_service: $e\n$stack'); }
    }
  }

  // ─── Playback Controls ─────────────────────────────────────────────────────

  // C1 fix: Completer lock to prevent overlapping cleanup/play.
  Completer<void>? _cleanupLock;

  Future<void> playAsset(String assetPath, {double? normalizationGain}) async {
    // Guard against re-entrant calls
    if (_isPlayingNext) return;
    _isPlayingNext = true;

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

      engineState.value = AudioEngineState.playing;
      _startPositionTimer();

      // Subscribe to song-end event
      _songEndSub = source.allInstancesFinished.listen((_) {
        if (!_isDisposed && !_isPlayingNext) {
          engineState.value = AudioEngineState.stopped;
          if (!_isCrossfading && !_songCompletedController.isClosed) {
             _songCompletedController.add(null);
          }
        }
      });
    } catch (e, stack) {
      debugPrint('Play error: $e\n$stack');
      engineState.value = AudioEngineState.error;
    } finally {
      _isPlayingNext = false;
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
      } catch (e, stack) { debugPrint('Error in audio_engine_service: $e\n$stack'); }
    }
    if (crossHandle != null) {
      try {
        if (_soloud.getPause(crossHandle)) {
          _soloud.setPause(crossHandle, false);
        }
      } catch (e, stack) { debugPrint('Error in audio_engine_service: $e\n$stack'); }
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
      } catch (e, stack) { debugPrint('Error in audio_engine_service: $e\n$stack'); }
    }
    final crossHandle = _crossfadeHandle;
    if (crossHandle != null) {
      try {
        _soloud.setPause(crossHandle, true);
      } catch (e, stack) { debugPrint('Error in audio_engine_service: $e\n$stack'); }
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

  Future<void> seek(Duration position) async {
    final handle = _currentHandle;
    if (handle == null) return;
    try {
      _soloud.seek(handle, position);
      positionNotifier.value = position;
    } catch (e, stack) { debugPrint('Error in audio_engine_service: $e\n$stack'); }
  }

  // ─── Volume & Crossfade ────────────────────────────────────────────────────

  void setVolume(double volume) {
    _volume = volume.clamp(0.0, 1.0);
    volumeNotifier.value = _volume;
    _applyVolume();
  }

  void setNormalizationGain(double gain) {
    _normalizationGain = gain;
    _applyVolume();
  }

  void _applyVolume() {
    try {
      if (_currentHandle != null) {
        _soloud.setVolume(_currentHandle!, _volume * _normalizationGain);
      }
    } catch (e, stack) { debugPrint('Error in audio_engine_service: $e\n$stack'); }
  }

  Timer? _crossfadeTimer;

  Future<void> crossfadeTo(
    String nextAssetPath,
    double crossfadeDuration, {
    double? nextNormalizationGain,
    CrossfadeCurve curve = CrossfadeCurve.linear,
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
      final nextSource = await ensureSource(nextAssetPath);
      if (nextSource == null) {
        _isCrossfading = false;
        return;
      }

      _crossfadeHandle = _soloud.play(nextSource, volume: 0.0);

      // Use a Completer so the caller can await crossfade completion
      final completer = Completer<void>();
      int currentStep = 0;

      _crossfadeTimer?.cancel();
      _crossfadeTimer = Timer.periodic(stepDuration, (timer) {
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
            _soloud.setVolume(
              _currentHandle!,
              fadeOutVolume.clamp(0.0, 1.0),
            );
          }
          if (_crossfadeHandle != null) {
            // Fade in next song
            final fadeInVolume = targetVolume * curvedProgress;
            _soloud.setVolume(
              _crossfadeHandle!,
              fadeInVolume.clamp(0.0, 1.0),
            );
          }
        } catch (e, stack) { debugPrint('Error in audio_engine_service: $e\n$stack'); }

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
        if (nextNormalizationGain != null) {
          _normalizationGain = nextNormalizationGain;
        }

        final dur = _soloud.getLength(nextSource);
        durationNotifier.value = dur;
        positionNotifier.value = Duration.zero;
        engineState.value = AudioEngineState.playing;
        _startPositionTimer();

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
      debugPrint('Crossfade error: $e\n$stack');
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

      if (handle != null) {
        try {
          _soloud.stop(handle);
        } catch (e, stack) { debugPrint('Error in audio_engine_service: $e\n$stack'); }
      }
      
      final crossHandle = _crossfadeHandle;
      _crossfadeHandle = null;
      _isCrossfading = false;
      _crossfadeTimer?.cancel();
      _crossfadeTimer = null;
      if (crossHandle != null) {
        try {
          _soloud.stop(crossHandle);
        } catch (e, stack) { debugPrint('Error in audio_engine_service: $e\n$stack'); }
      }
    } finally {
      _cleanupLock!.complete();
    }
  }

  Future<void> _disposeAllCached() async {
    for (final entry in _sourceCache.values) {
      try {
        await _soloud.disposeSource(entry.source);
      } catch (e, stack) { debugPrint('Error in audio_engine_service: $e\n$stack'); }
    }
    _sourceCache.clear();
    _sourceLoadFutures.clear();
  }

  // ─── Crossfade Curve ──────────────────────────────────────────────────────

  /// Apply crossfade curve transformation to progress value.
  ///
  /// Input: progress (0.0 → 1.0, linear)
  /// Output: curved value (0.0 → 1.0)
  double _applyCrossfadeCurve(double progress, CrossfadeCurve curve) {
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
        ? (_totalCacheHits / (_totalCacheHits + _totalCacheMisses) * 100).toStringAsFixed(1)
        : 'N/A',
    'loadFutures': _sourceLoadFutures.length,
  };

  Future<void> dispose() async {
    _isDisposed = true;
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
}
