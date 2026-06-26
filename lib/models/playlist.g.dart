// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'playlist.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Playlist _$PlaylistFromJson(Map<String, dynamic> json) => Playlist(
  id: (json['id'] as num?)?.toInt(),
  name: json['name'] as String? ?? '',
  songIds:
      (json['songIds'] as List<dynamic>?)
          ?.map((e) => (e as num).toInt())
          .toList() ??
      const [],
);

Map<String, dynamic> _$PlaylistToJson(Playlist instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'songIds': instance.songIds,
};
