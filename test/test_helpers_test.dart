/// Unit Tests for Mock Services
///
/// Tests the mock implementations to ensure they behave correctly.
library;

import 'package:flutter_test/flutter_test.dart';

import 'test_helpers.dart';

void main() {
  group('Test Helpers', () {
    group('createTestSong', () {
      test('creates song with default values', () {
        final song = createTestSong();

        expect(song.name, 'Test Song');
        expect(song.artist, 'Test Artist');
        expect(song.album, 'Test Album');
        expect(song.durationMs, 180000);
        expect(song.sourcePath, 'assets/song/test.mp3');
        expect(song.isBuiltIn, false);
        expect(song.isFavorite, false);
      });

      test('creates song with custom values', () {
        final song = createTestSong(
          id: 42,
          name: 'Custom Song',
          artist: 'Custom Artist',
          album: 'Custom Album',
          durationMs: 250000,
          sourcePath: '/custom/path.mp3',
          isBuiltIn: true,
          isFavorite: true,
          playCount: 10,
        );

        expect(song.id, 42);
        expect(song.name, 'Custom Song');
        expect(song.artist, 'Custom Artist');
        expect(song.album, 'Custom Album');
        expect(song.durationMs, 250000);
        expect(song.sourcePath, '/custom/path.mp3');
        expect(song.isBuiltIn, true);
        expect(song.isFavorite, true);
        expect(song.playCount, 10);
      });
    });

    group('createTestSongList', () {
      test('creates list of songs with sequential data', () {
        final songs = createTestSongList(5, prefix: 'Track');

        expect(songs.length, 5);
        for (int i = 0; i < 5; i++) {
          expect(songs[i].id, i + 1);
          expect(songs[i].name, 'Track ${i + 1}');
          expect(songs[i].artist, 'Artist ${(i % 3) + 1}');
          expect(songs[i].album, 'Album ${(i % 2) + 1}');
          expect(songs[i].sourcePath, 'assets/song/track_${i + 1}.mp3');
          expect(songs[i].playCount, i * 2);
        }
      });

      test('creates empty list for zero count', () {
        final songs = createTestSongList(0);
        expect(songs, isEmpty);
      });
    });

    group('createTestPlaylist', () {
      test('creates playlist with default values', () {
        final playlist = createTestPlaylist();

        expect(playlist.name, 'Test Playlist');
        expect(playlist.songIds, isEmpty);
      });

      test('creates playlist with custom values', () {
        final playlist = createTestPlaylist(
          id: 10,
          name: 'My Playlist',
          songIds: [1, 2, 3],
        );

        expect(playlist.id, 10);
        expect(playlist.name, 'My Playlist');
        expect(playlist.songIds, [1, 2, 3]);
      });
    });

    group('createTestPlaylistList', () {
      test('creates multiple playlists from song pool', () {
        final songs = createTestSongList(10);
        final playlists = createTestPlaylistList(3, songs: songs);

        expect(playlists.length, 3);
        for (int i = 0; i < 3; i++) {
          expect(playlists[i].id, i + 1);
          expect(playlists[i].name, 'Playlist ${i + 1}');
          expect(playlists[i].songIds.length, 3);
          // All song IDs should be valid
          for (final songId in playlists[i].songIds) {
            expect(songs.any((final s) => s.id == songId), isTrue);
          }
        }
      });
    });

    group('createTestImageBytes', () {
      test('creates valid PNG header', () {
        final bytes = createTestImageBytes();

        expect(bytes.length, greaterThan(8));
        // PNG signature
        expect(bytes[0], 0x89);
        expect(bytes[1], 0x50);
        expect(bytes[2], 0x4E);
        expect(bytes[3], 0x47);
      });
    });
  });

  group('MockServices', () {
    late MockServices mockServices;

    setUp(() {
      mockServices = MockServices();
    });

    tearDown(() {
      mockServices.disposeAll();
    });

    test('initializes all services', () async {
      await mockServices.initAll();
      // If we reach here without error, all services initialized
      expect(true, isTrue);
    });

    test('provides correct overrides', () {
      final overrides = mockServices.overrides;

      expect(overrides.length, greaterThan(5));

      // Check key providers are overridden
      final providerTypes = overrides
          .map((final o) => o.origin.runtimeType.toString())
          .toList();
      expect(
        providerTypes.any((final t) => t.contains('SettingsManager')),
        isTrue,
      );
      expect(
        providerTypes.any((final t) => t.contains('DatabaseService')),
        isTrue,
      );
      expect(providerTypes.any((final t) => t.contains('AudioEngine')), isTrue);
      expect(providerTypes.any((final t) => t.contains('Playlist')), isTrue);
    });

    test('disposes all services without error', () {
      // Use a fresh instance so the tearDown dispose doesn't double-dispose.
      final services = MockServices();
      expect(() => services.disposeAll(), returnsNormally);
    });
  });

  group('SongMatcher', () {
    test('matches song with correct properties', () {
      final song = createTestSong(
        name: 'Test',
        artist: 'Artist',
        album: 'Album',
        durationMs: 200000,
      );

      expect(
        song,
        isSong(
          name: 'Test',
          artist: 'Artist',
          album: 'Album',
          durationMs: 200000,
        ),
      );
      expect(song, isNot(isSong(name: 'Wrong')));
      expect(song, isNot(isSong(artist: 'Wrong')));
    });

    test('matches with partial properties', () {
      final song = createTestSong(name: 'Test', artist: 'Artist');

      expect(song, isSong(name: 'Test'));
      expect(song, isSong(artist: 'Artist'));
      expect(song, isNot(isSong(name: 'Other')));
    });
  });

  group('PlaylistMatcher', () {
    test('matches playlist with correct properties', () {
      final playlist = createTestPlaylist(name: 'Test', songIds: [1, 2, 3]);

      expect(playlist, isPlaylist(name: 'Test', songCount: 3));
      expect(playlist, isNot(isPlaylist(name: 'Wrong')));
      expect(playlist, isNot(isPlaylist(songCount: 5)));
    });

    test('matches with partial properties', () {
      final playlist = createTestPlaylist(name: 'Test', songIds: [1, 2]);

      expect(playlist, isPlaylist(name: 'Test'));
      expect(playlist, isPlaylist(songCount: 2));
    });
  });
}
