import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:ga_song/core/audio/audio_engine_service.dart';
import 'package:ga_song/core/audio/playlist_service.dart';
import 'package:ga_song/core/services/smtc_service.dart';
import 'package:ga_song/core/services/smtc_platform.dart';
import 'package:ga_song/models/song.dart';
import 'package:smtc_windows/smtc_windows.dart';

// ---------------------------------------------------------------------------
// Mock SmtcPlatform — records calls for assertion
// ---------------------------------------------------------------------------
class MockSmtcPlatform implements SmtcPlatform {
  final _buttonController = StreamController<PressedButton>.broadcast();
  @override
  Stream<PressedButton> get buttonPressStream => _buttonController.stream;

  PlaybackStatus? lastSetStatus;
  MusicMetadata? lastMetadata;
  Duration? lastPosition;
  Duration? lastEndTime;
  bool disposed = false;
  bool metadataCleared = false;

  @override
  Future<void> setPlaybackStatus(PlaybackStatus status) async {
    lastSetStatus = status;
  }

  @override
  Future<void> updateMetadata(MusicMetadata metadata) async {
    lastMetadata = metadata;
  }

  @override
  Future<void> clearMetadata() async {
    metadataCleared = true;
  }

  @override
  Future<void> setPosition(Duration position) async {
    lastPosition = position;
  }

  @override
  Future<void> setEndTime(Duration endTime) async {
    lastEndTime = endTime;
  }

  @override
  Future<void> dispose() async {
    disposed = true;
  }

  void simulateButtonPress(PressedButton button) {
    _buttonController.add(button);
  }

  void reset() {
    lastSetStatus = null;
    lastMetadata = null;
    lastPosition = null;
    lastEndTime = null;
    disposed = false;
    metadataCleared = false;
  }
}

// ---------------------------------------------------------------------------
// Mock engine — follows same pattern as playlist_service_test.dart
// ---------------------------------------------------------------------------
class MockAudioEngineService with WidgetsBindingObserver implements AudioEngineService {
  @override
  ValueNotifier<AudioEngineState> engineState =
      ValueNotifier(AudioEngineState.idle);

  @override
  ValueNotifier<Duration> positionNotifier = ValueNotifier(Duration.zero);

  @override
  ValueNotifier<Duration> durationNotifier = ValueNotifier(Duration.zero);

  @override
  ValueNotifier<double> volumeNotifier = ValueNotifier(1.0);

  final _songCompletedController = StreamController<void>.broadcast();
  @override
  Stream<void> get onSongCompleted => _songCompletedController.stream;

  bool paused = false;
  bool stopped = false;

  @override
  Future<void> pause() async {
    paused = true;
  }

  @override
  Future<void> stop() async {
    stopped = true;
  }

  @override
  Future<void> playAsset(String assetPath, {double? normalizationGain}) async {}

  @override
  Future<void> resume() async {}

  @override
  Future<void> seek(Duration position) async {}

  @override
  void setVolume(double volume) {}

  @override
  void setNormalizationGain(double gain) {}

  @override
  Future<void> crossfadeTo(
    String nextAssetPath,
    double crossfadeDuration, {
    double? nextNormalizationGain,
    CrossfadeCurve curve = CrossfadeCurve.linear,
  }) async {}

  @override
  Future<void> preload(String assetPath) async {}

  @override
  Future<void> evictSources(Set<String> keepAssetPaths) async {}

  @override
  Future<void> dispose() async {}

  @override
  Map<String, dynamic> get cacheDiagnostics => {};

  @override
  Future<AudioSource?> ensureSource(String assetPath) async => null;

  // P3.4: Lifecycle observer — mock is a no-op.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {}

  // Forward any other WidgetsBindingObserver methods to noSuchMethod.
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// ---------------------------------------------------------------------------
// Mock playlist service
// ---------------------------------------------------------------------------
class MockPlaylistService implements PlaylistService {
  @override
  List<Song> playlist = [];

