import 'dart:typed_data';
import 'package:json_annotation/json_annotation.dart';

part 'cover_art_cache.g.dart';

/// Cached cover art image bytes for a song, persisted in SQLite.
///
/// The [fileName] is the unique key (matches [Song.fileName]). The [bytes]
/// contain the raw image data (PNG/JPEG). Entries are evicted LRU when the
/// cache exceeds [maxDiskCacheEntries].
@JsonSerializable()
class CoverArtCache {
  CoverArtCache({
    this.id,
    this.fileName = '',
    this.bytes = const [],
    DateTime? lastAccessed,
  }) : lastAccessed = lastAccessed ?? DateTime.now();

  int? id;
  String fileName;
  List<int> bytes;
  DateTime lastAccessed;

  Uint8List get bytesAsUint8List => Uint8List.fromList(bytes);

  static int maxDiskCacheEntries(bool isAndroid) => isAndroid ? 24 : 60;

  factory CoverArtCache.fromJson(Map<String, dynamic> json) => _$CoverArtCacheFromJson(json);

  Map<String, dynamic> toJson() => _$CoverArtCacheToJson(this);
}
