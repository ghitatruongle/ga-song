/// Test Helpers for G.A - Song
///
/// Common utilities, matchers, and setup helpers for unit, widget, and integration tests.

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod/misc.dart' show Override;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:leak_tracker_flutter_testing/leak_tracker_flutter_testing.dart';

import 'package:ga_song/core/settings_manager.dart';
import 'package:ga_song/core/services/db_service_wrapper.dart';
import 'package:ga_song/core/audio/audio_engine_service.dart';
import 'package:ga_song/core/audio/audio_effect_service.dart';
import 'package:ga_song/core/audio/playlist_service.dart';
import 'package:ga_song/core/cover_art_repository.dart';
import 'package:ga_song/core/services/window_manager_service.dart';
import 'package:ga_song/core/services/system_tray_service.dart';
import 'package:ga_song/core/services/hotkey_service.dart';
import 'package:ga_song/core/services/audio_handler_service.dart';
import 'package:ga_song/core/services/smtc_service.dart';
import 'package:ga_song/core/pip_service.dart';
import 'package:ga_song/core/services/desktop_lyrics_service.dart';
import 'package:ga_song/providers/service_providers.dart';
import 'package:ga_song/models/song.dart';
import 'package:ga_song/models/playlist.dart';

import 'mocks/mock_settings_manager.dart';
import 'mocks/mock_database_service.dart';
import 'mocks/mock_audio_engine_service.dart';
import 'mocks/mock_audio_effect_service.dart';
import 'mocks/mock_playlist_service.dart';
import 'mocks/mock_cover_art_repository.dart';
import 'mocks/mock_window_manager_service.dart';
import 'mocks/mock_system_tray_service.dart';
import 'mocks/mock_hotkey_service.dart';
import 'mocks/mock_audio_handler_service.dart';

// ─── Test Data Factories ─────────────────────────────────────────────

Song createTestSong({
  int? id,
  String name = 'Test Song',
  String? artist = 'Test Artist',
  String? album = 'Test Album',
  int? durationMs = 180000,
  double peakDb = -12.0,
  String sourcePath = 'assets/song/test.mp3',
  bool isBuiltIn = false,
  bool isFavorite = false,
  DateTime? dateAdded,
  int playCount = 0,
  DateTime? lastPlayed,
}) {
  return Song(
    id: id,
    name: name,
    artist: artist,
    album: album,
    durationMs: durationMs,
    peakDb: peakDb,
    sourcePath: sourcePath,
    isBuiltIn: isBuiltIn,
    isFavorite: isFavorite,
    dateAdded: dateAdded,
    playCount: playCount,
    lastPlayed: lastPlayed,
  );
}

List<Song> createTestSongList(int count, {String prefix = 'Song'}) {
  return List.generate(count, (i) {
    return createTestSong(
      id: i + 1,
      name: '$prefix ${i + 1}',
      artist: 'Artist ${(i % 3) + 1}',
      album: 'Album ${(i % 2) + 1}',
      sourcePath: 'assets/song/${prefix.toLowerCase()}_${i + 1}.mp3',
      dateAdded: DateTime(2026, 1, i + 1),
      playCount: i * 2,
      lastPlayed: DateTime(2026, 7, 1).subtract(Duration(days: i)),
    );
  });
}

Playlist createTestPlaylist({
  int? id,
  String name = 'Test Playlist',
  List<int> songIds = const [],
}) {
  return Playlist(id: id, name: name, songIds: songIds);
}

List<Playlist> createTestPlaylistList(int count, {List<Song>? songs}) {
  final songPool = songs ?? createTestSongList(20);
  return List.generate(count, (i) {
    final start = (i * 3) % songPool.length;
    final end = (start + 3).clamp(0, songPool.length);
    return createTestPlaylist(
      id: i + 1,
      name: 'Playlist ${i + 1}',
      songIds: songPool.sublist(start, end).map((s) => s.id!).toList(),
    );
  });
}

Uint8List createTestImageBytes({int width = 100, int height = 100}) {
  // Create a simple PNG header + minimal data
  return Uint8List.fromList([
    0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, // PNG signature
    0x00, 0x00, 0x00, 0x0D, // IHDR chunk length
    0x49, 0x48, 0x44, 0x52, // IHDR
    0x00, 0x00, 0x00, width.toUnsigned(8),
    0x00, 0x00, 0x00, height.toUnsigned(8),
    0x08, 0x02, 0x00, 0x00, 0x00,
  ]);
}

// ─── Mock Service Setup ──────────────────────────────────────────────

