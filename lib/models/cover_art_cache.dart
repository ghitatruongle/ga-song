import 'dart:typed_data';

import 'package:isar/isar.dart';

part 'cover_art_cache.g.dart';

/// Persists cover art image bytes in Isar for fast disk cache across sessions.
///
/// After the first run, all cover art images are stored here so subsequent
/// launches avoid file I/O for built-in assets and local .png files.
/// Entries are LRU-evicted on write when the cache exceeds [maxDiskCacheEntries].
@Collection()
class CoverArtCache {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  String fileName = '';

  /// Raw image bytes stored as [List<int>] (Isar-compatible).
  /// Convert to/from [Uint8List] in repository code.
  List<int> bytes = [];

  /// Timestamp used for LRU eviction (oldest entries removed first).
  DateTime lastAccessed = DateTime.now();

  /// Maximum number of entries to keep in the disk cache.
  /// Desktop (60) mirrors the in-memory provider cache; Android (24) saves space.
  static int maxDiskCacheEntries(bool isAndroid) => isAndroid ? 24 : 60;
}
