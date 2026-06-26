import 'package:ga_song/models/song.dart';
import 'package:ga_song/models/playlist.dart';
import 'package:ga_song/models/cover_art_cache.dart';

/// Factory helpers for creating test data.

Song createTestSong({
  int? id,
  String name = 'Test Song',
  String? artist = 'Test Artist',
  String? album = 'Test Album',
  int? durationMs = 180000,
  double peakDb = -12.0,
  String sourcePath = 'assets/song/test.mp3',
  bool isBuiltIn = false,
  bool isFavorite = false,
  DateTime? dateAdded,
}) {
  return Song(
    id: id,
    name: name,
    artist: artist,
    album: album,
    durationMs: durationMs,
    peakDb: peakDb,
    sourcePath: sourcePath,
    isBuiltIn: isBuiltIn,
    isFavorite: isFavorite,
    dateAdded: dateAdded,
  );
}

List<Song> createTestSongList(int count, {String prefix = 'Song'}) {
  return List.generate(count, (i) {
    return createTestSong(
      id: i + 1,
      name: '$prefix ${i + 1}',
      artist: 'Artist ${(i % 3) + 1}',
      album: 'Album ${(i % 2) + 1}',
      sourcePath: 'assets/song/${prefix.toLowerCase()}_${i + 1}.mp3',
      dateAdded: DateTime(2026, 1, i + 1),
    );
  });
}

Playlist createTestPlaylist({
  int? id,
  String name = 'Test Playlist',
  List<int> songIds = const [],
}) {
  return Playlist(id: id, name: name, songIds: songIds);
}

CoverArtCache createTestCoverArtCache({
  int? id,
  String fileName = 'test.mp3',
  List<int> bytes = const [0x89, 0x50, 0x4E, 0x47],
  DateTime? lastAccessed,
}) {
  return CoverArtCache(
    id: id,
    fileName: fileName,
    bytes: bytes,
    lastAccessed: lastAccessed,
  );
}
