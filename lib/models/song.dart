import 'package:json_annotation/json_annotation.dart';

part 'song.g.dart';

/// Represents a song in the music library
/// A song can be either a built-in asset (shipped with the app) or a local
/// file imported by the user. The [sourcePath] determines how the song is
/// loaded: asset paths start with `assets/`, local paths are absolute file paths.
/// Equality is based on [id] only, allowing the same song to appear multiple
/// times in a playlist with different positions
@JsonSerializable()
class Song {
  int? id;
  final String name;
  final String? artist;
  final String? album;
  final int? durationMs;
  final double peakDb;
  final String sourcePath;
  @JsonKey(fromJson: _boolFromJson)
  final bool isBuiltIn;
  @JsonKey(fromJson: _boolFromJson)
  final bool isFavorite;
  @JsonKey(fromJson: _dateTimeFromJson)
  final DateTime? dateAdded;

  // ─── Playback statistics & ID3 tags ─────────────────────────────────────
  final int playCount;
  @JsonKey(fromJson: _dateTimeFromJson)
  final DateTime? lastPlayed;
  final String? genre;
  final int? year;

  Song({
    this.id,
    this.name = '',
    this.artist,
    this.album,
    this.durationMs,
    this.peakDb = -12.0,
    this.sourcePath = '',
    this.isBuiltIn = false,
    this.isFavorite = false,
    this.dateAdded,
    this.playCount = 0,
    this.lastPlayed,
    this.genre,
    this.year,
  });

  factory Song.fromJson(final Map<String, dynamic> json) =>
      _$SongFromJson(json);

  Map<String, dynamic> toJson() => _$SongToJson(this);

  /// Handles both bool and int (SQLite 0/1) formats.
  static bool _boolFromJson(final dynamic value) {
    if (value is bool) return value;
    if (value is int) return value == 1;
    return false;
  }

  /// Handles invalid date strings gracefully.
  static DateTime? _dateTimeFromJson(final dynamic value) {
    if (value == null) return null;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  /// File name extracted from sourcePath.
  String get fileName => sourcePath.split(RegExp(r'[/\\]')).last;

  /// For built-in songs, returns the asset path; for local songs, the file path.
  String get assetPath => sourcePath;

  /// Duration as a Duration object, or null if durationMs is not set.
  Duration? get duration =>
      durationMs != null ? Duration(milliseconds: durationMs!) : null;

  /// Copy with new values
  Song copyWith({
    final int? id,
    final String? name,
    final String? artist,
    final String? album,
    final int? durationMs,
    final double? peakDb,
    final String? sourcePath,
    final bool? isBuiltIn,
    final bool? isFavorite,
    final DateTime? dateAdded,
    final int? playCount,
    final DateTime? lastPlayed,
    final String? genre,
    final int? year,
  }) => Song(
    id: id ?? this.id,
    name: name ?? this.name,
    artist: artist ?? this.artist,
    album: album ?? this.album,
    durationMs: durationMs ?? this.durationMs,
    peakDb: peakDb ?? this.peakDb,
    sourcePath: sourcePath ?? this.sourcePath,
    isBuiltIn: isBuiltIn ?? this.isBuiltIn,
    isFavorite: isFavorite ?? this.isFavorite,
    dateAdded: dateAdded ?? this.dateAdded,
    playCount: playCount ?? this.playCount,
    lastPlayed: lastPlayed ?? this.lastPlayed,
    genre: genre ?? this.genre,
    year: year ?? this.year,
  );

  @override
  bool operator ==(final Object other) =>
      identical(this, other) || other is Song && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