/// Creates a complete set of mock services for testing
class MockServices {
  final MockSettingsManager settings;
  final MockDatabaseServiceWrapper database;
  final MockAudioEngineService audioEngine;
  final MockAudioEffectService audioEffect;
  final MockPlaylistService playlist;
  final MockCoverArtRepository coverArt;
  final MockWindowManagerService windowManager;
  final MockSystemTrayService systemTray;
  final MockHotkeyService hotkey;
  final MockAudioHandlerService audioHandler;

  MockServices({
    MockSettingsManager? settings,
    MockDatabaseServiceWrapper? database,
    MockAudioEngineService? audioEngine,
    MockAudioEffectService? audioEffect,
    MockPlaylistService? playlist,
    MockCoverArtRepository? coverArt,
    MockWindowManagerService? windowManager,
    MockSystemTrayService? systemTray,
    MockHotkeyService? hotkey,
    MockAudioHandlerService? audioHandler,
  }) : settings = settings ?? MockSettingsManager(),
       database = database ?? MockDatabaseServiceWrapper(),
       audioEngine = audioEngine ?? MockAudioEngineService(),
       audioEffect = audioEffect ?? MockAudioEffectService(),
       playlist = playlist ?? MockPlaylistService(),
       coverArt = coverArt ?? MockCoverArtRepository(),
       windowManager = windowManager ?? MockWindowManagerService(),
       systemTray = systemTray ?? MockSystemTrayService(),
       hotkey = hotkey ?? MockHotkeyService(
         settingsManager: settings ?? MockSettingsManager(),
       ),
       audioHandler = audioHandler ?? MockAudioHandlerService(
         audioEngine ?? MockAudioEngineService(),
         playlist ?? MockPlaylistService(),
       );

  /// Initialize all services
  Future<void> initAll() async {
    await settings.init();
    await database.init();
    await audioHandler.init();
    await windowManager.init();
  }

  /// Dispose all services
  void disposeAll() {
    settings.dispose();
    database.close();
    audioEngine.dispose();
    audioEffect.dispose();
    playlist.dispose();
    coverArt.clearCache();
    windowManager.dispose();
    systemTray.dispose();
    hotkey.dispose();
    audioHandler.dispose();
  }

  /// Get Riverpod overrides for all services
  List<Override> get overrides => [
    settingsManagerProvider.overrideWithValue(settings),
    databaseServiceProvider.overrideWithValue(database),
    audioEngineServiceProvider.overrideWithValue(audioEngine),
    audioEffectServiceProvider.overrideWithValue(audioEffect),
    playlistServiceProvider.overrideWithValue(playlist),
    coverArtRepositoryProvider.overrideWithValue(coverArt),
    windowManagerServiceProvider.overrideWithValue(windowManager),
    systemTrayServiceProvider.overrideWithValue(systemTray),
    hotkeyServiceProvider.overrideWithValue(hotkey),
    pipServiceProvider.overrideWithValue(PipService.instance),
    desktopLyricsServiceProvider.overrideWithValue(DesktopLyricsService(settingsManager: settings)),
  ];
}

// ─── Widget Test Helpers ─────────────────────────────────────────────

/// Pumps a widget with all mock services initialized
Future<void> pumpTestWidget(
  WidgetTester tester,
  Widget widget, {
  MockServices? services,
  List<Override>? additionalOverrides,
}) async {
  final mockServices = services ?? MockServices();
  await mockServices.initAll();

  final List<Override> overrides = [...mockServices.overrides, ...(additionalOverrides ?? const [])];

  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        home: widget,
        localizationsDelegates: const [
          // Add your localization delegates here
        ],
        supportedLocales: const [Locale('vi'), Locale('en')],
      ),
    ),
  );

  await tester.pumpAndSettle();
}

/// Creates a test app wrapper with providers
Widget createTestApp({
  required Widget child,
  MockServices? services,
  List<Override>? additionalOverrides,
}) {
  final mockServices = services ?? MockServices();
  final List<Override> overrides = [...mockServices.overrides, ...(additionalOverrides ?? const [])];

  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      home: child,
      localizationsDelegates: const [],
      supportedLocales: const [Locale('vi'), Locale('en')],
    ),
  );
}

/// Waits for all microtasks and frames to complete
Future<void> pumpAndSettle(WidgetTester tester, {Duration? timeout}) async {
  await tester.pumpAndSettle(timeout ?? const Duration(seconds: 5));
}

// ─── Async Test Helpers ──────────────────────────────────────────────

