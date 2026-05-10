import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import '../platform_capabilities.dart';

enum AudioEngineState { idle, loading, playing, paused, stopped, error }

/// Handles low-level audio playback, caching, and SoLoud interactions.
class AudioEngineService {
  final _soloud = SoLoud.instance;

  final Map<String, AudioSource> _sourceCache = {};
  final Map<String, Future<AudioSource?>> _sourceLoadFutures = {};

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
      positionNotifier.value = pos;
    } catch (_) {}
  }

  // ─── Source Management & Caching ───────────────────────────────────────────

  Future<AudioSource?> ensureSource(String assetPath) {
    final cached = _sourceCache[assetPath];
    if (cached != null) {
      return SynchronousFuture<AudioSource?>(cached);
    }

    return _sourceLoadFutures.putIfAbsent(assetPath, () async {
      try {
        final bytes = await rootBundle.load(assetPath);
        final source = await _soloud.loadMem(
          assetPath,
          bytes.buffer.asUint8List(),
        );
        _sourceCache[assetPath] = source;
        return source;
      } catch (e) {
        debugPrint('Preload error at $assetPath: $e');
        return null;
      } finally {
        _sourceLoadFutures.remove(assetPath);
      }
    });
  }

  Future<void> preload(String assetPath) async {
    await ensureSource(assetPath);
  }

  Future<void> evictSources(Set<String> keepAssetPaths) async {
    final toRemove = _sourceCache.keys
        .where((path) => !keepAssetPaths.contains(path))
        .toList();
    for (final path in toRemove) {
      final source = _sourceCache.remove(path);
      if (source == null) continue;
      try {
        await _soloud.disposeSource(source);
      } catch (_) {}
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
    } catch (e) {
      debugPrint('Play error: $e');
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
      } catch (_) {}
    }
    if (crossHandle != null) {
      try {
        if (_soloud.getPause(crossHandle)) {
          _soloud.setPause(crossHandle, false);
        }
      } catch (_) {}
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
      } catch (_) {}
    }
    final crossHandle = _crossfadeHandle;
    if (crossHandle != null) {
      try {
        _soloud.setPause(crossHandle, true);
      } catch (_) {}
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
    } catch (_) {}
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
    } catch (_) {}
  }

  Timer? _crossfadeTimer;

  Future<void> crossfadeTo(
    String nextAssetPath,
    double crossfadeDuration, {
    double? nextNormalizationGain,
  }) async {
    if (_isCrossfading) return;
    if (crossfadeDuration <= 0) {
      await playAsset(nextAssetPath, normalizationGain: nextNormalizationGain);
      return;
    }

    _isCrossfading = true;
    const fadeSteps = 20;
    final stepDuration = Duration(
      milliseconds: (crossfadeDuration * 1000 / fadeSteps).round(),
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
      final fadeOutStep = currentFullVolume / fadeSteps;
      final fadeInStep = targetVolume / fadeSteps;

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
          if (_currentHandle != null) {
            _soloud.setVolume(
              _currentHandle!,
              (currentFullVolume - (fadeOutStep * currentStep)).clamp(0.0, 1.0),
            );
          }
          if (_crossfadeHandle != null) {
            _soloud.setVolume(
              _crossfadeHandle!,
              (fadeInStep * currentStep).clamp(0.0, 1.0),
            );
          }
        } catch (_) {}

        if (currentStep >= fadeSteps) {
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
    } catch (e) {
      debugPrint('Crossfade error: $e');
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
        } catch (_) {}
      }
      
      final crossHandle = _crossfadeHandle;
      _crossfadeHandle = null;
      _isCrossfading = false;
      _crossfadeTimer?.cancel();
      _crossfadeTimer = null;
      if (crossHandle != null) {
        try {
          _soloud.stop(crossHandle);
        } catch (_) {}
      }
    } finally {
      _cleanupLock!.complete();
    }
  }

  Future<void> _disposeAllCached() async {
    for (final source in _sourceCache.values) {
      try {
        await _soloud.disposeSource(source);
      } catch (_) {}
    }
    _sourceCache.clear();
    _sourceLoadFutures.clear();
  }

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
