import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'tables/songs_table.dart';
import 'tables/playlists_table.dart';
import 'tables/playlist_songs_table.dart';
import 'tables/cover_art_cache_table.dart';
import 'tables/lyrics_cache_table.dart';

part 'app_database.g.dart';

/// Drift database for G.A Song app.
///
/// Provides type-safe database access with automatic migrations.
/// This coexists with the existing sqflite DatabaseService during migration.
@DriftDatabase(
  tables: [Songs, Playlists, PlaylistSongs, CoverArtCache, LyricsCache],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase({QueryExecutor? executor}) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
      await _createIndexes(m);
    },
    onUpgrade: (Migrator m, int from, int to) async {
      if (from < 2) {
        // v1 → v2: Add smart playlist & tag editor columns
        await m.addColumn(songs, songs.playCount);
        await m.addColumn(songs, songs.lastPlayed);
        await m.addColumn(songs, songs.genre);
        await m.addColumn(songs, songs.year);
      }
      if (from < 3) {
        // v2 → v3: Add playlist timestamps and cover art size
        await m.addColumn(playlists, playlists.createdAt);
        await m.addColumn(playlists, playlists.updatedAt);
        await m.addColumn(coverArtCache, coverArtCache.sizeBytes);
        await _createIndexes(m);
      }
    },
  );

  Future<void> _createIndexes(Migrator m) async {
    await m.database.customStatement(
      'CREATE INDEX IF NOT EXISTS idx_songs_artist ON songs(artist)',
    );
    await m.database.customStatement(
      'CREATE INDEX IF NOT EXISTS idx_songs_album ON songs(album)',
    );
    await m.database.customStatement(
      'CREATE INDEX IF NOT EXISTS idx_songs_play_count ON songs(play_count DESC)',
    );
    await m.database.customStatement(
      'CREATE INDEX IF NOT EXISTS idx_songs_date_added ON songs(date_added DESC)',
    );
    await m.database.customStatement(
      'CREATE INDEX IF NOT EXISTS idx_songs_name ON songs(name)',
    );
    await m.database.customStatement(
      'CREATE INDEX IF NOT EXISTS idx_cover_art_last_accessed ON cover_art_cache(last_accessed)',
    );
    await m.database.customStatement(
      'CREATE INDEX IF NOT EXISTS idx_lyrics_song_id ON lyrics_cache(song_id)',
    );
  }

  // ─── Song Operations ─────────────────────────────────────────────

  /// Get all songs ordered by date added (newest first).
  Future<List<SongEntry>> getAllSongs() =>
      (select(songs)..orderBy([(t) => OrderingTerm.desc(t.dateAdded)])).get();

  /// Watch all songs as a stream.
  Stream<List<SongEntry>> watchAllSongs() =>
      (select(songs)..orderBy([(t) => OrderingTerm.desc(t.dateAdded)])).watch();

  /// Get a song by ID.
  Future<SongEntry?> getSongById(int id) =>
      (select(songs)..where((t) => t.id.equals(id))).getSingleOrNull();

  /// Get songs by artist.
  Future<List<SongEntry>> getSongsByArtist(String artist) =>
      (select(songs)..where((t) => t.artist.equals(artist))).get();

  /// Get songs by album.
  Future<List<SongEntry>> getSongsByAlbum(String album) =>
      (select(songs)..where((t) => t.album.equals(album))).get();

  /// Search songs by name or artist.
  Future<List<SongEntry>> searchSongs(String query) => (select(
    songs,
  )..where((t) => t.name.like('%$query%') | t.artist.like('%$query%'))).get();

  /// Insert a new song.
  Future<int> insertSong(SongsCompanion song) => into(songs).insert(song);

  /// Update an existing song.
  Future<bool> updateSong(SongsCompanion song) => update(songs).replace(song);

  /// Delete a song by ID.
  Future<int> deleteSong(int id) =>
      (delete(songs)..where((t) => t.id.equals(id))).go();

  /// Increment play count and update last played timestamp.
  Future<void> incrementPlayCount(int id) async {
    final song = await getSongById(id);
    if (song != null) {
      await (update(songs)..where((t) => t.id.equals(id))).write(
        SongsCompanion(
          playCount: Value(song.playCount + 1),
          lastPlayed: Value(DateTime.now()),
        ),
      );
    }
  }

  /// Toggle favorite status for a song.
  Future<void> toggleFavorite(int id) async {
    final song = await getSongById(id);
    if (song != null) {
      await (update(songs)..where((t) => t.id.equals(id))).write(
        SongsCompanion(isFavorite: Value(!song.isFavorite)),
      );
    }
  }

  /// Get paginated songs with offset and limit.
  Future<List<SongEntry>> getSongsPaginated(int offset, int limit) =>
      (select(songs)
            ..orderBy([(t) => OrderingTerm.asc(t.name)])
            ..limit(limit, offset: offset))
          .get();

  // ─── Smart Playlist Queries ──────────────────────────────────────

  /// Get most played songs.
  Future<List<SongEntry>> getMostPlayed({int limit = 50}) =>
      (select(songs)
            ..where((t) => t.playCount.isBiggerThanValue(0))
            ..orderBy([(t) => OrderingTerm.desc(t.playCount)])
            ..limit(limit))
          .get();

  /// Get recently played songs.
  Future<List<SongEntry>> getRecentlyPlayed({int limit = 50}) =>
      (select(songs)
            ..where((t) => t.lastPlayed.isNotNull())
            ..orderBy([(t) => OrderingTerm.desc(t.lastPlayed)])
            ..limit(limit))
          .get();

  /// Get favorite songs.
  Future<List<SongEntry>> getFavorites() =>
      (select(songs)..where((t) => t.isFavorite.equals(true))).get();

  /// Get recently added songs.
  Future<List<SongEntry>> getRecentlyAdded({int limit = 50}) =>
      (select(songs)
            ..where((t) => t.dateAdded.isNotNull())
            ..orderBy([(t) => OrderingTerm.desc(t.dateAdded)])
            ..limit(limit))
          .get();

  /// Get discovery songs (least played).
  Future<List<SongEntry>> getDiscovery({int limit = 50}) =>
      (select(songs)
            ..orderBy([
              (t) => OrderingTerm.asc(t.playCount),
              (t) => OrderingTerm.desc(t.dateAdded),
            ])
            ..limit(limit))
          .get();

  // ─── Statistics ──────────────────────────────────────────────────

  /// Get total song count.
  Future<int> getSongCount() async {
    final count = await customSelect(
      'SELECT COUNT(*) as count FROM songs',
    ).getSingle();
    return count.data['count'] as int;
  }

  /// Get total duration in milliseconds.
  Future<int> getTotalDurationMs() async {
    final result = await customSelect(
      'SELECT COALESCE(SUM(duration_ms), 0) as total FROM songs WHERE duration_ms IS NOT NULL',
    ).getSingle();
    return result.data['total'] as int;
  }

  /// Get total play count.
  Future<int> getTotalPlayCount() async {
    final result = await customSelect(
      'SELECT COALESCE(SUM(play_count), 0) as total FROM songs',
    ).getSingle();
    return result.data['total'] as int;
  }

  /// Get library statistics.
  Future<Map<String, dynamic>> getLibraryStats() async {
    final totalSongs = await getSongCount();
    final totalDurationMs = await getTotalDurationMs();
    final totalPlayCount = await getTotalPlayCount();

    final genreCounts = await customSelect(
      'SELECT genre, COUNT(*) as count FROM songs WHERE genre IS NOT NULL GROUP BY genre ORDER BY count DESC',
    ).get();

    return {
      'totalSongs': totalSongs,
      'totalDurationMs': totalDurationMs,
      'totalPlayCount': totalPlayCount,
      'genreCounts': genreCounts.map((r) => r.data).toList(),
    };
  }

  // ─── Playlist Operations ─────────────────────────────────────────

  /// Get all playlists.
  Future<List<PlaylistEntry>> getAllPlaylists() => select(playlists).get();

  /// Watch all playlists as a stream.
  Stream<List<PlaylistEntry>> watchAllPlaylists() => select(playlists).watch();

  /// Create a new playlist.
  Future<int> createPlaylist(String name) => into(playlists).insert(
    PlaylistsCompanion(
      name: Value(name),
      createdAt: Value(DateTime.now()),
      updatedAt: Value(DateTime.now()),
    ),
  );

  /// Update a playlist name.
  Future<int> updatePlaylist(int id, String name) =>
      (update(playlists)..where((t) => t.id.equals(id))).write(
        PlaylistsCompanion(name: Value(name), updatedAt: Value(DateTime.now())),
      );

  /// Delete a playlist and its songs.
  Future<void> deletePlaylist(int id) async {
    await (delete(playlistSongs)..where((t) => t.playlistId.equals(id))).go();
    await (delete(playlists)..where((t) => t.id.equals(id))).go();
  }

  /// Add a song to a playlist.
  Future<void> addSongToPlaylist(int playlistId, int songId) async {
    // Get max position
    final maxPosQuery = await customSelect(
      'SELECT COALESCE(MAX(position), -1) as max_pos FROM playlist_songs WHERE playlist_id = ?',
      variables: [Variable.withInt(playlistId)],
    ).getSingle();
    final maxPos = maxPosQuery.data['max_pos'] as int;

    await into(playlistSongs).insert(
      PlaylistSongsCompanion(
        playlistId: Value(playlistId),
        songId: Value(songId),
        position: Value(maxPos + 1),
      ),
    );
  }

  /// Remove a song from a playlist.
  Future<void> removeSongFromPlaylist(int playlistId, int songId) =>
      (delete(playlistSongs)..where(
            (t) => t.playlistId.equals(playlistId) & t.songId.equals(songId),
          ))
          .go();

  /// Get songs in a playlist ordered by position.
  Future<List<SongEntry>> getPlaylistSongs(int playlistId) async {
    final query =
        select(
            playlistSongs,
          ).join([innerJoin(songs, songs.id.equalsExp(playlistSongs.songId))])
          ..where(playlistSongs.playlistId.equals(playlistId))
          ..orderBy([OrderingTerm.asc(playlistSongs.position)]);

    final results = await query.get();
    return results.map((row) => row.readTable(songs)).toList();
  }

  /// Check if a song is in a playlist.
  Future<bool> isSongInPlaylist(int playlistId, int songId) async {
    final result =
        await (select(playlistSongs)..where(
              (t) => t.playlistId.equals(playlistId) & t.songId.equals(songId),
            ))
            .get();
    return result.isNotEmpty;
  }

  // ─── Cover Art Cache Operations ──────────────────────────────────

  /// Get cover art bytes by file name.
  Future<Uint8List?> getCoverArt(String fileName) async {
    final entry = await (select(
      coverArtCache,
    )..where((t) => t.fileName.equals(fileName))).getSingleOrNull();

    if (entry != null) {
      // Update last accessed
      await (update(coverArtCache)..where((t) => t.id.equals(entry.id))).write(
        CoverArtCacheCompanion(lastAccessed: Value(DateTime.now())),
      );
      return entry.bytes;
    }
    return null;
  }

  /// Save cover art bytes.
  Future<void> saveCoverArt(String fileName, Uint8List bytes) async {
    await into(coverArtCache).insert(
      CoverArtCacheCompanion(
        fileName: Value(fileName),
        bytes: Value(bytes),
        lastAccessed: Value(DateTime.now()),
        sizeBytes: Value(bytes.length),
      ),
      mode: InsertMode.insertOrReplace,
    );
  }

  /// Evict old cover art entries to maintain cache size limit.
  Future<void> evictOldCoverArt(int maxEntries) async {
    final countResult = await customSelect(
      'SELECT COUNT(*) as count FROM cover_art_cache',
    ).getSingle();
    final currentCount = countResult.data['count'] as int;

    if (currentCount > maxEntries) {
      final toDelete = currentCount - maxEntries;
      await customStatement('''
        DELETE FROM cover_art_cache WHERE id IN (
          SELECT id FROM cover_art_cache 
          ORDER BY last_accessed ASC 
          LIMIT $toDelete
        )
      ''');
    }
  }

  /// Get total cover art cache size in bytes.
  Future<int> getCoverArtCacheSize() async {
    final result = await customSelect(
      'SELECT COALESCE(SUM(size_bytes), 0) as total FROM cover_art_cache',
    ).getSingle();
    return result.data['total'] as int;
  }

  /// Get cover art cache count.
  Future<int> getCoverArtCacheCount() async {
    final result = await customSelect(
      'SELECT COUNT(*) as count FROM cover_art_cache',
    ).getSingle();
    return result.data['count'] as int;
  }

  /// Clear all cover art cache.
  Future<void> clearCoverArtCache() async {
    await customStatement('DELETE FROM cover_art_cache');
  }

  // ─── Lyrics Cache Operations ─────────────────────────────────────

  /// Get cached lyrics for a song.
  Future<LyricsCacheEntry?> getLyrics(int songId) => (select(
    lyricsCache,
  )..where((t) => t.songId.equals(songId))).getSingleOrNull();

  /// Save lyrics for a song.
  Future<void> saveLyrics(
    int songId, {
    String? synced,
    String? plain,
    String source = 'lrclib',
  }) async {
    await into(lyricsCache).insert(
      LyricsCacheCompanion(
        songId: Value(songId),
        syncedLyrics: Value(synced),
        plainLyrics: Value(plain),
        source: Value(source),
        fetchedAt: Value(DateTime.now()),
      ),
      mode: InsertMode.insertOrReplace,
    );
  }

  /// Delete cached lyrics for a song.
  Future<void> deleteLyrics(int songId) =>
      (delete(lyricsCache)..where((t) => t.songId.equals(songId))).go();

  /// Clear all lyrics cache.
  Future<void> clearLyricsCache() async {
    await customStatement('DELETE FROM lyrics_cache');
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'ga_song_drift.db'));
    return NativeDatabase.createInBackground(file);
  });
}