  @override
  int currentIndex = -1;

  @override
  Song? currentSong;

  @override
  PlayMode playMode = PlayMode.sequential;

  @override
  final ValueNotifier<int> currentIndexNotifier = ValueNotifier(-1);

  @override
  final ValueNotifier<PlayMode> playModeNotifier =
      ValueNotifier(PlayMode.sequential);

  @override
  final ValueNotifier<Duration?> sleepTimerRemainingNotifier =
      ValueNotifier(null);

  @override
  SortMode sortMode = SortMode.name;

  @override
  bool sortAscending = true;

  bool played = false;
  bool nexted = false;
  bool previoused = false;

  @override
  Future<void> play() async {
    played = true;
  }

  @override
  Future<void> next() async {
    nexted = true;
  }

  @override
  Future<void> previous() async {
    previoused = true;
  }

  @override
  Future<void> setPlaylist(List<Song> songs, {int startIndex = 0}) async {}

  @override
  void reorderPlaylist(List<Song> songs) {}

  @override
  Future<void> playSongAt(int index, {bool isHistoryNavigation = false}) async {}

  @override
  Future<void> playSongByFileName(String fileName) async {}

  @override
  void setPlayMode(PlayMode mode) {}

  @override
  Future<void> nextPlayMode() async {}

  @override
  void startSleepTimer(Duration duration) {}

  @override
  void cancelSleepTimer() {}

  @override
  bool get isSleepTimerActive => false;

  @override
  void setSortMode(SortMode mode) {}

  @override
  List<Song> getSortedPlaylist(List<Song> songs) => songs;

