import 'package:json_annotation/json_annotation.dart';

part 'playlist.g.dart';

/// Represents a user-created playlist containing ordered song references.
///
/// Songs are stored as [songIds] (references to [Song.id] in the database).
/// Equality is based on [id] only.
@JsonSerializable()
class Playlist {
  int? id;
  @JsonKey(defaultValue: '')
  final String name;
  final List<int> songIds;

  Playlist({this.id, required this.name, this.songIds = const []});

  factory Playlist.fromJson(Map<String, dynamic> json) =>
      _$PlaylistFromJson(json);

  Map<String, dynamic> toJson() => _$PlaylistToJson(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Playlist && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
