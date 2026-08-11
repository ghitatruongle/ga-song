/// Mock implementation of [DatabaseServiceWrapper] for testing.
/// Provides in-memory database operations without Drift/SQLite dependencies.
library;

import 'package:ga_song/core/services/db_service_wrapper.dart';
import 'package:ga_song/models/song.dart';
import 'package:ga_song/models/playlist.dart';
import 'package:ga_song/models/cover_art_cache.dart';

class MockDatabaseServiceWrapper implements DatabaseServiceWrapper {
  final Map<int, Song> _songs = {};
  final Map<int, Playlist> _playlists = {};
  final Map<int, List<int>> _playlistSongs = {}; // playlistId -> songIds
  final Map<String, CoverArtCache> _coverArtCache = {};
  int _nextSongId = 1;
  int _nextPlaylistId = 1;
  int _nextCacheId = 1;

  // Track calls for verification
  int getAllSongsCallCount = 0;
  int getSongCallCount = 0;
  int insertSongCallCount = 0;
  int updateSongCallCount = 0;
  int deleteSongCallCount = 0;
  int getAllPlaylistsCallCount = 0;
  int getPlaylistCallCount = 0;
  int insertPlaylistCallCount = 0;
  int updatePlaylistCallCount = 0;
  int deletePlaylistCallCount = 0;
  int getPlaylistSongsCallCount = 0;
  int addSongToPlaylistCallCount = 0;
  int removeSongFromPlaylistCallCount = 0;
  int reorderPlaylistSongsCallCount = 0;
  int getCoverArtCallCount = 0;
  int putCoverArtCallCount = 0;
  int deleteCoverArtCallCount = 0;
  int clearCoverArtCacheCallCount = 0;
  int incrementPlayCountCallCount = 0;

  @override
  Future<void> init() async {
    // Pre-populate with some test data
    _songs[1] = Song(
      id: 1,
      name: 'Test Song 1',
      artist: 'Test Artist',
      album: 'Test Album',
      durationMs: 180000,
      sourcePath: 'assets/song/test1.mp3',
      isBuiltIn: true,
    );
    _songs[2] = Song(
      id: 2,
      name: 'Test Song 2',
      artist: 'Test Artist 2',
      album: 'Test Album 2',
      durationMs: 200000,
      sourcePath: 'assets/song/test2.mp3',
      isBuiltIn: true,
    );
    _nextSongId = 3;

    _playlists[1] = Playlist(id: 1, name: 'Test Playlist', songIds: [1, 2]);
    _playlistSongs[1] = [1, 2];
    _nextPlaylistId = 2;
  }

  Future<void> close() async {
    _songs.clear();
    _playlists.clear();
    _playlistSongs.clear();
    _coverArtCache.clear();
  }

  @override
  Future<List<Song>> getAllSongs() async {
    getAllSongsCallCount++;
    return _songs.values.toList();
  }

  @override
  Future<Song?> getSong(final int id) async {
    getSongCallCount++;
    return _songs[id];
  }

  Future<int> insertSong(final Song song) async {
    insertSongCallCount++;
    final id = _nextSongId++;
    final newSong = song.copyWith(id: id);
    _songs[id] = newSong;
    return id;
  }

  Future<void> updateSong(final Song song) async {
    updateSongCallCount++;
    if (song.id != null && _songs.containsKey(song.id)) {
      _songs[song.id!] = song;
    }
  }

  @override
  Future<void> deleteSong(final int id) async {
    deleteSongCallCount++;
    _songs.remove(id);
    // Also remove from playlists
    for (final entry in _playlistSongs.entries) {
      entry.value.remove(id);
    }
  }

  @override
  Future<List<Playlist>> getAllPlaylists() async {
    getAllPlaylistsCallCount++;
    return _playlists.values.toList();
  }

  Future<Playlist?> getPlaylist(final int id) async {
    getPlaylistCallCount++;
    return _playlists[id];
  }

