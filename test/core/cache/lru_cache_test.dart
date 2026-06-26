import 'package:flutter_test/flutter_test.dart';
import 'package:ga_song/core/cache/lru_cache.dart';

void main() {
  group('LRUCache', () {
    late LRUCache<String, int> cache;

    setUp(() {
      cache = LRUCache(maxSize: 3);
    });

    test('get returns null for non-existent key', () {
      expect(cache.get('key'), isNull);
    });

    test('put and get works correctly', () {
      cache.put('key', 1);
      expect(cache.get('key'), equals(1));
    });

    test('put overwrites existing key', () {
      cache.put('key', 1);
      cache.put('key', 2);
      expect(cache.get('key'), equals(2));
      expect(cache.length, equals(1));
    });

    test('evicts least recently used when full', () {
      cache.put('a', 1);
      cache.put('b', 2);
      cache.put('c', 3);
      cache.put('d', 4); // should evict 'a'

      expect(cache.get('a'), isNull);
      expect(cache.get('b'), equals(2));
      expect(cache.get('c'), equals(3));
      expect(cache.get('d'), equals(4));
    });

    test('get moves item to end', () {
      cache.put('a', 1);
      cache.put('b', 2);
      cache.put('c', 3);

      cache.get('a'); // move 'a' to end
      cache.put('d', 4); // should evict 'b'

      expect(cache.get('a'), equals(1));
      expect(cache.get('b'), isNull);
      expect(cache.get('c'), equals(3));
      expect(cache.get('d'), equals(4));
    });

    test('remove works correctly', () {
      cache.put('key', 1);
      cache.remove('key');
      expect(cache.get('key'), isNull);
      expect(cache.length, equals(0));
    });

    test('clear removes all items', () {
      cache.put('a', 1);
      cache.put('b', 2);
      cache.clear();

      expect(cache.get('a'), isNull);
      expect(cache.get('b'), isNull);
      expect(cache.length, equals(0));
    });

    test('isEmpty returns true when empty', () {
      expect(cache.isEmpty, isTrue);
      expect(cache.isNotEmpty, isFalse);
    });

    test('isNotEmpty returns false when has items', () {
      cache.put('key', 1);
      expect(cache.isEmpty, isFalse);
      expect(cache.isNotEmpty, isTrue);
    });

    test('containsKey works correctly', () {
      cache.put('key', 1);
      expect(cache.containsKey('key'), isTrue);
      expect(cache.containsKey('other'), isFalse);
    });

    test('keys returns all keys', () {
      cache.put('a', 1);
      cache.put('b', 2);
      cache.put('c', 3);

      expect(cache.keys.toList(), equals(['a', 'b', 'c']));
    });

    test('values returns all values', () {
      cache.put('a', 1);
      cache.put('b', 2);
      cache.put('c', 3);

      expect(cache.values.toList(), equals([1, 2, 3]));
    });

    test('length returns correct count', () {
      expect(cache.length, equals(0));

      cache.put('a', 1);
      expect(cache.length, equals(1));

      cache.put('b', 2);
      expect(cache.length, equals(2));

      cache.put('c', 3);
      expect(cache.length, equals(3));

      cache.put('d', 4); // evicts 'a'
      expect(cache.length, equals(3));
    });

    test('toString returns descriptive string', () {
      cache.put('a', 1);
      final str = cache.toString();

      expect(str, contains('LRUCache'));
      expect(str, contains('1'));
      expect(str, contains('3'));
    });
  });
}
