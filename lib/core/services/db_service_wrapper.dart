import 'dart:async';
import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../database/app_database.dart';
import '../logging/app_logger.dart';
import '../../models/song.dart';
import '../../models/playlist.dart';
import '../../models/cover_art_cache.dart';
import '../../models/extensions/song_extension.dart';
import '../../models/extensions/playlist_extension.dart';
import '../utils/result.dart';

/// A wrapper around AppDatabase (Drift) that implements the old DatabaseService interface
/// so that the rest of the app doesn't break during the transition.
class DatabaseServiceWrapper {
  final AppDatabase _db;

  late final StreamController<List<Song>> _songsController;
  StreamSubscription? _songsSubscription;

  DatabaseServiceWrapper(this._db) {
    _songsController = StreamController<List<Song>>.broadcast(
      onListen: () {
        _startWatchingSongs();
      },
      onCancel: () {
        _stopWatchingSongs();
      },
    );
  }

  Stream<List<Song>> get songsStream => _songsController.stream;

  void _startWatchingSongs() {
    _songsSubscription?.cancel();
    _songsSubscription = _db.watchAllSongs().listen((final entries) {
      _songsController.add(entries.map((final e) => e.toSong()).toList());
    });
  }

  void _stopWatchingSongs() {
    _songsSubscription?.cancel();
    _songsSubscription = null;
  }

  Future<void> init() async {
    // Restore the built-in library seeding that was lost in the v0.5.0
    // sqflite → Drift rewrite: without it a fresh install shows an empty
    // library even though the songs ship as assets.
    await ensureBuiltInSeeded();
  }

  /// Checks that all built-in songs from `assets/song/songs.json` exist in
  /// the database with matching metadata. If any are missing or stale
  /// (fresh install, partial seed, a corrupt DB, or songs.json updated with
  /// new fields like `album`), deletes ALL built-in rows and re-seeds.
  Future<void> ensureBuiltInSeeded() async {
    try {
      final jsonString = await rootBundle.loadString('assets/song/songs.json');
      if (jsonString.trim().isEmpty) return;

      final decoded = json.decode(jsonString);
      if (decoded is! List) return;

      // sourcePath -> (name, album) expected signature from songs.json
      final expected = <String, ({String name, String? album})>{};
      for (final item in decoded) {
        if (item is Map<String, dynamic>) {
          final fileName = item['fileName'] as String? ?? '';
          if (fileName.isNotEmpty) {
            final sourcePath = 'assets/song/$fileName';
            expected[sourcePath] = (
              name: _normalizeText(item['name']) ?? 'Unknown',
              album: _normalizeText(item['album']),
            );
          }
        }
      }
      if (expected.isEmpty) return;

      // Query actual built-in sourcePaths from DB.
      final all = await getAllSongs();
      final actualPaths = all
          .where((final s) => s.isBuiltIn)
          .map((final s) => s.sourcePath)
          .toSet();

      // Fast path: counts + signatures match → nothing to do.
      final actualSignatures = all
          .where((final s) => s.isBuiltIn)
          .map((final s) => (path: s.sourcePath, name: s.name, album: s.album))
          .toList();

      bool signatureMatches(
        final List<({String path, String name, String? album})> actual,
      ) {
        if (actual.length != expected.length) return false;
        for (final s in actual) {
          final exp = expected[s.path];
          if (exp == null) return false;
          if (s.name != exp.name || s.album != exp.album) return false;
        }
        return true;
      }

      if (actualPaths.length == expected.length &&
          actualPaths.containsAll(expected.keys) &&
          signatureMatches(actualSignatures)) {
        return;
      }

      AppLogger.i(
        'database.wrapper',
        'Built-in songs mismatch (expected=${expected.length}, '
            'actual=${actualPaths.length}); re-seeding…',
      );

      // Delete stale built-in rows and re-seed from JSON.
      await (_db.delete(
        _db.songs,
      )..where((final t) => t.isBuiltIn.equals(true))).go();

      final songsToInsert = <Song>[];
      for (final item in decoded) {
        if (item is Map<String, dynamic>) {
          final fileName = item['fileName'] as String? ?? '';
          if (fileName.isEmpty) continue;
          final sourcePath = 'assets/song/$fileName';
          if (!expected.containsKey(sourcePath)) continue;

          songsToInsert.add(
            Song(
              name: _normalizeText(item['name']) ?? 'Unknown',
              artist: _normalizeText(item['artist']),
              album: _normalizeText(item['album']),
              durationMs: item['duration'] as int?,
              peakDb: (item['peakDb'] as num?)?.toDouble() ?? -12.0,
              sourcePath: sourcePath,
              isBuiltIn: true,
              dateAdded: DateTime.now(),
            ),
          );
        }
      }

      if (songsToInsert.isNotEmpty) {
        await putAllSongs(songsToInsert);
        AppLogger.i(
          'database.wrapper',
          'Seeded ${songsToInsert.length} built-in songs',
        );
      }
    } catch (e, stack) {
      AppLogger.e(
        'database.wrapper',
        'ensureBuiltInSeeded failed',
        error: e,
        stack: stack,
      );
    }
  }

