import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class SongModel {
  final String name;
  final String fileName;
  final String? artist;
  final String? album;
  final Duration? duration;
  final double peakDb;

  SongModel({
    required this.name,
    required this.fileName,
    this.artist,
    this.album,
    this.duration,
    this.peakDb = -12.0,
  });

  String get assetPath {
    return 'assets/song/$fileName';
  }

  factory SongModel.fromJson(Map<String, dynamic> json) {
    return SongModel(
      name: _normalizeText(json['name']) ?? 'Unknown',
      fileName: json['fileName'] ?? '',
      artist: _normalizeText(json['artist']),
      album: _normalizeText(json['album']),
      duration: json['duration'] != null
          ? Duration(milliseconds: json['duration'] as int)
          : null,
      peakDb: (json['peakDb'] as num?)?.toDouble() ?? -12.0,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'fileName': fileName,
    'artist': artist,
    'album': album,
    'duration': duration?.inMilliseconds,
    'peakDb': peakDb,
  };

  /// Sanitises a JSON string value.
  /// Repairs double-encoded UTF-8 (mojibake) and trims whitespace.
  static String? _normalizeText(dynamic value) {
    if (value is! String) return null;
    String text = value.trim();
    if (text.isEmpty) return null;

    // Repair mojibake: UTF-8 bytes misinterpreted as Latin-1 (possibly twice)
    text = _repairMojibake(text);
    return text;
  }

  /// Attempts to repair text that was double-encoded as UTF-8 → Latin-1.
  static String _repairMojibake(String input) {
    try {
      // Mojibake happens when UTF-8 bytes are interpreted as Latin-1
      // Repair: encode as Latin-1 (get original bytes), then decode as UTF-8
      final latin1Bytes = latin1.encode(input);
      final decoded = utf8.decode(latin1Bytes);

      // If different, try once more for double mojibake
      if (decoded != input) {
        try {
          final latin1Bytes2 = latin1.encode(decoded);
          final doubleDecoded = utf8.decode(latin1Bytes2);
          if (doubleDecoded != decoded) return doubleDecoded;
        } catch (_) {
          // ignore
        }
        return decoded;
      }
    } catch (_) {
      // If latin1.encode fails (e.g., chars > 255), return original
    }
    return input;
  }
}

class SongLoader {
  static Future<List<SongModel>> loadSongs() async {
    try {
      final String jsonString = await rootBundle.loadString(
        'assets/song/songs.json',
      );

      if (jsonString.trim().isEmpty) {
        debugPrint('Error: songs.json is empty');
        return [];
      }

      final dynamic decoded = json.decode(jsonString);

      if (decoded is! List) {
        debugPrint('Error: songs.json should be a list, got ${decoded.runtimeType}');
        return [];
      }

      final List<dynamic> jsonList = decoded;

      if (jsonList.isEmpty) {
        debugPrint('Warning: songs.json contains no songs');
        return [];
      }

      final List<SongModel> songs = [];
      int validCount = 0;
      int invalidCount = 0;

      for (int i = 0; i < jsonList.length; i++) {
        try {
          final song = SongModel.fromJson(jsonList[i] as Map<String, dynamic>);
          if (song.fileName.isNotEmpty) {
            songs.add(song);
            validCount++;
          } else {
            debugPrint('Warning: Song at index $i has empty fileName, skipping');
            invalidCount++;
          }
        } catch (e, stackTrace) {
          debugPrint('Error parsing song at index $i: $e');
          debugPrint('Stack trace: $stackTrace');
          invalidCount++;
        }
      }

      if (invalidCount > 0) {
        debugPrint('Loaded $validCount valid songs, skipped $invalidCount invalid entries');
      }

      return songs;
    } catch (e, stackTrace) {
      debugPrint('Error loading songs: $e');
      debugPrint('Stack trace: $stackTrace');
      return [];
    }
  }
}
