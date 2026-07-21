import '../logging/app_logger.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../audio/lyric_parser.dart';

/// Result from an online lyrics search.
class LyricsSearchResult {
  final int id;
  final String trackName;
  final String artistName;
  final String? albumName;
  final int? duration;
  final bool instrumental;
  final String? plainLyrics;
  final String? syncedLyrics;

  const LyricsSearchResult({
    required this.id,
    required this.trackName,
    required this.artistName,
    this.albumName,
    this.duration,
    this.instrumental = false,
    this.plainLyrics,
    this.syncedLyrics,
  });

  factory LyricsSearchResult.fromJson(Map<String, dynamic> json) {
    return LyricsSearchResult(
      id: json['id'] as int,
      trackName: json['trackName'] as String? ?? '',
      artistName: json['artistName'] as String? ?? '',
      albumName: json['albumName'] as String?,
      duration: json['duration'] as int?,
      instrumental: json['instrumental'] as bool? ?? false,
      plainLyrics: json['plainLyrics'] as String?,
      syncedLyrics: json['syncedLyrics'] as String?,
    );
  }

  /// Whether this result has synced lyrics (LRC format)
  bool get hasSyncedLyrics => syncedLyrics != null && syncedLyrics!.isNotEmpty;

  /// Whether this result has plain lyrics
  bool get hasPlainLyrics => plainLyrics != null && plainLyrics!.isNotEmpty;

  /// Parse synced lyrics into LyricLine list
  List<LyricLine> get parsedSyncedLyrics {
    if (!hasSyncedLyrics) return [];
    return LyricParser.parse(syncedLyrics!);
  }
}

/// Service for fetching lyrics from online sources.
///
/// Primary source: lrclib.net (free, no API key required)
/// Provides synced lyrics in LRC format when available.
class OnlineLyricsService {
  static const String _baseUrl = 'https://lrclib.net/api';
  static const Duration _timeout = Duration(seconds: 10);

  /// Search for lyrics by title and artist
  Future<List<LyricsSearchResult>> search({
    required String title,
    String? artist,
    String? album,
  }) async {
    try {
      final queryParams = <String, String>{
        'track_name': title,
      };
      if (artist != null && artist.isNotEmpty) {
        queryParams['artist_name'] = artist;
      }
      if (album != null && album.isNotEmpty) {
        queryParams['album_name'] = album;
      }

      final uri = Uri.parse('$_baseUrl/search').replace(queryParameters: queryParams);
      
      final response = await http.get(uri).timeout(_timeout);

      if (response.statusCode == 200) {
        final List<dynamic> json = jsonDecode(response.body);
        return json
            .map((item) => LyricsSearchResult.fromJson(item as Map<String, dynamic>))
            .where((r) => r.hasSyncedLyrics || r.hasPlainLyrics)
            .toList();
      } else if (response.statusCode == 404) {
        // No results found
        return [];
      } else {
        AppLogger.w('online_lyrics.service', 'API error: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      AppLogger.w('online_lyrics.service', 'fetch failed', error: e);
      return [];
    }
  }

  /// Get the best matching lyrics for a song
  ///
  /// Returns the first result with synced lyrics, or the first result with plain lyrics.
  Future<LyricsSearchResult?> getBestMatch({
    required String title,
    String? artist,
    String? album,
  }) async {
    final results = await search(title: title, artist: artist, album: album);
    if (results.isEmpty) return null;

    // Prefer synced lyrics
    final synced = results.where((r) => r.hasSyncedLyrics).toList();
    if (synced.isNotEmpty) return synced.first;

    // Fall back to plain lyrics
    final plain = results.where((r) => r.hasPlainLyrics).toList();
    if (plain.isNotEmpty) return plain.first;

    return null;
  }

  /// Get synced lyrics as parsed LyricLine list
  Future<List<LyricLine>> getSyncedLyrics({
    required String title,
    String? artist,
    String? album,
  }) async {
    final result = await getBestMatch(title: title, artist: artist, album: album);
    if (result == null || !result.hasSyncedLyrics) return [];
    return result.parsedSyncedLyrics;
  }
}