  static String? _normalizeText(final dynamic value) {
    if (value is! String) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  void dispose() {
    _songsSubscription?.cancel();
    _songsController.close();
    // AppDatabase should probably be closed somewhere central, not here,
    // but for compatibility we might leave it open.
  }

  Future<List<Song>> getAllSongs() async {
    final entries = await _db.getAllSongs();
    return entries.map((final e) => e.toSong()).toList();
  }

  /// Gets a single song by ID.
  Future<Song?> getSong(final int id) async {
    final entry = await _db.getSongById(id);
    return entry?.toSong();
  }

  /// Searches songs by name or artist.
  Future<List<Song>> searchSongs(final String query) async {
    final entries = await _db.searchSongs(query);
    return entries.map((final e) => e.toSong()).toList();
  }

  Future<Result<List<Song>>> querySongs() async {
    try {
      final songs = await getAllSongs();
      return Success(songs);
    } catch (e, st) {
      return Failure(e.toString(), st);
    }
  }

  Future<int> getSongCount() async => _db.getSongCount();

  Future<void> putSong(final Song song) async {
    if (song.id != null) {
      await _db.updateSong(song.toCompanion());
    } else {
      await _db.insertSong(
        song.toCompanion().copyWith(
          id: const Value.absent(), // Auto increment if new
        ),
      );
    }
  }

  Future<void> putAllSongs(final List<Song> songs) async {
    await _db.batch((final batch) {
      for (final song in songs) {
        batch.insert(
          _db.songs,
          song.toCompanion(),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  Future<void> deleteSong(final int id) async {
    await _db.deleteSong(id);
  }

  Future<List<Song>> getMostPlayedSongs({final int limit = 50}) async {
    final entries = await _db.getMostPlayed(limit: limit);
    return entries.map((final e) => e.toSong()).toList();
  }

  Future<List<Song>> getRecentlyPlayedSongs({final int limit = 50}) async {
    final entries = await _db.getRecentlyPlayed(limit: limit);
    return entries.map((final e) => e.toSong()).toList();
  }

  Future<void> toggleFavorite(final int songId) async {
    await _db.toggleFavorite(songId);
  }

  Future<List<Song>> getFavoriteSongs() async {
    final entries = await _db.getFavorites();
    return entries.map((final e) => e.toSong()).toList();
  }

  Future<List<Song>> getRecentlyAddedSongs({final int limit = 50}) async {
    final entries = await _db.getRecentlyAdded(limit: limit);
    return entries.map((final e) => e.toSong()).toList();
  }

  Future<List<Song>> getDiscoverySongs({final int limit = 50}) async {
    final entries = await _db.getDiscovery(limit: limit);
    return entries.map((final e) => e.toSong()).toList();
  }

  Future<void> incrementPlayCount(final int songId) async {
    await _db.incrementPlayCount(songId);
  }

  Future<Map<String, dynamic>> getLibraryStats() async => _db.getLibraryStats();

  Future<Map<String, String>?> getCachedLyrics(final int songId) async {
    final entry = await _db.getLyrics(songId);
    if (entry == null) return null;
    return {
      'plain': entry.plainLyrics ?? '',
      'synced': entry.syncedLyrics ?? '',
      'source': entry.source,
    };
  }

  Future<void> cacheLyrics({
    required final int songId,
    final String? plainLyrics,
    final String? syncedLyrics,
    required final String source,
  }) async {
    await _db.saveLyrics(
      songId,
      source: source,
      plain: plainLyrics,
      synced: syncedLyrics,
    );
  }

  Future<void> deleteCachedLyrics(final int songId) async {
    await _db.deleteLyrics(songId);
  }

  Future<List<Playlist>> getAllPlaylists() async {
    final entries = await _db.getAllPlaylists();
    return entries.map((final e) => e.toPlaylist()).toList();
  }

  Future<List<Song>> getPlaylistSongsDirect(final int playlistId) async {
    final entries = await _db.getPlaylistSongs(playlistId);
    return entries.map((final e) => e.toSong()).toList();
  }

  Future<void> putPlaylist(final Playlist playlist) async {
    if (playlist.id != null) {
      await _db.updatePlaylist(playlist.id!, playlist.name);
    } else {
      await _db.createPlaylist(playlist.name);
    }
  }

  Future<void> deletePlaylist(final int id) async {
    await _db.deletePlaylist(id);
  }

  Future<void> addSongToPlaylist(final int playlistId, final int songId) async {
    await _db.addSongToPlaylist(playlistId, songId);
  }

  Future<void> removeSongFromPlaylist(
    final int playlistId,
    final int songId,
  ) async {
    await _db.removeSongFromPlaylist(playlistId, songId);
  }

  Future<bool> isSongInPlaylist(final int playlistId, final int songId) async =>
      _db.isSongInPlaylist(playlistId, songId);

  /// Reorder songs in a user-created playlist.
  Future<void> reorderPlaylistSongs(
    final int playlistId,
    final List<int> songIds,
  ) async {
    await _db.reorderPlaylistSongs(playlistId, songIds);
  }

  Future<CoverArtCache?> getCoverArtCacheByFileName(
    final String fileName,
  ) async {
    final bytes = await _db.getCoverArt(fileName);
    if (bytes == null) return null;
    return CoverArtCache(fileName: fileName, bytes: bytes.toList());
  }

  Future<void> putCoverArtCache(final CoverArtCache cache) async {
    await _db.saveCoverArt(cache.fileName, cache.bytesAsUint8List);
  }

  Future<void> deleteCoverArtCache(final String fileName) async {
    // Current Drift DB might not have delete by fileName explicitly
    await _db.coverArtCache.deleteWhere(
      (final tbl) => tbl.fileName.equals(fileName),
    );
  }

  Future<int> getCoverArtCacheCount() async => _db.getCoverArtCacheCount();

  /// Evicts the oldest [count] cover art cache entries (by last_accessed).
  /// Uses a single SQL query — no loading of all entries into memory.
  Future<void> evictOldestCoverArtCaches(final int count) async {
    if (count <= 0) return;
    await _db.customStatement(
      'DELETE FROM cover_art_cache WHERE id IN ('
      'SELECT id FROM cover_art_cache ORDER BY last_accessed ASC LIMIT ?)',
      [Variable.withInt(count)],
    );
  }

  /// Evicts half of all cover art cache entries (oldest by last_accessed).
  Future<void> evictHalfCoverArtCaches() async {
    final count = await getCoverArtCacheCount();
    if (count == 0) return;
    await _db.customStatement(
      'DELETE FROM cover_art_cache WHERE id IN ('
      'SELECT id FROM cover_art_cache ORDER BY last_accessed ASC LIMIT ?)',
      [Variable.withInt((count / 2).ceil())],
    );
  }
}
