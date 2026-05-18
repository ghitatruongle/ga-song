import 'package:isar/isar.dart';
import 'song.dart';

part 'playlist.g.dart';

@collection
class Playlist {
  Id id = Isar.autoIncrement;

  late String name;

  final songs = IsarLinks<Song>();
}
