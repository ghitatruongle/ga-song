import '../playlist.dart';
import '../../core/database/app_database.dart';
import 'package:drift/drift.dart';

extension PlaylistEntryMapper on PlaylistEntry {
  Playlist toPlaylist() => Playlist(id: id, name: name);
}

extension PlaylistMapper on Playlist {
  PlaylistsCompanion toCompanion() => PlaylistsCompanion(
    id: id != null ? Value(id!) : const Value.absent(),
    name: Value(name),
  );
}
