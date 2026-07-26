import 'dart:io';
import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:path/path.dart' as p;
import 'package:drift/drift.dart';
import '../../logging/app_logger.dart';
import '../app_database.dart';
import '../../../models/song.dart';
import '../../../models/cover_art_cache.dart';

class MigrationService {
  final AppDatabase newDb;

  MigrationService(this.newDb);

  Future<void> migrateFromSqflite() async {
    final sqfliteDbPath = await sqflite.getDatabasesPath();
    final dbFilePath = p.join(sqfliteDbPath, 'ga_song.db');

    final file = File(dbFilePath);
    if (!await file.exists()) {
      AppLogger.i(
        'Migration',
        'No old sqflite database found. Skipping migration.',
      );
      return;
    }

    AppLogger.i(
      'Migration',
      'Found legacy sqflite database. Starting migration to Drift...',
    );

    // Open legacy DB (read-only if possible, or just normal open)
    final oldDb = await sqflite.openDatabase(dbFilePath, version: 2);

    try {
      await _migrateSongs(oldDb);
      await _migratePlaylists(oldDb);
      await _migrateCoverArtCache(oldDb);
      AppLogger.i('Migration', 'Migration to Drift completed successfully.');

      // We will not delete the old DB right away to be safe, just rename it
      await oldDb.close();
      try {
        await file.rename(p.join(sqfliteDbPath, 'ga_song_migrated.db.bak'));
      } catch (e) {
        AppLogger.w(
          'Migration',
          'Failed to rename old DB file after migration: $e',
        );
      }
    } catch (e, st) {
      AppLogger.e(
        'Migration',
        'Error during migration: $e',
        error: e,
        stack: st,
      );
    } finally {
      if (oldDb.isOpen) {
        await oldDb.close();
      }
    }
  }

  Future<void> _migrateSongs(sqflite.Database oldDb) async {
    final List<Map<String, dynamic>> maps = await oldDb.query('songs');
    if (maps.isEmpty) return;

    final songs = <Song>[];
    for (final map in maps) {
      try {
        songs.add(Song.fromJson(map));
      } catch (e, st) {
        AppLogger.w(
          'Migration',
          'Failed to parse song: $e',
          error: e,
          stack: st,
        );
      }
    }

    await newDb.batch((batch) {
      for (final song in songs) {
        batch.insert(
          newDb.songs,
          SongsCompanion(
            id: Value(song.id!),
            name: Value(song.name),
            artist: Value(song.artist),
            album: Value(song.album),
            durationMs: Value(song.durationMs),
            peakDb: Value(song.peakDb),
            sourcePath: Value(song.sourcePath),
            isBuiltIn: Value(song.isBuiltIn),
            isFavorite: Value(song.isFavorite),
            dateAdded: Value(song.dateAdded),
            playCount: Value(song.playCount),
            lastPlayed: Value(song.lastPlayed),
            genre: Value(song.genre),
            year: Value(song.year),
          ),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
    AppLogger.i('Migration', 'Migrated ${songs.length} songs.');
  }

  Future<void> _migratePlaylists(sqflite.Database oldDb) async {
    // Migrate playlists
    final List<Map<String, dynamic>> playlistMaps = await oldDb.query(
      'playlists',
    );

    await newDb.batch((batch) {
      for (final map in playlistMaps) {
        batch.insert(
          newDb.playlists,
          PlaylistsCompanion(
            id: Value(map['id'] as int),
            name: Value(map['name'] as String),
            createdAt: Value(
              DateTime.tryParse(map['createdAt']?.toString() ?? '') ??
                  DateTime.now(),
            ),
            updatedAt: Value(
              DateTime.tryParse(map['updatedAt']?.toString() ?? '') ??
                  DateTime.now(),
            ),
          ),
          mode: InsertMode.insertOrReplace,
        );
      }
    });

    // Migrate playlist_songs (junction table)
    final List<Map<String, dynamic>> junctionMaps = await oldDb.query(
      'playlist_songs',
    );
    await newDb.batch((batch) {
      for (final map in junctionMaps) {
        batch.insert(
          newDb.playlistSongs,
          PlaylistSongsCompanion(
            playlistId: Value(map['playlistId'] as int),
            songId: Value(map['songId'] as int),
            position: Value(map['position'] as int),
          ),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
    AppLogger.i(
      'Migration',
      'Migrated ${playlistMaps.length} playlists and ${junctionMaps.length} playlist entries.',
    );
  }

  Future<void> _migrateCoverArtCache(sqflite.Database oldDb) async {
    final List<Map<String, dynamic>> maps = await oldDb.query(
      'cover_art_cache',
    );
    if (maps.isEmpty) return;

    final caches = <CoverArtCache>[];
    for (final map in maps) {
      try {
        caches.add(CoverArtCache.fromJson(map));
      } catch (e, st) {
        AppLogger.w(
          'Migration',
          'Failed to parse cover art cache: $e',
          error: e,
          stack: st,
        );
      }
    }

    await newDb.batch((batch) {
      for (final cache in caches) {
        batch.insert(
          newDb.coverArtCache,
          CoverArtCacheCompanion(
            fileName: Value(cache.fileName),
            bytes: Value(cache.bytesAsUint8List),
            lastAccessed: Value(cache.lastAccessed),
          ),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
    AppLogger.i(
      'Migration',
      'Migrated ${caches.length} cover art cache entries.',
    );
  }
}
