import 'package:drift/drift.dart';
import 'songs_table.dart';
import 'playlists_table.dart';

/// Playlist songs junction table for Drift ORM.
///
/// Links playlists to songs with position ordering.
@DataClassName('PlaylistSongEntry')
class PlaylistSongs extends Table {
  IntColumn get playlistId => integer().references(Playlists, #id)();
  IntColumn get songId => integer().references(Songs, #id)();
  IntColumn get position => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {playlistId, songId};
}
