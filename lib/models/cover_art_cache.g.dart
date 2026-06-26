// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cover_art_cache.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CoverArtCache _$CoverArtCacheFromJson(Map<String, dynamic> json) =>
    CoverArtCache(
      id: (json['id'] as num?)?.toInt(),
      fileName: json['fileName'] as String? ?? '',
      bytes:
          (json['bytes'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          const [],
      lastAccessed: json['lastAccessed'] == null
          ? null
          : DateTime.parse(json['lastAccessed'] as String),
    );

Map<String, dynamic> _$CoverArtCacheToJson(CoverArtCache instance) =>
    <String, dynamic>{
      'id': instance.id,
      'fileName': instance.fileName,
      'bytes': instance.bytes,
      'lastAccessed': instance.lastAccessed.toIso8601String(),
    };