/// Runs a test with a timeout
Future<T> withTimeout<T>(Future<T> future, Duration timeout, {T? onTimeout}) async {
  try {
    return await future.timeout(timeout, onTimeout: () {
      if (onTimeout != null) return onTimeout;
      throw TimeoutException('Test timed out after $timeout', timeout);
    });
  } on TimeoutException {
    rethrow;
  }
}

/// Waits for a condition to become true
Future<void> waitFor(
  bool Function() condition, {
  Duration timeout = const Duration(seconds: 5),
  Duration interval = const Duration(milliseconds: 50),
}) async {
  final stopwatch = Stopwatch()..start();
  while (!condition()) {
    if (stopwatch.elapsed > timeout) {
      throw TimeoutException('Condition not met within $timeout');
    }
    await Future.delayed(interval);
  }
}

/// Waits for a ValueNotifier to emit a specific value
Future<void> waitForValue<T>(
  ValueNotifier<T> notifier,
  T expectedValue, {
  Duration timeout = const Duration(seconds: 5),
}) async {
  if (notifier.value == expectedValue) return;
  
  final completer = Completer<void>();
  late VoidCallback listener;
  listener = () {
    if (notifier.value == expectedValue) {
      notifier.removeListener(listener);
      completer.complete();
    }
  };
  notifier.addListener(listener);
  
  await completer.future.timeout(timeout);
}

// ─── Matchers ────────────────────────────────────────────────────────

/// Matcher for Song objects
class SongMatcher extends Matcher {
  final String? name;
  final String? artist;
  final String? album;
  final int? durationMs;

  const SongMatcher({this.name, this.artist, this.album, this.durationMs});

  @override
  bool matches(Object? item, Map matchState) {
    if (item is! Song) return false;
    if (name != null && item.name != name) return false;
    if (artist != null && item.artist != artist) return false;
    if (album != null && item.album != album) return false;
    if (durationMs != null && item.durationMs != durationMs) return false;
    return true;
  }

  @override
  Description describe(Description description) {
    description.add('Song(');
    if (name != null) description.add('name: $name, ');
    if (artist != null) description.add('artist: $artist, ');
    if (album != null) description.add('album: $album, ');
    if (durationMs != null) description.add('duration: $durationMs, ');
    description.add(')');
    return description;
  }
}

Matcher isSong({
  String? name,
  String? artist,
  String? album,
  int? durationMs,
}) => SongMatcher(name: name, artist: artist, album: album, durationMs: durationMs);

/// Matcher for Playlist objects
class PlaylistMatcher extends Matcher {
  final String? name;
  final int? songCount;

  const PlaylistMatcher({this.name, this.songCount});

  @override
  bool matches(Object? item, Map matchState) {
    if (item is! Playlist) return false;
    if (name != null && item.name != name) return false;
    if (songCount != null && item.songIds.length != songCount) return false;
    return true;
  }

  @override
  Description describe(Description description) {
    description.add('Playlist(');
    if (name != null) description.add('name: $name, ');
    if (songCount != null) description.add('songCount: $songCount, ');
    description.add(')');
    return description;
  }
}

Matcher isPlaylist({String? name, int? songCount}) => PlaylistMatcher(name: name, songCount: songCount);


// ─── Performance Test Helpers ────────────────────────────────────────

/// Measures execution time of a callback
Future<Duration> measureTime(FutureOr<void> Function() callback) async {
  final stopwatch = Stopwatch()..start();
  await callback();
  stopwatch.stop();
  return stopwatch.elapsed;
}

/// Runs a callback multiple times and returns statistics
Future<Map<String, Duration>> benchmark(
  FutureOr<void> Function() callback, {
  int iterations = 100,
  Duration? warmupDuration,
}) async {
  // Warmup
  if (warmupDuration != null) {
    final warmupStopwatch = Stopwatch()..start();
    while (warmupStopwatch.elapsed < warmupDuration) {
      await callback();
    }
  }

  final times = <Duration>[];
  for (int i = 0; i < iterations; i++) {
    final time = await measureTime(callback);
    times.add(time);
  }

  times.sort();
  final sum = times.fold<Duration>(Duration.zero, (a, b) => a + b);
  return {
    'min': times.first,
    'max': times.last,
    'mean': Duration(microseconds: sum.inMicroseconds ~/ iterations),
    'median': times[iterations ~/ 2],
    'p90': times[(iterations * 0.9).floor()],
    'p99': times[(iterations * 0.99).floor()],
  };
}

