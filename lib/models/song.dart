import 'package:isar/isar.dart';

part 'song.g.dart';

@collection
class Song {
  Id id = Isar.autoIncrement;

  late String name;
  String? artist;
  String? album;
  int? durationMs;
  double peakDb = -12.0;

  late String sourcePath;
  bool isBuiltIn = false;
  
  @Index()
  DateTime? dateAdded;

  @ignore
  Duration? get duration => durationMs != null ? Duration(milliseconds: durationMs!) : null;

  @ignore
  String get fileName => sourcePath.replaceAll('\\', '/').split('/').last;

  @ignore
  String get assetPath => sourcePath;
}
