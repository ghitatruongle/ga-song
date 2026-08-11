import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:ga_song/core/audio/audio_engine_service.dart';

/// Mock implementation of [AudioEngineService] for testing.
/// Simulates playback state without requiring SoLoud native initialization.
class MockAudioEngineService
    with WidgetsBindingObserver
    implements AudioEngineService {
  @override
  ValueNotifier<AudioEngineState> engineState = ValueNotifier(
    AudioEngineState.idle,
  );
  @override
  ValueNotifier<Duration> positionNotifier = ValueNotifier(Duration.zero);
  @override
  ValueNotifier<Duration> durationNotifier = ValueNotifier(Duration.zero);
  @override
  ValueNotifier<double> volumeNotifier = ValueNotifier(1);

  final StreamController<void> _songCompletedController =
      StreamController<void>.broadcast();
  @override
  Stream<void> get onSongCompleted => _songCompletedController.stream;

  // Track method calls for verification
  String? lastPlayedAsset;
  double? lastNormalizationGain;
  Duration? lastSeekPosition;
  int playCallCount = 0;
  int stopCallCount = 0;
  int pauseCallCount = 0;
  int resumeCallCount = 0;

  void triggerSongCompleted() {
    _songCompletedController.add(null);
  }

  @override
  Future<void> stop() async {
    stopCallCount++;
    engineState.value = AudioEngineState.stopped;
    positionNotifier.value = Duration.zero;
  }

  @override
  Future<void> playAsset(
    final String assetPath, {
    final double? normalizationGain,
  }) async {
    playCallCount++;
    lastPlayedAsset = assetPath;
    lastNormalizationGain = normalizationGain;
    engineState.value = AudioEngineState.playing;
    durationNotifier.value = const Duration(minutes: 3);
    positionNotifier.value = Duration.zero;
  }

  @override
  Future<void> resume() async {
    resumeCallCount++;
    engineState.value = AudioEngineState.playing;
  }

  @override
  Future<void> pause() async {
    pauseCallCount++;
    engineState.value = AudioEngineState.paused;
  }

  @override
  Future<void> seek(final Duration position) async {
    lastSeekPosition = position;
    positionNotifier.value = position;
  }

  @override
  void setVolume(final double volume) {
    volumeNotifier.value = volume.clamp(0.0, 1.0);
  }

  @override
  void setNormalizationGain(final double gain) {
    // No-op in mock
  }

  @override
  Future<void> crossfadeTo(
    final String nextAssetPath,
    final double crossfadeDuration, {
    final double? nextNormalizationGain,
    final CrossfadeCurve curve = CrossfadeCurve.linear,
  }) async {
    lastPlayedAsset = nextAssetPath;
    lastNormalizationGain = nextNormalizationGain;
    engineState.value = AudioEngineState.playing;
  }

  @override
  Future<void> preload(final String assetPath) async {
    // No-op in mock
  }

  @override
  Future<void> evictSources(final Set<String> keepAssetPaths) async {
    // No-op in mock
  }

  @override
  Future<void> dispose() async {
    await _songCompletedController.close();
    engineState.dispose();
    positionNotifier.dispose();
    durationNotifier.dispose();
    volumeNotifier.dispose();
  }

  @override
  Map<String, dynamic> get cacheDiagnostics => {
    'cacheSize': 0,
    'maxCacheSize': 50,
    'hits': 0,
    'misses': 0,
    'hitRate': 'N/A',
    'loadFutures': 0,
  };

  @override
  Future<AudioSource?> ensureSource(final String assetPath) async => null;

  // P3.4: Lifecycle observer — mock records the events for verification.
  int lifecycleEventCount = 0;
  AppLifecycleState? lastLifecycleState;

  @override
  void didChangeAppLifecycleState(final AppLifecycleState state) {
    lifecycleEventCount++;
    lastLifecycleState = state;
  }

  // The other WidgetsBindingObserver methods (didChangeLocales,
  // didChangeMetrics, etc.) are forwarded to noSuchMethod so the mock
  // doesn't have to stub them all explicitly.
  @override
  dynamic noSuchMethod(final Invocation invocation) =>
      super.noSuchMethod(invocation);
}
