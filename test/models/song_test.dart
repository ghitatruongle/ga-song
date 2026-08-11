import 'package:flutter_test/flutter_test.dart';
import 'package:ga_song/models/song.dart';

void main() {
  group('Song Model', () {
    test('duration getter returns Duration when durationMs is set', () {
      final song = Song(
        name: 'Test',
        sourcePath: 'test.mp3',
        durationMs: 180000,
      );
      expect(song.duration, const Duration(minutes: 3));
    });

    test('duration getter returns null when durationMs is null', () {
      final song = Song(name: 'Test', sourcePath: 'test.mp3');
      expect(song.durationMs, isNull);
      expect(song.duration, isNull);
    });

    test('fileName extracts filename from sourcePath', () {
      final song = Song(name: 'Test', sourcePath: '/path/to/my_song.mp3');
      expect(song.fileName, 'my_song.mp3');
    });

    test('fileName handles Windows backslash paths', () {
      final song = Song(name: 'Test', sourcePath: r'C:\Users\music\song.mp3');
      expect(song.fileName, 'song.mp3');
    });

    test('fileName handles nested forward slash paths', () {
      final song = Song(
        name: 'Test',
        sourcePath: 'assets/song/album/track.mp3',
      );
      expect(song.fileName, 'track.mp3');
    });

    test('dateAdded can be set and retrieved', () {
      final now = DateTime(2026, 5, 18);
      final song = Song(name: 'Test', sourcePath: 'test.mp3', dateAdded: now);
      expect(song.dateAdded, now);
    });

    test('dateAdded defaults to null', () {
      final song = Song(name: 'Test', sourcePath: 'test.mp3');
      expect(song.dateAdded, isNull);
    });

    test('peakDb defaults to -12.0', () {
      final song = Song(name: 'Test', sourcePath: 'test.mp3');
      expect(song.peakDb, -12.0);
    });

    test('isBuiltIn defaults to false', () {
      final song = Song(name: 'Test', sourcePath: 'test.mp3');
      expect(song.isBuiltIn, isFalse);
    });

    test('assetPath returns sourcePath', () {
      final song = Song(name: 'Test', sourcePath: 'assets/song/test.mp3');
      expect(song.assetPath, 'assets/song/test.mp3');
    });

    test('fromJson parses all fields correctly', () {
      final json = {
        'id': 42,
        'name': 'My Song',
        'artist': 'My Artist',
        'album': 'My Album',
        'durationMs': 240000,
        'peakDb': -8.5,
        'sourcePath': 'assets/song/my_song.mp3',
        'isBuiltIn': true,
        'isFavorite': true,
        'dateAdded': '2026-06-01T12:00:00.000',
      };
      final song = Song.fromJson(json);
      expect(song.id, 42);
      expect(song.name, 'My Song');
      expect(song.artist, 'My Artist');
      expect(song.album, 'My Album');
      expect(song.durationMs, 240000);
      expect(song.peakDb, -8.5);
      expect(song.sourcePath, 'assets/song/my_song.mp3');
      expect(song.isBuiltIn, isTrue);
      expect(song.isFavorite, isTrue);
      expect(song.dateAdded, DateTime(2026, 6, 1, 12));
    });

    test('fromJson handles missing fields gracefully', () {
      final json = <String, dynamic>{};
      final song = Song.fromJson(json);
      expect(song.id, isNull);
      expect(song.name, '');
      expect(song.artist, isNull);
      expect(song.album, isNull);
      expect(song.durationMs, isNull);
      expect(song.peakDb, -12.0);
      expect(song.sourcePath, '');
      expect(song.isBuiltIn, isFalse);
      expect(song.isFavorite, isFalse);
      expect(song.dateAdded, isNull);
    });

    test('fromJson handles integer isBuiltIn (SQLite format)', () {
      final json = {
        'isBuiltIn': 1,
        'isFavorite': 1,
        'name': 'Test',
        'sourcePath': 'test.mp3',
      };
      final song = Song.fromJson(json);
      expect(song.isBuiltIn, isTrue);
      expect(song.isFavorite, isTrue);
    });

    test('fromJson handles boolean isBuiltIn (JSON format)', () {
      final json = {
        'isBuiltIn': true,
        'isFavorite': false,
        'name': 'Test',
        'sourcePath': 'test.mp3',
      };
      final song = Song.fromJson(json);
      expect(song.isBuiltIn, isTrue);
      expect(song.isFavorite, isFalse);
    });

    test('fromJson handles invalid dateAdded gracefully', () {
      final json = {
        'name': 'Test',
        'sourcePath': 'test.mp3',
        'dateAdded': 'invalid',
      };
      final song = Song.fromJson(json);
      expect(song.dateAdded, isNull);
    });

    test('toJson serializes all fields', () {
      final song = Song(
        id: 1,
        name: 'Test',
        artist: 'Artist',
        album: 'Album',
        durationMs: 180000,
        peakDb: -10,
        sourcePath: 'test.mp3',
        isBuiltIn: true,
        dateAdded: DateTime(2026, 6),
      );
      final json = song.toJson();
      expect(json['id'], 1);
      expect(json['name'], 'Test');
      expect(json['artist'], 'Artist');
      expect(json['album'], 'Album');
      expect(json['durationMs'], 180000);
      expect(json['peakDb'], -10.0);
      expect(json['sourcePath'], 'test.mp3');
      expect(json['isBuiltIn'], true);
      expect(json['isFavorite'], false);
      expect(json['dateAdded'], '2026-06-01T00:00:00.000');
    });

    test('fromJson → toJson roundtrip preserves data', () {
      final original = Song(
        id: 5,
        name: 'Roundtrip',
        artist: 'Artist',
        album: 'Album',
        durationMs: 120000,
        peakDb: -6,
        sourcePath: 'assets/song/roundtrip.mp3',
        isBuiltIn: true,
        isFavorite: true,
        dateAdded: DateTime(2026, 3, 15, 14, 30),
      );
      final json = original.toJson();
      final restored = Song.fromJson(json);
      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.artist, original.artist);
      expect(restored.album, original.album);
      expect(restored.durationMs, original.durationMs);
      expect(restored.peakDb, original.peakDb);
      expect(restored.sourcePath, original.sourcePath);
      expect(restored.isBuiltIn, original.isBuiltIn);
      expect(restored.isFavorite, original.isFavorite);
      expect(restored.dateAdded, original.dateAdded);
    });

    test('equality is based on id', () {
      final a = Song(id: 1, name: 'A', sourcePath: 'a.mp3');
      final b = Song(id: 1, name: 'B', sourcePath: 'b.mp3');
      final c = Song(id: 2, name: 'A', sourcePath: 'a.mp3');
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });

    test('hashCode is based on id', () {
      final a = Song(id: 1, name: 'A', sourcePath: 'a.mp3');
      final b = Song(id: 1, name: 'B', sourcePath: 'b.mp3');
      expect(a.hashCode, b.hashCode);
    });

    test('identical instances are equal', () {
      final a = Song(id: 1, name: 'A', sourcePath: 'a.mp3');
      expect(a, equals(a));
    });

    test('peakDb can be negative and fractional', () {
      final song = Song(name: 'Test', sourcePath: 'test.mp3', peakDb: -14.7);
      expect(song.peakDb, -14.7);
    });

    test('fileName handles root path', () {
      final song = Song(name: 'Test', sourcePath: 'song.mp3');
      expect(song.fileName, 'song.mp3');
    });

    test('isFavorite defaults to false', () {
      final song = Song(name: 'Test', sourcePath: 'test.mp3');
      expect(song.isFavorite, isFalse);
    });
  });
}
