import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import '../../models/song.dart';
import '../../models/playlist.dart';
import '../../models/cover_art_cache.dart';
import '../utils/result.dart';
import '../exceptions/app_exception.dart' as app_exc;
import '../logging/app_logger.dart';

class DatabaseService {
  late Database _db;

  late final _songsController = StreamController<List<Song>>.broadcast(
    onListen: () {
      _notifySongsChanged();
    },
  );
  Stream<List<Song>> get songsStream => _songsController.stream;

  Future<void> init() async {
    final dbPath = await getDatabasesPath();
    final dbFilePath = p.join(dbPath, 'ga_song.db');

    _db = await openDatabase(
      dbFilePath,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );

    await _ensureBuiltInSeeded();

    _notifySongsChanged();
  }

  /// Checks that all built-in songs from `assets/song/songs.json` exist in
  /// the database.  If any are missing (e.g. due to a partial seed or a
  /// corrupt DB), deletes ALL built-in rows and re-seeds from scratch.
  Future<void> _ensureBuiltInSeeded() async {
    try {
      final jsonString = await rootBundle.loadString('assets/song/songs.json');
      if (jsonString.trim().isEmpty) return;

      final decoded = json.decode(jsonString);
      if (decoded is! List) return;

      final expectedFileNames = <String>{};
      for (final item in decoded) {
        if (item is Map<String, dynamic>) {
          final fileName = item['fileName'] as String? ?? '';
          if (fileName.isNotEmpty) {
            expectedFileNames.add('assets/song/$fileName');
          }
        }
      }
      if (expectedFileNames.isEmpty) return;

      // Query actual built-in sourcePaths from DB.
      final rows = await _db.query(
        'songs',
        columns: ['sourcePath'],
        where: 'isBuiltIn = 1',
      );
      final actualPaths = rows.map((r) => r['sourcePath'] as String).toSet();

      // Fast path: counts match → nothing to do.
      if (actualPaths.length == expectedFileNames.length &&
          actualPaths.containsAll(expectedFileNames)) {
        return;
      }

      AppLogger.i(
        'database.service',
        'Built-in songs mismatch (expected=${expectedFileNames.length}, '
        'actual=${actualPaths.length}); re-seeding…',
      );

      // Delete stale built-in rows and re-seed.
      await _db.delete('songs', where: 'isBuiltIn = 1');
      await _seedBuiltInSongs(expectedFileNames);
    } catch (e, stack) {
      AppLogger.e('database.service', 'ensureBuiltInSeeded failed',
          error: e, stack: stack);
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE songs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        artist TEXT,
        album TEXT,
        durationMs INTEGER,
        peakDb REAL DEFAULT -12.0,
        sourcePath TEXT NOT NULL,
        isBuiltIn INTEGER DEFAULT 0,
        isFavorite INTEGER DEFAULT 0,
        dateAdded TEXT,
        playCount INTEGER DEFAULT 0,
        lastPlayed TEXT,
        genre TEXT,
        year INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE playlists (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE playlist_songs (
        playlist_id INTEGER NOT NULL,
        song_id INTEGER NOT NULL,
        position INTEGER NOT NULL DEFAULT 0,
        PRIMARY KEY (playlist_id, song_id)
      )
    ''');

    await db.execute('''
      CREATE TABLE cover_art_cache (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        fileName TEXT NOT NULL UNIQUE,
        bytes BLOB NOT NULL,
        lastAccessed TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE lyrics_cache (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        songId INTEGER NOT NULL,
        syncedLyrics TEXT,
        plainLyrics TEXT,
        source TEXT NOT NULL DEFAULT 'lrclib',
        fetchedAt TEXT NOT NULL,
        FOREIGN KEY (songId) REFERENCES songs(id) ON DELETE CASCADE,
        UNIQUE(songId)
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // v1 → v2: Add smart playlist & tag editor columns
      await db.execute('ALTER TABLE songs ADD COLUMN playCount INTEGER DEFAULT 0');
      await db.execute('ALTER TABLE songs ADD COLUMN lastPlayed TEXT');
      await db.execute('ALTER TABLE songs ADD COLUMN genre TEXT');
      await db.execute('ALTER TABLE songs ADD COLUMN year INTEGER');

      // Add lyrics cache table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS lyrics_cache (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          songId INTEGER NOT NULL,
          syncedLyrics TEXT,
          plainLyrics TEXT,
          source TEXT NOT NULL DEFAULT 'lrclib',
          fetchedAt TEXT NOT NULL,
          FOREIGN KEY (songId) REFERENCES songs(id) ON DELETE CASCADE,
          UNIQUE(songId)
        )
      ''');
    }
  }

  // ─── Songs ────────────────────────────────────────────────────────────────

  Future<List<Song>> getAllSongs() async {
    final maps = await _db.query('songs', orderBy: 'dateAdded DESC');
    return maps.map(_songFromMap).toList();
  }

  /// Result-returning variant of [getAllSongs].
  ///
  /// Wraps any error in a [Failure] with the underlying [AppException]
  /// accessible via [Failure.exception]. The legacy [getAllSongs] is kept
  /// for backward compatibility.
  Future<Result<List<Song>>> querySongs() async {
    try {
      final songs = await getAllSongs();
      return Success(songs);
    } on app_exc.AppException catch (e, st) {
      AppLogger.e('database.service', 'querySongs failed', error: e, stack: st);
      return Failure(e.message, st, e);
    } catch (e, st) {
      final ex = app_exc.DatabaseException('querySongs failed: $e');
      AppLogger.e(
        'database.service',
        'querySongs unexpected error',
        error: e,
        stack: st,
      );
      return Failure(ex.message, st, ex);
    }
  }

  Future<int> getSongCount() async {
    return Sqflite.firstIntValue(
      await _db.rawQuery('SELECT COUNT(*) FROM songs'),
    ) ?? 0;
  }

  Future<void> putSong(Song song) async {
    final map = _songToMap(song);
    if (song.id != null) {
      await _db.update('songs', map, where: 'id = ?', whereArgs: [song.id]);
    } else {
      song.id = await _db.insert('songs', map);
    }
    _notifySongsChanged();
  }

  Future<void> putAllSongs(List<Song> songs) async {
    final batch = _db.batch();
    for (final song in songs) {
      batch.insert('songs', _songToMap(song));
    }
    await batch.commit(noResult: true);
    _notifySongsChanged();
  }

  Future<void> deleteSong(int id) async {
    await _db.delete('songs', where: 'id = ?', whereArgs: [id]);
    await _db.delete('playlist_songs', where: 'song_id = ?', whereArgs: [id]);
    _notifySongsChanged();
  }

  // ─── Smart Playlist Queries ──────────────────────────────────────────────

  /// Get most played songs (playCount > 0, ordered by playCount DESC)
  Future<List<Song>> getMostPlayedSongs({int limit = 50}) async {
    final maps = await _db.query(
      'songs',
      where: 'playCount > 0',
      orderBy: 'playCount DESC',
      limit: limit,
    );
    return maps.map(_songFromMap).toList();
  }

  /// Get recently played songs (lastPlayed IS NOT NULL, ordered by lastPlayed DESC)
  Future<List<Song>> getRecentlyPlayedSongs({int limit = 50}) async {
    final maps = await _db.query(
      'songs',
      where: 'lastPlayed IS NOT NULL',
      orderBy: 'lastPlayed DESC',
      limit: limit,
    );
    return maps.map(_songFromMap).toList();
  }

  /// Get favorite songs
  Future<List<Song>> getFavoriteSongs() async {
    final maps = await _db.query(
      'songs',
      where: 'isFavorite = 1',
      orderBy: 'name ASC',
    );
    return maps.map(_songFromMap).toList();
  }

  /// Get recently added songs
  Future<List<Song>> getRecentlyAddedSongs({int limit = 50}) async {
    final maps = await _db.query(
      'songs',
      orderBy: 'dateAdded DESC',
      limit: limit,
    );
    return maps.map(_songFromMap).toList();
  }

  /// Get discovery songs (least played, for discovering new music)
  Future<List<Song>> getDiscoverySongs({int limit = 50}) async {
    final maps = await _db.query(
      'songs',
      orderBy: 'playCount ASC, dateAdded DESC',
      limit: limit,
    );
    return maps.map(_songFromMap).toList();
  }

  /// Increment play count and update lastPlayed for a song
  Future<void> incrementPlayCount(int songId) async {
    await _db.rawUpdate(
      'UPDATE songs SET playCount = playCount + 1, lastPlayed = ? WHERE id = ?',
      [DateTime.now().toIso8601String(), songId],
    );
    _notifySongsChanged();
  }

  /// Get library statistics
  Future<Map<String, dynamic>> getLibraryStats() async {
    final totalSongs = Sqflite.firstIntValue(
      await _db.rawQuery('SELECT COUNT(*) FROM songs'),
    ) ?? 0;

    final totalDurationMs = Sqflite.firstIntValue(
      await _db.rawQuery('SELECT SUM(durationMs) FROM songs WHERE durationMs IS NOT NULL'),
    ) ?? 0;

    final totalPlayCount = Sqflite.firstIntValue(
      await _db.rawQuery('SELECT SUM(playCount) FROM songs'),
    ) ?? 0;

    final genreCounts = await _db.rawQuery(
      'SELECT genre, COUNT(*) as count FROM songs WHERE genre IS NOT NULL GROUP BY genre ORDER BY count DESC',
    );

    return {
      'totalSongs': totalSongs,
      'totalDurationMs': totalDurationMs,
      'totalPlayCount': totalPlayCount,
      'genreCounts': genreCounts,
    };
  }

  // ─── Lyrics Cache ──────────────────────────────────────────────────────

  /// Get cached lyrics for a song
  Future<Map<String, String>?> getCachedLyrics(int songId) async {
    final maps = await _db.query(
      'lyrics_cache',
      where: 'songId = ?',
      whereArgs: [songId],
    );
    if (maps.isEmpty) return null;
    
    final map = maps.first;
    return {
      'syncedLyrics': map['syncedLyrics'] as String? ?? '',
      'plainLyrics': map['plainLyrics'] as String? ?? '',
      'source': map['source'] as String? ?? 'lrclib',
    };
  }

  /// Cache lyrics for a song
  Future<void> cacheLyrics({
    required int songId,
    String? syncedLyrics,
    String? plainLyrics,
    String source = 'lrclib',
  }) async {
    await _db.insert(
      'lyrics_cache',
      {
        'songId': songId,
        'syncedLyrics': syncedLyrics,
        'plainLyrics': plainLyrics,
        'source': source,
        'fetchedAt': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Delete cached lyrics for a song
  Future<void> deleteCachedLyrics(int songId) async {
    await _db.delete('lyrics_cache', where: 'songId = ?', whereArgs: [songId]);
  }

  void _notifySongsChanged() async {
    try {
      final songs = await getAllSongs();
      _songsController.add(songs);
    } catch (e) {
      AppLogger.w('database.service', 'notify songs changed failed', error: e);
    }
  }

  Map<String, dynamic> _songToMap(Song song) {
    return <String, dynamic>{
      'name': song.name,
      'artist': song.artist,
      'album': song.album,
      'durationMs': song.durationMs,
      'peakDb': song.peakDb,
      'sourcePath': song.sourcePath,
      'isBuiltIn': song.isBuiltIn ? 1 : 0,
      'isFavorite': song.isFavorite ? 1 : 0,
      'dateAdded': song.dateAdded?.toIso8601String(),
      'playCount': song.playCount,
      'lastPlayed': song.lastPlayed?.toIso8601String(),
      'genre': song.genre,
      'year': song.year,
    };
  }

  Song _songFromMap(Map<String, dynamic> map) => Song(
    id: map['id'] as int?,
    name: map['name'] as String,
    artist: map['artist'] as String?,
    album: map['album'] as String?,
    durationMs: map['durationMs'] as int?,
    peakDb: (map['peakDb'] as num?)?.toDouble() ?? -12.0,
    sourcePath: map['sourcePath'] as String,
    isBuiltIn: map['isBuiltIn'] == 1,
    isFavorite: map['isFavorite'] == 1,
    dateAdded: map['dateAdded'] != null
        ? DateTime.tryParse(map['dateAdded'] as String)
        : null,
    playCount: (map['playCount'] as int?) ?? 0,
    lastPlayed: map['lastPlayed'] != null
        ? DateTime.tryParse(map['lastPlayed'] as String)
        : null,
    genre: map['genre'] as String?,
    year: map['year'] as int?,
  );

  // ─── Playlists ────────────────────────────────────────────────────────────

  Future<List<Playlist>> getAllPlaylists() async {
    final playlistMaps = await _db.query('playlists');
    final playlists = <Playlist>[];
    for (final map in playlistMaps) {
      final id = map['id'] as int;
      final songIdMaps = await _db.query(
        'playlist_songs',
        columns: ['song_id'],
        where: 'playlist_id = ?',
        whereArgs: [id],
        orderBy: 'position',
      );
      final songIds = songIdMaps.map((m) => m['song_id'] as int).toList();
      playlists.add(Playlist(
        id: id,
        name: map['name'] as String,
        songIds: songIds,
      ));
    }
    return playlists;
  }

  Future<void> putPlaylist(Playlist playlist) async {
    if (playlist.id != null) {
      await _db.update('playlists', {'name': playlist.name},
          where: 'id = ?', whereArgs: [playlist.id]);
      await _db.delete('playlist_songs',
          where: 'playlist_id = ?', whereArgs: [playlist.id]);
      await _insertPlaylistSongs(playlist.id!, playlist.songIds);
    } else {
      playlist.id = await _db.insert('playlists', {'name': playlist.name});
      await _insertPlaylistSongs(playlist.id!, playlist.songIds);
    }
  }

  Future<void> _insertPlaylistSongs(int playlistId, List<int> songIds) async {
    final batch = _db.batch();
    for (int i = 0; i < songIds.length; i++) {
      batch.insert('playlist_songs', {
        'playlist_id': playlistId,
        'song_id': songIds[i],
        'position': i,
      });
    }
    await batch.commit(noResult: true);
  }

  Future<void> deletePlaylist(int id) async {
    await _db.delete('playlist_songs', where: 'playlist_id = ?', whereArgs: [id]);
    await _db.delete('playlists', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> addSongToPlaylist(int playlistId, int songId) async {
    final existing = await _db.query('playlist_songs',
        where: 'playlist_id = ? AND song_id = ?',
        whereArgs: [playlistId, songId]);
    if (existing.isNotEmpty) return;

    final maxPos = Sqflite.firstIntValue(await _db.rawQuery(
      'SELECT MAX(position) FROM playlist_songs WHERE playlist_id = ?',
      [playlistId],
    )) ?? -1;

    await _db.insert('playlist_songs', {
      'playlist_id': playlistId,
      'song_id': songId,
      'position': maxPos + 1,
    });
  }

  Future<void> removeSongFromPlaylist(int playlistId, int songId) async {
    await _db.delete('playlist_songs',
        where: 'playlist_id = ? AND song_id = ?',
        whereArgs: [playlistId, songId]);
  }

  Future<bool> isSongInPlaylist(int playlistId, int songId) async {
    final result = await _db.query('playlist_songs',
        where: 'playlist_id = ? AND song_id = ?',
        whereArgs: [playlistId, songId]);
    return result.isNotEmpty;
  }

  // ─── Cover Art Cache ──────────────────────────────────────────────────────

  Future<CoverArtCache?> getCoverArtCacheByFileName(String fileName) async {
    final maps = await _db.query('cover_art_cache',
        where: 'fileName = ?', whereArgs: [fileName]);
    if (maps.isEmpty) return null;
    return _coverArtCacheFromMap(maps.first);
  }

  Future<void> putCoverArtCache(CoverArtCache cache) async {
    final map = <String, dynamic>{
      'fileName': cache.fileName,
      'bytes': Uint8List.fromList(cache.bytes),
      'lastAccessed': cache.lastAccessed.toIso8601String(),
    };

    final existing = await getCoverArtCacheByFileName(cache.fileName);
    if (existing != null) {
      await _db.update('cover_art_cache', map,
          where: 'fileName = ?', whereArgs: [cache.fileName]);
    } else {
      await _db.insert('cover_art_cache', map);
    }
  }

  Future<void> deleteCoverArtCache(String fileName) async {
    await _db.delete('cover_art_cache',
        where: 'fileName = ?', whereArgs: [fileName]);
  }

  Future<List<CoverArtCache>> getAllCoverArtCaches() async {
    final maps = await _db.query('cover_art_cache', orderBy: 'lastAccessed ASC');
    return maps.map(_coverArtCacheFromMap).toList();
  }

  Future<int> getCoverArtCacheCount() async {
    return Sqflite.firstIntValue(
      await _db.rawQuery('SELECT COUNT(*) FROM cover_art_cache'),
    ) ?? 0;
  }

  Future<void> deleteCoverArtCachesByFileNames(List<String> fileNames) async {
    if (fileNames.isEmpty) return;
    final batch = _db.batch();
    for (final fileName in fileNames) {
      batch.delete('cover_art_cache',
          where: 'fileName = ?', whereArgs: [fileName]);
    }
    await batch.commit(noResult: true);
  }

  CoverArtCache _coverArtCacheFromMap(Map<String, dynamic> map) {
    final bytesRaw = map['bytes'];
    List<int> bytes;
    if (bytesRaw is Uint8List) {
      bytes = bytesRaw.toList();
    } else if (bytesRaw is List<int>) {
      bytes = bytesRaw;
    } else {
      bytes = <int>[];
    }

    return CoverArtCache(
      id: map['id'] as int?,
      fileName: map['fileName'] as String? ?? '',
      bytes: bytes,
      lastAccessed: map['lastAccessed'] != null
          ? DateTime.tryParse(map['lastAccessed'] as String)
          : null,
    );
  }

  // ─── Seed ─────────────────────────────────────────────────────────────────

  Future<void> _seedBuiltInSongs([Set<String>? expectedFileNames]) async {
    try {
      final String jsonString =
          await rootBundle.loadString('assets/song/songs.json');
      if (jsonString.trim().isEmpty) return;

      final dynamic decoded = json.decode(jsonString);
      if (decoded is! List) return;

      final List<Song> songsToInsert = [];
      for (final item in decoded) {
        if (item is Map<String, dynamic>) {
          final fileName = item['fileName'] as String? ?? '';
          if (fileName.isEmpty) continue;

          final sourcePath = 'assets/song/$fileName';

          // If caller passed expectedFileNames, skip entries that don't
          // belong (safety guard against a stale JSON).
          if (expectedFileNames != null &&
              !expectedFileNames.contains(sourcePath)) {
            continue;
          }

          songsToInsert.add(Song(
            name: _normalizeText(item['name']) ?? 'Unknown',
            artist: _normalizeText(item['artist']),
            album: _normalizeText(item['album']),
            durationMs: item['duration'] as int?,
            peakDb: (item['peakDb'] as num?)?.toDouble() ?? -12.0,
            sourcePath: sourcePath,
            isBuiltIn: true,
            dateAdded: DateTime.now(),
          ));
        }
      }

      if (songsToInsert.isNotEmpty) {
        await putAllSongs(songsToInsert);
        AppLogger.i('database.service',
            'Seeded ${songsToInsert.length} built-in songs');
      }
    } catch (e, stack) {
      AppLogger.e('database.service', 'seed songs failed',
          error: e, stack: stack);
    }
  }

  static String? _normalizeText(dynamic value) {
    if (value is! String) return null;
    final text = value.trim();
    return text.isEmpty ? null : text;
  }

  void dispose() {
    _songsController.close();
  }
}
