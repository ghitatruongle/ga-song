import 'package:drift/drift.dart';

/// Songs table definition for Drift ORM.
///
/// Matches the existing sqflite schema for backward compatibility.
@DataClassName('SongEntry')
class Songs extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 255)();
  TextColumn get artist => text().nullable().withLength(max: 255)();
  TextColumn get album => text().nullable().withLength(max: 255)();
  IntColumn get durationMs => integer().nullable()();
  RealColumn get peakDb => real().withDefault(const Constant(-12.0))();
  TextColumn get sourcePath => text()();
  BoolColumn get isBuiltIn => boolean().withDefault(const Constant(false))();
  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();
  DateTimeColumn get dateAdded => dateTime().nullable()();
  IntColumn get playCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastPlayed => dateTime().nullable()();
  TextColumn get genre => text().nullable().withLength(max: 100)();
  IntColumn get year => integer().nullable()();
}
