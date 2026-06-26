import 'package:flutter_test/flutter_test.dart';
import 'package:ga_song/models/playlist.dart';

void main() {
  group('Playlist Model', () {
    test('constructor sets required fields', () {
      final playlist = Playlist(name: 'My Playlist');
      expect(playlist.name, 'My Playlist');
      expect(playlist.songIds, isEmpty);
      expect(playlist.id, isNull);
    });

    test('constructor sets optional fields', () {
      final playlist = Playlist(id: 1, name: 'Test', songIds: [1, 2, 3]);
      expect(playlist.id, 1);
      expect(playlist.songIds, [1, 2, 3]);
    });

    test('fromJson parses all fields correctly', () {
      final json = {
        'id': 5,
        'name': 'Favorites',
        'songIds': [10, 20, 30],
      };
      final playlist = Playlist.fromJson(json);
      expect(playlist.id, 5);
      expect(playlist.name, 'Favorites');
      expect(playlist.songIds, [10, 20, 30]);
    });

    test('fromJson handles missing optional fields', () {
      final json = <String, dynamic>{};
      final playlist = Playlist.fromJson(json);
      expect(playlist.id, isNull);
      expect(playlist.name, '');
      expect(playlist.songIds, isEmpty);
    });

    test('fromJson handles null name gracefully', () {
      final json = {'name': null, 'songIds': null};
      final playlist = Playlist.fromJson(json);
      expect(playlist.name, '');
      expect(playlist.songIds, isEmpty);
    });

    test('toJson serializes all fields', () {
      final playlist = Playlist(id: 3, name: 'Workout', songIds: [1, 2]);
      final json = playlist.toJson();
      expect(json['id'], 3);
      expect(json['name'], 'Workout');
      expect(json['songIds'], [1, 2]);
    });

    test('fromJson → toJson roundtrip preserves data', () {
      final original = Playlist(id: 7, name: 'Chill', songIds: [5, 10, 15]);
      final json = original.toJson();
      final restored = Playlist.fromJson(json);
      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.songIds, original.songIds);
    });

    test('equality is based on id', () {
      final a = Playlist(id: 1, name: 'A', songIds: [1]);
      final b = Playlist(id: 1, name: 'B', songIds: [2]);
      final c = Playlist(id: 2, name: 'A', songIds: [1]);
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });

    test('hashCode is based on id', () {
      final a = Playlist(id: 1, name: 'A');
      final b = Playlist(id: 1, name: 'B');
      expect(a.hashCode, b.hashCode);
    });

    test('identical instances are equal', () {
      final a = Playlist(id: 1, name: 'A');
      expect(a, equals(a));
    });

    test('songIds can be mutated after construction', () {
      final playlist = Playlist(name: 'Test', songIds: [1, 2]);
      playlist.songIds.add(3);
      expect(playlist.songIds, [1, 2, 3]);
    });
  });
}
