import 'package:drift/drift.dart';
import 'songs_table.dart';

/// Lyrics cache table for Drift ORM.
///
/// Caches synced and plain lyrics fetched from lrclib.net.
@DataClassName('LyricsCacheEntry')
class LyricsCache extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get songId => integer().references(Songs, #id)();
  TextColumn get syncedLyrics => text().nullable()();
  TextColumn get plainLyrics => text().nullable()();
  TextColumn get source => text().withDefault(const Constant('lrclib'))();
  DateTimeColumn get fetchedAt => dateTime()();

  @override
  List<Set<Column>> get uniqueKeys => [{songId}];
}
