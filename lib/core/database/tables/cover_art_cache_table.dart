import 'package:drift/drift.dart';

/// Cover art cache table for Drift ORM.
///
/// Stores cover art images as BLOBs with LRU eviction support.
@DataClassName('CoverArtCacheEntry')
class CoverArtCache extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get fileName => text().unique()();
  BlobColumn get bytes => blob()();
  DateTimeColumn get lastAccessed => dateTime()();
  IntColumn get sizeBytes => integer().withDefault(const Constant(0))();
}