  Future<int> insertPlaylist(final Playlist playlist) async {
    insertPlaylistCallCount++;
    final id = _nextPlaylistId++;
    _playlists[id] = Playlist(
      id: id,
      name: playlist.name,
      songIds: List.from(playlist.songIds),
    );
    _playlistSongs[id] = [];
    return id;
  }

  Future<void> updatePlaylist(final Playlist playlist) async {
    updatePlaylistCallCount++;
    if (playlist.id != null && _playlists.containsKey(playlist.id)) {
      _playlists[playlist.id!] = playlist;
    }
  }

  @override
  Future<void> deletePlaylist(final int id) async {
    deletePlaylistCallCount++;
    _playlists.remove(id);
    _playlistSongs.remove(id);
  }

  Future<List<Song>> getPlaylistSongs(final int playlistId) async {
    getPlaylistSongsCallCount++;
    final songIds = _playlistSongs[playlistId] ?? [];
    return songIds.map((final id) => _songs[id]).whereType<Song>().toList();
  }

  @override
  Future<void> addSongToPlaylist(
    final int playlistId,
    final int songId, {
    final int? position,
  }) async {
    addSongToPlaylistCallCount++;
    final songIds = _playlistSongs[playlistId] ?? [];
    if (position != null && position >= 0 && position <= songIds.length) {
      songIds.insert(position, songId);
    } else {
      songIds.add(songId);
    }
    _playlistSongs[playlistId] = songIds;

    // Update playlist songIds
    if (_playlists.containsKey(playlistId)) {
      final p = _playlists[playlistId]!;
      _playlists[playlistId] = Playlist(
        id: playlistId,
        name: p.name,
        songIds: List.from(songIds),
      );
    }
  }

  @override
  Future<void> removeSongFromPlaylist(
    final int playlistId,
    final int songId,
  ) async {
    removeSongFromPlaylistCallCount++;
    final songIds = _playlistSongs[playlistId] ?? [];
    songIds.remove(songId);
    _playlistSongs[playlistId] = songIds;

    if (_playlists.containsKey(playlistId)) {
      final p = _playlists[playlistId]!;
      _playlists[playlistId] = Playlist(
        id: playlistId,
        name: p.name,
        songIds: List.from(songIds),
      );
    }
  }

  @override
  Future<void> reorderPlaylistSongs(
    final int playlistId,
    final List<int> songIds,
  ) async {
    reorderPlaylistSongsCallCount++;
    _playlistSongs[playlistId] = List.from(songIds);

    if (_playlists.containsKey(playlistId)) {
      final p = _playlists[playlistId]!;
      _playlists[playlistId] = Playlist(
        id: playlistId,
        name: p.name,
        songIds: List.from(songIds),
      );
    }
  }

  Future<CoverArtCache?> getCoverArt(final String fileName) async {
    getCoverArtCallCount++;
    return _coverArtCache[fileName];
  }

  Future<void> putCoverArt(final CoverArtCache cache) async {
    putCoverArtCallCount++;
    final id = _nextCacheId++;
    cache.id = id;
    _coverArtCache[cache.fileName] = cache;
  }

  Future<void> deleteCoverArt(final String fileName) async {
    deleteCoverArtCallCount++;
    _coverArtCache.remove(fileName);
  }

  Future<void> clearCoverArtCache() async {
    clearCoverArtCacheCallCount++;
    _coverArtCache.clear();
  }

  @override
  Future<int> getSongCount() async => _songs.length;

  Future<int> getPlaylistCount() async => _playlists.length;

  @override
  Future<void> incrementPlayCount(final int songId) async {
    incrementPlayCountCallCount++;
    final song = _songs[songId];
    if (song != null) {
      _songs[songId] = song.copyWith(playCount: song.playCount + 1);
    }
  }

  @override
  dynamic noSuchMethod(final Invocation invocation) =>
      super.noSuchMethod(invocation);
}