  @override
  void dispose() {}
}

void main() {
  // SMTC is Windows-only — skip all tests on non-Windows platforms.
  if (!Platform.isWindows) {
    test('SMTC tests require Windows', () {});
    return;
  }

  late MockAudioEngineService mockEngine;
  late MockPlaylistService mockPlaylist;
  late MockSmtcPlatform mockSmtc;
  late SmtcService smtcService;

  setUp(() {
    mockEngine = MockAudioEngineService();
    mockPlaylist = MockPlaylistService();
    mockSmtc = MockSmtcPlatform();
    smtcService = SmtcService(mockEngine, mockPlaylist);
  });

  tearDown(() {
    smtcService.dispose();
  });

  // ─── Init Behavior ─────────────────────────────────────────────────────

  // Note: Platform.isWindows check in SmtcService.init() is trivially correct.
  // Testing it requires running on a non-Windows platform or using IOOverrides.
  // On Windows test runners, Platform.isWindows returns true, so early-return
  // behavior cannot be verified. These tests are intentionally omitted.

  // ─── Button Press Handling ─────────────────────────────────────────────

  test('play button press calls playlistService.play()', () async {
    await smtcService.init(smtc: mockSmtc);

    mockSmtc.simulateButtonPress(PressedButton.play);
    await Future<void>.delayed(Duration.zero);

    expect(mockPlaylist.played, isTrue);
  });

  test('pause button press calls engineService.pause()', () async {
    await smtcService.init(smtc: mockSmtc);

    mockSmtc.simulateButtonPress(PressedButton.pause);
    await Future<void>.delayed(Duration.zero);

    expect(mockEngine.paused, isTrue);
  });

  test('next button press calls playlistService.next()', () async {
    await smtcService.init(smtc: mockSmtc);

    mockSmtc.simulateButtonPress(PressedButton.next);
    await Future<void>.delayed(Duration.zero);

    expect(mockPlaylist.nexted, isTrue);
  });

  test('previous button press calls playlistService.previous()', () async {
    await smtcService.init(smtc: mockSmtc);

    mockSmtc.simulateButtonPress(PressedButton.previous);
    await Future<void>.delayed(Duration.zero);

    expect(mockPlaylist.previoused, isTrue);
  });

  test('stop button press calls engineService.stop()', () async {
    await smtcService.init(smtc: mockSmtc);

    mockSmtc.simulateButtonPress(PressedButton.stop);
    await Future<void>.delayed(Duration.zero);

    expect(mockEngine.stopped, isTrue);
  });

  // ─── Engine State → Playback Status ────────────────────────────────────

  test('engineState playing updates SMTC status to playing', () async {
    await smtcService.init(smtc: mockSmtc);

    mockEngine.engineState.value = AudioEngineState.playing;
    await Future<void>.delayed(Duration.zero);

    expect(mockSmtc.lastSetStatus, equals(PlaybackStatus.playing));
  });

  test('engineState paused updates SMTC status to paused', () async {
    await smtcService.init(smtc: mockSmtc);

    mockEngine.engineState.value = AudioEngineState.paused;
    await Future<void>.delayed(Duration.zero);

    expect(mockSmtc.lastSetStatus, equals(PlaybackStatus.paused));
  });

  test('engineState stopped updates SMTC status to stopped', () async {
    await smtcService.init(smtc: mockSmtc);

    mockEngine.engineState.value = AudioEngineState.stopped;
    await Future<void>.delayed(Duration.zero);

    expect(mockSmtc.lastSetStatus, equals(PlaybackStatus.stopped));
  });

  test('engineState error updates SMTC status to stopped', () async {
    await smtcService.init(smtc: mockSmtc);

    mockEngine.engineState.value = AudioEngineState.error;
    await Future<void>.delayed(Duration.zero);

    expect(mockSmtc.lastSetStatus, equals(PlaybackStatus.stopped));
  });

  // ─── Position Throttling ───────────────────────────────────────────────

  test('position updates SMTC when diff >= 900ms', () async {
    await smtcService.init(smtc: mockSmtc);

    mockEngine.positionNotifier.value = const Duration(seconds: 1);
    await Future<void>.delayed(Duration.zero);

    expect(mockSmtc.lastPosition, equals(const Duration(seconds: 1)));
  });

  test('position does NOT update SMTC when diff < 900ms', () async {
    await smtcService.init(smtc: mockSmtc);

    // Set initial position so SMTC knows where we are
    mockEngine.positionNotifier.value = const Duration(seconds: 5);
    await Future<void>.delayed(Duration.zero);
    expect(mockSmtc.lastPosition, equals(const Duration(seconds: 5)));

    // Small change (~300ms) — should be throttled
    mockSmtc.lastPosition = null;
    mockEngine.positionNotifier.value = const Duration(milliseconds: 5300);
    await Future<void>.delayed(Duration.zero);

    expect(mockSmtc.lastPosition, isNull,
        reason: '300ms change should be throttled');
  });

  test('position updates again after crossing 900ms threshold', () async {
    await smtcService.init(smtc: mockSmtc);

    mockEngine.positionNotifier.value = const Duration(seconds: 2);
    await Future<void>.delayed(Duration.zero);
    expect(mockSmtc.lastPosition, equals(const Duration(seconds: 2)));

    // Jump to 3.5s (1.5s diff) — should update
    mockEngine.positionNotifier.value = const Duration(milliseconds: 3500);
    await Future<void>.delayed(Duration.zero);

    expect(mockSmtc.lastPosition, equals(const Duration(milliseconds: 3500)));
  });

  // ─── Duration Updates ──────────────────────────────────────────────────

  test('duration changes update SMTC end time', () async {
    await smtcService.init(smtc: mockSmtc);

    mockEngine.durationNotifier.value = const Duration(seconds: 180);
    await Future<void>.delayed(Duration.zero);

    expect(mockSmtc.lastEndTime, equals(const Duration(seconds: 180)));
  });

  // ─── Dispose ───────────────────────────────────────────────────────────

  test('dispose() cleans up SMTC instance', () async {
    await smtcService.init(smtc: mockSmtc);
    expect(mockSmtc.disposed, isFalse);

    smtcService.dispose();
    expect(mockSmtc.disposed, isTrue);
  });
}
