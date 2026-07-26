import 'package:flutter_test/flutter_test.dart';
import 'package:ga_song/models/cover_art_cache.dart';

void main() {
  group('CoverArtCache Model', () {
    test('constructor sets defaults correctly', () {
      final cache = CoverArtCache();
      expect(cache.id, isNull);
      expect(cache.fileName, '');
      expect(cache.bytes, isEmpty);
      expect(cache.lastAccessed, isNotNull);
    });

    test('constructor sets all fields', () {
      final now = DateTime(2026, 6, 15);
      final cache = CoverArtCache(
        id: 1,
        fileName: 'song.mp3',
        bytes: [0x89, 0x50, 0x4E, 0x47],
        lastAccessed: now,
      );
      expect(cache.id, 1);
      expect(cache.fileName, 'song.mp3');
      expect(cache.bytes, [0x89, 0x50, 0x4E, 0x47]);
      expect(cache.lastAccessed, now);
    });

    test('bytesAsUint8List converts bytes correctly', () {
      final cache = CoverArtCache(bytes: [0x01, 0x02, 0x03]);
      final uint8List = cache.bytesAsUint8List;
      expect(uint8List.length, 3);
      expect(uint8List[0], 0x01);
      expect(uint8List[1], 0x02);
      expect(uint8List[2], 0x03);
    });

    test('bytesAsUint8List returns empty for empty bytes', () {
      final cache = CoverArtCache(bytes: []);
      expect(cache.bytesAsUint8List.length, 0);
    });

    test('maxDiskCacheEntries returns correct values', () {
      expect(CoverArtCache.maxDiskCacheEntries(true), 24); // Android
      expect(CoverArtCache.maxDiskCacheEntries(false), 60); // Desktop
    });

    test('fromJson parses all fields', () {
      final json = {
        'id': 10,
        'fileName': 'cover.png',
        'bytes': [1, 2, 3],
        'lastAccessed': '2026-06-15T10:30:00.000',
      };
      final cache = CoverArtCache.fromJson(json);
      expect(cache.id, 10);
      expect(cache.fileName, 'cover.png');
      expect(cache.bytes, [1, 2, 3]);
      expect(cache.lastAccessed, DateTime(2026, 6, 15, 10, 30));
    });

    test('fromJson handles missing fields', () {
      final json = <String, dynamic>{};
      final cache = CoverArtCache.fromJson(json);
      expect(cache.id, isNull);
      expect(cache.fileName, '');
      expect(cache.bytes, isEmpty);
      expect(cache.lastAccessed, isNotNull); // defaults to now
    });

    test('fromJson handles null lastAccessed', () {
      final json = {'lastAccessed': null};
      final cache = CoverArtCache.fromJson(json);
      expect(cache.lastAccessed, isNotNull);
    });

    test('toJson serializes all fields', () {
      final now = DateTime(2026, 6, 15, 10, 30);
      final cache = CoverArtCache(
        id: 5,
        fileName: 'art.jpg',
        bytes: [10, 20],
        lastAccessed: now,
      );
      final json = cache.toJson();
      expect(json['id'], 5);
      expect(json['fileName'], 'art.jpg');
      expect(json['bytes'], [10, 20]);
      expect(json['lastAccessed'], now.toIso8601String());
    });

    test('fromJson → toJson roundtrip preserves data', () {
      final now = DateTime(2026, 6, 15, 10, 30);
      final original = CoverArtCache(
        id: 3,
        fileName: 'test.png',
        bytes: [0xFF, 0xD8, 0xFF],
        lastAccessed: now,
      );
      final json = original.toJson();
      final restored = CoverArtCache.fromJson(json);
      expect(restored.id, original.id);
      expect(restored.fileName, original.fileName);
      expect(restored.bytes, original.bytes);
      expect(restored.lastAccessed, original.lastAccessed);
    });
  });
}
