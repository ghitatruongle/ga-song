import 'dart:collection';

/// A Least Recently Used (LRU) cache implementation.
///
/// Evicts the least recently accessed item when the cache reaches [maxSize].
/// This is used for in-memory caching of cover art images.
class LRUCache<K, V> {
  /// Maximum number of items in the cache.
  final int maxSize;

  /// Internal storage using LinkedHashMap for O(1) access and ordering.
  final LinkedHashMap<K, V> _cache = LinkedHashMap();

  /// Creates an LRU cache with the given [maxSize].
  LRUCache({required this.maxSize}) : assert(maxSize > 0);

  /// Returns the value for [key] if it exists, or null otherwise.
  ///
  /// Accessing an item moves it to the end (most recently used).
  V? get(final K key) {
    if (_cache.containsKey(key)) {
      // Move to end (most recently used) — keep the entry even if the
      // stored value itself is null (generic V may be nullable).
      final value = _cache.remove(key);
      _cache[key] = value as V;
      return value;
    }
    return null;
  }

  /// Stores [value] with [key] in the cache.
  ///
  /// If the cache is full, evicts the least recently used item.
  /// If [key] already exists, updates the value and moves to end.
  void put(final K key, final V value) {
    if (_cache.containsKey(key)) {
      _cache.remove(key);
    } else if (_cache.length >= maxSize) {
      // Evict least recently used (first item)
      _cache.remove(_cache.keys.first);
    }
    _cache[key] = value;
  }

  /// Removes the entry for [key] if it exists.
  void remove(final K key) {
    _cache.remove(key);
  }

  /// Removes all entries from the cache.
  void clear() {
    _cache.clear();
  }

  /// Returns the number of items in the cache.
  int get length => _cache.length;

  /// Returns true if the cache is empty.
  bool get isEmpty => _cache.isEmpty;

  /// Returns true if the cache is not empty.
  bool get isNotEmpty => _cache.isNotEmpty;

  /// Returns true if the cache contains [key].
  bool containsKey(final K key) => _cache.containsKey(key);

  /// Returns all keys in the cache (ordered from least to most recently used).
  Iterable<K> get keys => _cache.keys;

  /// Returns all values in the cache (ordered from least to most recently used).
  Iterable<V> get values => _cache.values;

  @override
  String toString() => 'LRUCache(size=$length/$maxSize)';
}
