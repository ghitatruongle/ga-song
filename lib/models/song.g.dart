// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'song.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Song _$SongFromJson(Map<String, dynamic> json) => Song(
  id: (json['id'] as num?)?.toInt(),
  name: json['name'] as String? ?? '',
  artist: json['artist'] as String?,
  album: json['album'] as String?,
  durationMs: (json['durationMs'] as num?)?.toInt(),
  peakDb: (json['peakDb'] as num?)?.toDouble() ?? -12.0,
  sourcePath: json['sourcePath'] as String? ?? '',
  isBuiltIn: json['isBuiltIn'] == null
      ? false
      : Song._boolFromJson(json['isBuiltIn']),
  isFavorite: json['isFavorite'] == null
      ? false
      : Song._boolFromJson(json['isFavorite']),
  dateAdded: Song._dateTimeFromJson(json['dateAdded']),
  playCount: (json['playCount'] as num?)?.toInt() ?? 0,
  lastPlayed: Song._dateTimeFromJson(json['lastPlayed']),
  genre: json['genre'] as String?,
  year: (json['year'] as num?)?.toInt(),
);

Map<String, dynamic> _$SongToJson(Song instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'artist': instance.artist,
  'album': instance.album,
  'durationMs': instance.durationMs,
  'peakDb': instance.peakDb,
  'sourcePath': instance.sourcePath,
  'isBuiltIn': instance.isBuiltIn,
  'isFavorite': instance.isFavorite,
  'dateAdded': instance.dateAdded?.toIso8601String(),
  'playCount': instance.playCount,
  'lastPlayed': instance.lastPlayed?.toIso8601String(),
  'genre': instance.genre,
  'year': instance.year,
};
