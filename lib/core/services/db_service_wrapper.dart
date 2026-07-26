import 'dart:async';
import 'package:drift/drift.dart';
import '../database/app_database.dart';
import '../../models/song.dart';
import '../../models/playlist.dart';
import '../../models/cover_art_cache.dart';
import '../../models/extensions/song_extension.dart';
import '../../models/extensions/playlist_extension.dart';
import '../../models/extensions/cover_art_cache_extension.dart';
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
    _songsSubscription = _db.watchAllSongs().listen((entries) {
      _songsController.add(entries.map((e) => e.toSong()).toList());
    });
  }

  void _stopWatchingSongs() {
    _songsSubscription?.cancel();
    _songsSubscription = null;
  }

  Future<void> init() async {
    // Initialization is already done by AppDatabase constructor
  }

  void dispose() {
    _songsSubscription?.cancel();
    _songsController.close();
    // AppDatabase should probably be closed somewhere central, not here,
    // but for compatibility we might leave it open.
  }

  Future<List<Song>> getAllSongs() async {
    final entries = await _db.getAllSongs();
    return entries.map((e) => e.toSong()).toList();
  }

  Future<Result<List<Song>>> querySongs() async {
    try {
      final songs = await getAllSongs();
      return Success(songs);
    } catch (e, st) {
      return Failure(e.toString(), st);
    }
  }

  Future<int> getSongCount() async {
    return await _db.getSongCount();
  }

  Future<void> putSong(Song song) async {
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

  Future<void> putAllSongs(List<Song> songs) async {
    await _db.batch((batch) {
      for (final song in songs) {
        batch.insert(
          _db.songs,
          song.toCompanion(),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  Future<void> deleteSong(int id) async {
    await _db.deleteSong(id);
  }

  Future<List<Song>> getMostPlayedSongs({int limit = 50}) async {
    final entries = await _db.getMostPlayed(limit: limit);
    return entries.map((e) => e.toSong()).toList();
  }

  Future<List<Song>> getRecentlyPlayedSongs({int limit = 50}) async {
    final entries = await _db.getRecentlyPlayed(limit: limit);
    return entries.map((e) => e.toSong()).toList();
  }

  Future<List<Song>> getFavoriteSongs() async {
    final entries = await _db.getFavorites();
    return entries.map((e) => e.toSong()).toList();
  }

  Future<List<Song>> getRecentlyAddedSongs({int limit = 50}) async {
    final entries = await _db.getRecentlyAdded(limit: limit);
    return entries.map((e) => e.toSong()).toList();
  }

  Future<List<Song>> getDiscoverySongs({int limit = 50}) async {
    final entries = await _db.getDiscovery(limit: limit);
    return entries.map((e) => e.toSong()).toList();
  }

  Future<void> incrementPlayCount(int songId) async {
    await _db.incrementPlayCount(songId);
  }

  Future<Map<String, dynamic>> getLibraryStats() async {
    return await _db.getLibraryStats();
  }

  Future<Map<String, String>?> getCachedLyrics(int songId) async {
    final entry = await _db.getLyrics(songId);
    if (entry == null) return null;
    return {
      'plain': entry.plainLyrics ?? '',
      'synced': entry.syncedLyrics ?? '',
      'source': entry.source,
    };
  }

  Future<void> cacheLyrics({
    required int songId,
    String? plainLyrics,
    String? syncedLyrics,
    required String source,
  }) async {
    await _db.saveLyrics(
      songId,
      source: source,
      plain: plainLyrics,
      synced: syncedLyrics,
    );
  }

  Future<void> deleteCachedLyrics(int songId) async {
    await _db.deleteLyrics(songId);
  }

  Future<List<Playlist>> getAllPlaylists() async {
    final entries = await _db.getAllPlaylists();
    return entries.map((e) => e.toPlaylist()).toList();
  }

  Future<void> putPlaylist(Playlist playlist) async {
    if (playlist.id != null) {
      await _db.updatePlaylist(playlist.id!, playlist.name);
    } else {
      await _db.createPlaylist(playlist.name);
    }
  }

  Future<void> deletePlaylist(int id) async {
    await _db.deletePlaylist(id);
  }

  Future<void> addSongToPlaylist(int playlistId, int songId) async {
    await _db.addSongToPlaylist(playlistId, songId);
  }

  Future<void> removeSongFromPlaylist(int playlistId, int songId) async {
    await _db.removeSongFromPlaylist(playlistId, songId);
  }

  Future<bool> isSongInPlaylist(int playlistId, int songId) async {
    return await _db.isSongInPlaylist(playlistId, songId);
  }

  Future<CoverArtCache?> getCoverArtCacheByFileName(String fileName) async {
    final bytes = await _db.getCoverArt(fileName);
    if (bytes == null) return null;
    return CoverArtCache(fileName: fileName, bytes: bytes.toList());
  }

  Future<void> putCoverArtCache(CoverArtCache cache) async {
    await _db.saveCoverArt(cache.fileName, cache.bytesAsUint8List);
  }

  Future<void> deleteCoverArtCache(String fileName) async {
    // Current Drift DB might not have delete by fileName explicitly
    await _db.coverArtCache.deleteWhere((tbl) => tbl.fileName.equals(fileName));
  }

  Future<List<CoverArtCache>> getAllCoverArtCaches() async {
    final entries = await _db.select(_db.coverArtCache).get();
    return entries.map((e) => e.toCoverArtCache()).toList();
  }

  Future<int> getCoverArtCacheCount() async {
    return await _db.getCoverArtCacheCount();
  }

  Future<void> deleteCoverArtCachesByFileNames(List<String> fileNames) async {
    for (final fileName in fileNames) {
      await deleteCoverArtCache(fileName);
    }
  }
}
