import '../cover_art_cache.dart';
import '../../core/database/app_database.dart';
import 'package:drift/drift.dart';

extension CoverArtCacheEntryMapper on CoverArtCacheEntry {
  CoverArtCache toCoverArtCache() => CoverArtCache(
    id: id,
    fileName: fileName,
    bytes: bytes.toList(),
    lastAccessed: lastAccessed,
  );
}

extension CoverArtCacheMapper on CoverArtCache {
  CoverArtCacheCompanion toCompanion() => CoverArtCacheCompanion(
    id: id != null ? Value(id!) : const Value.absent(),
    fileName: Value(fileName),
    bytes: Value(bytesAsUint8List),
    lastAccessed: Value(lastAccessed),
  );
}
