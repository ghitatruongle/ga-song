import '../song.dart';
import '../../core/database/app_database.dart';
import 'package:drift/drift.dart';

extension SongEntryMapper on SongEntry {
  Song toSong() {
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
      playCount: playCount,
      lastPlayed: lastPlayed,
      genre: genre,
      year: year,
    );
  }
}

extension SongMapper on Song {
  SongsCompanion toCompanion() {
    return SongsCompanion(
      id: id != null ? Value(id!) : const Value.absent(),
      name: Value(name),
      artist: Value(artist),
      album: Value(album),
      durationMs: Value(durationMs),
      peakDb: Value(peakDb),
      sourcePath: Value(sourcePath),
      isBuiltIn: Value(isBuiltIn),
      isFavorite: Value(isFavorite),
      dateAdded: Value(dateAdded),
      playCount: Value(playCount),
      lastPlayed: Value(lastPlayed),
      genre: Value(genre),
      year: Value(year),
    );
  }
}
