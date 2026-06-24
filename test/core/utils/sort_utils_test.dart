import 'package:flutter_test/flutter_test.dart';
import 'package:ga_song/core/audio/playlist_service.dart';
import 'package:ga_song/core/utils/sort_utils.dart';
import 'package:ga_song/models/song.dart';

void main() {
  group('SongSortUtils.sortModeFromInt', () {
    test('0 maps to SortMode.name', () {
      expect(SongSortUtils.sortModeFromInt(0), SortMode.name);
    });

    test('1 maps to SortMode.artist', () {
      expect(SongSortUtils.sortModeFromInt(1), SortMode.artist);
    });

    test('2 maps to SortMode.dateAdded', () {
      expect(SongSortUtils.sortModeFromInt(2), SortMode.dateAdded);
    });

    test('3 maps to SortMode.duration', () {
      expect(SongSortUtils.sortModeFromInt(3), SortMode.duration);
    });

    test('invalid value defaults to SortMode.name', () {
      expect(SongSortUtils.sortModeFromInt(-1), SortMode.name);
      expect(SongSortUtils.sortModeFromInt(99), SortMode.name);
    });
  });

  group('SongSortUtils.sort / sorted', () {
    final songs = [
      Song(name: 'Delta', sourcePath: 'd.mp3', artist: 'Zeta'),
      Song(name: 'Alpha', sourcePath: 'a.mp3', artist: 'Beta'),
      Song(name: 'Charlie', sourcePath: 'c.mp3', artist: 'Alpha'),
    ];

    test('sort by name ascending', () {
      final result = SongSortUtils.sorted(songs, SortMode.name);
      expect(result[0].name, 'Alpha');
      expect(result[1].name, 'Charlie');
      expect(result[2].name, 'Delta');
    });

    test('sort by name descending', () {
      final result = SongSortUtils.sorted(songs, SortMode.name, ascending: false);
      expect(result[0].name, 'Delta');
      expect(result[1].name, 'Charlie');
      expect(result[2].name, 'Alpha');
    });

    test('sort by artist ascending', () {
      final result = SongSortUtils.sorted(songs, SortMode.artist);
      expect(result[0].artist, 'Alpha');
      expect(result[1].artist, 'Beta');
      expect(result[2].artist, 'Zeta');
    });

    test('sort by artist descending', () {
      final result = SongSortUtils.sorted(songs, SortMode.artist, ascending: false);
      expect(result[0].artist, 'Zeta');
      expect(result[1].artist, 'Beta');
      expect(result[2].artist, 'Alpha');
    });

    test('sort does not modify original list', () {
      final original = List<Song>.from(songs);
      SongSortUtils.sorted(songs, SortMode.name);
      expect(songs.map((s) => s.name).toList(), ['Delta', 'Alpha', 'Charlie']);
      expect(original.map((s) => s.name).toList(), ['Delta', 'Alpha', 'Charlie']);
    });

    group('null / empty artist handling', () {
      test('empty artist sorts to end ascending', () {
        final songsWithNull = [
          Song(name: 'A', sourcePath: 'a.mp3', artist: 'Beta'),
          Song(name: 'B', sourcePath: 'b.mp3', artist: ''),  // empty artist
          Song(name: 'C', sourcePath: 'c.mp3', artist: 'Alpha'),
        ];
        final result = SongSortUtils.sorted(songsWithNull, SortMode.artist);
        // '' should be last — songs with no artist metadata should not
        // interrupt alphabetically ordered groups.
        expect(result[0].name, 'C');  // Alpha
        expect(result[1].name, 'A');  // Beta
        expect(result[2].name, 'B');  // '' (empty — pushed to end)
      });

      test('null artist sorts to end ascending', () {
        final songsWithNull = [
          Song(name: 'A', sourcePath: 'a.mp3', artist: 'Beta'),
          Song(name: 'B', sourcePath: 'b.mp3'),  // null artist
          Song(name: 'C', sourcePath: 'c.mp3', artist: 'Alpha'),
        ];
        final result = SongSortUtils.sorted(songsWithNull, SortMode.artist);
        expect(result[0].name, 'C');  // Alpha
        expect(result[1].name, 'A');  // Beta
        expect(result[2].name, 'B');  // null
      });
    });

    group('duration sorting', () {
      test('sort by duration ascending', () {
        final songsWithDuration = [
          Song(name: 'Long', sourcePath: 'l.mp3', durationMs: 300000),
          Song(name: 'Short', sourcePath: 's.mp3', durationMs: 120000),
          Song(name: 'Medium', sourcePath: 'm.mp3', durationMs: 200000),
        ];
        final result = SongSortUtils.sorted(songsWithDuration, SortMode.duration);
        expect(result[0].name, 'Short');
        expect(result[1].name, 'Medium');
        expect(result[2].name, 'Long');
      });

      test('null durationMs treated as 0 (sorts first ascending)', () {
        final songsMixed = [
          Song(name: 'Has Duration', sourcePath: 'a.mp3', durationMs: 200000),
          Song(name: 'No Duration', sourcePath: 'b.mp3'),
          Song(name: 'Short', sourcePath: 'c.mp3', durationMs: 60000),
        ];
        final result = SongSortUtils.sorted(songsMixed, SortMode.duration);
        expect(result[0].name, 'No Duration');
        expect(result[1].name, 'Short');
        expect(result[2].name, 'Has Duration');
      });
    });

    group('dateAdded sorting', () {
      test('sort by dateAdded ascending', () {
        final songsWithDates = [
          Song(name: 'Old', sourcePath: 'old.mp3', dateAdded: DateTime(2026, 1, 1)),
          Song(name: 'New', sourcePath: 'new.mp3', dateAdded: DateTime(2026, 5, 18)),
          Song(name: 'Mid', sourcePath: 'mid.mp3', dateAdded: DateTime(2026, 3, 10)),
        ];
        final result = SongSortUtils.sorted(songsWithDates, SortMode.dateAdded);
        expect(result[0].name, 'Old');
        expect(result[1].name, 'Mid');
        expect(result[2].name, 'New');
      });

      test('null dateAdded treated as epoch (sorts first ascending)', () {
        final songsMixedDates = [
          Song(name: 'Has Date', sourcePath: 'a.mp3', dateAdded: DateTime(2026, 5, 1)),
          Song(name: 'No Date', sourcePath: 'b.mp3'),
          Song(name: 'Old', sourcePath: 'c.mp3', dateAdded: DateTime(2026, 1, 1)),
        ];
        final result = SongSortUtils.sorted(songsMixedDates, SortMode.dateAdded);
        expect(result[0].name, 'No Date');
        expect(result[1].name, 'Old');
        expect(result[2].name, 'Has Date');
      });
    });
  });
}
