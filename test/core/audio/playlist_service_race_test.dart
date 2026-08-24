import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ga_song/core/audio/audio_engine_service.dart';
import 'package:ga_song/core/audio/audio_effect_service.dart';
import 'package:ga_song/core/audio/playlist_service.dart';
import 'package:ga_song/core/services/db_service_wrapper.dart';
import 'package:ga_song/models/song.dart';

/// Regression tests for the cache-window prepare race:
/// skipping to a new song WHILE `_prepareCacheWindow` is still decoding the
/// previous window must still end with the NEW window preloaded. Before the
/// fix, the epoch bump aborted the in-flight run and the guard returned
/// early, leaving the new position with NO preloads until the next index
/// change.
void main() {
  late BlockingEngine engine;
  late PlaylistService service;

  final songs = List.generate(
    10,
    (final i) => Song(
      name: 'Song $i',
      sourcePath: 'song_$i.mp3',
      artist: 'Artist',
      durationMs: 200000,
    ),
  );

  setUp(() {
    engine = BlockingEngine();
    service = PlaylistService(engine, _MockEffect(), _MockDb());
  });

  tearDown(() {
    service.dispose();
  });

  Future<void> flush() async {
    for (var i = 0; i < 8; i++) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  test('skip during in-flight prepare still preloads the new window', () async {
    // setPlaylist's own prepare (#0) blocks on the gate.
    final setList = service.setPlaylist(songs);
    await flush();
    expect(engine.preloaded, isEmpty, reason: 'prepare should be blocked');

    // Two skips while #0 is still in flight (prepare for index 2, then 8).
    await service.playSongAt(2);
    await service.playSongAt(8);

    // Release the gate: #0 aborts on the epoch mismatch, and the pending
    // retry must preload the window around the CURRENT index (8).
    engine.release();
    await setList;
    await flush();

    expect(engine.preloaded, contains('song_8.mp3'));
    expect(engine.preloaded, contains('song_9.mp3'));
  });

  test(
    'single skip during in-flight prepare still preloads the new window',
    () async {
      final setList = service.setPlaylist(songs);
      await flush();

    await service.playSongAt(5);

    engine.release();
    await setList;
    await flush();

      expect(engine.preloaded, contains('song_5.mp3'));
      expect(engine.preloaded, contains('song_6.mp3'));
    },
  );

  test('without a skip, prepare completes normally', () async {
    final setList = service.setPlaylist(songs);
    await flush();
    engine.release();
    await setList;
    await flush();

    expect(engine.preloaded, contains('song_0.mp3'));
    expect(engine.preloaded, contains('song_1.mp3'));
  });
}

/// Engine mock whose [preload] blocks until [release] is called, so tests can
/// hold a cache-window prepare in flight deterministically.
class BlockingEngine implements AudioEngineService {
  final List<String> preloaded = [];
  // One gate per blocked preload — parallel preloads each hold their own
  // gate, so release() must complete every one of them.
  final List<Completer<void>> _gates = [];
  bool _blocking = true;

  int _epoch = 0;
  @override
  int get cacheEpoch => _epoch;
  @override
  void bumpCacheEpoch() => _epoch++;

  void release() {
    _blocking = false;
    for (final gate in _gates) {
      gate.complete();
    }
    _gates.clear();
  }

  @override
  Future<void> preload(final String assetPath) async {
    if (_blocking) {
      final gate = Completer<void>();
      _gates.add(gate);
      await gate.future;
    }
    preloaded.add(assetPath);
  }

  @override
  Future<void> evictSources(final Set<String> keepAssetPaths) async {}

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
  @override
  Stream<void> get onSongCompleted => const Stream<void>.empty();
  @override
  Future<void> playAsset(
    final String assetPath, {
    final double? normalizationGain,
  }) async {}
  @override
  Future<void> stop() async {}
  @override
  Future<void> resume() async {}
  @override
  Future<void> pause() async {}
  @override
  Future<void> seek(final Duration position) async {}
  @override
  void setVolume(final double volume) {}
  @override
  void setNormalizationGain(final double gain) {}
  @override
  Future<void> crossfadeTo(
    final String nextAssetPath,
    final double crossfadeDuration, {
    final double? nextNormalizationGain,
    final CrossfadeCurve curve = CrossfadeCurve.linear,
  }) async {}
  @override
  Future<void> dispose() async {}

  @override
  dynamic noSuchMethod(final Invocation invocation) =>
      super.noSuchMethod(invocation);
}

class _MockEffect implements AudioEffectService {
  @override
  ValueNotifier<double> crossfadeDurationNotifier = ValueNotifier(0);
  @override
  double calculateNormalizationGain(final double? peakDb) => 1;
  @override
  dynamic noSuchMethod(final Invocation invocation) =>
      super.noSuchMethod(invocation);
}

class _MockDb implements DatabaseServiceWrapper {
  @override
  Future<void> incrementPlayCount(final int songId) async {}
  @override
  dynamic noSuchMethod(final Invocation invocation) =>
      super.noSuchMethod(invocation);
}
