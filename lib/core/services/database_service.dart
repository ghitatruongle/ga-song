import 'dart:convert';
import 'dart:io' as io;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../../models/song.dart';
import '../../models/playlist.dart';
import '../../models/cover_art_cache.dart';

class DatabaseService {
  late Isar isar;

  Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();

    try {
      isar = await _openIsar(dir.path);
    } catch (e) {
      debugPrint('Failed to open Isar database: $e');
      debugPrint('Attempting to delete old database and recreate...');
      await _deleteOldDatabase(dir.path);
      isar = await _openIsar(dir.path);
    }

    // Seed built-in songs if empty
    if (await isar.songs.count() == 0) {
      await _seedBuiltInSongs();
    }
  }

  Future<Isar> _openIsar(String directory) {
    return Isar.open(
      [SongSchema, PlaylistSchema, CoverArtCacheSchema],
      directory: directory,
      name: 'ga_song',
      maxSizeMiB: 256,
      relaxedDurability: true,
      compactOnLaunch: CompactCondition(minRatio: 0.3),
      inspector: kDebugMode,
    );
  }

  Future<void> _deleteOldDatabase(String directory) async {
    try {
      final dbDir = io.Directory(directory);
      if (await dbDir.exists()) {
        // Delete Isar database files with the 'ga_song' name
        // Isar creates: <name>.isar, <name>.isar.lock, <name>.isar.temp
        for (final suffix in ['.isar', '.isar.lock', '.isar.temp']) {
          final file = io.File('$directory${io.Platform.pathSeparator}ga_song$suffix');
          if (await file.exists()) {
            await file.delete();
          }
        }
        // Also delete old default-named database (from previous version)
        for (final suffix in ['.isar', '.isar.lock', '.isar.temp']) {
          final file = io.File('$directory${io.Platform.pathSeparator}default$suffix');
          if (await file.exists()) {
            await file.delete();
          }
        }
      }
    } catch (e) {
      debugPrint('Error deleting old Isar database files: $e');
    }
  }

  Future<void> _seedBuiltInSongs() async {
    try {
      final String jsonString =
          await rootBundle.loadString('assets/song/songs.json');
      if (jsonString.trim().isEmpty) return;

      final dynamic decoded = json.decode(jsonString);
      if (decoded is! List) return;

      final List<Song> songsToInsert = [];
      for (final item in decoded) {
        if (item is Map<String, dynamic>) {
          final fileName = item['fileName'] as String? ?? '';
          if (fileName.isEmpty) continue;

          songsToInsert.add(Song()
            ..name = _normalizeText(item['name']) ?? 'Unknown'
            ..artist = _normalizeText(item['artist'])
            ..album = _normalizeText(item['album'])
            ..durationMs = item['duration'] as int?
            ..peakDb = (item['peakDb'] as num?)?.toDouble() ?? -12.0
            ..sourcePath = 'assets/song/$fileName'
            ..isBuiltIn = true
            ..dateAdded = DateTime.now());
        }
      }

      if (songsToInsert.isNotEmpty) {
        await isar.writeTxn(() async {
          await isar.songs.putAll(songsToInsert);
        });
      }
    } catch (e) {
      debugPrint('Error seeding songs from assets/song/songs.json: $e');
    }
  }

  static String? _normalizeText(dynamic value) {
    if (value is! String) return null;
    String text = value.trim();
    if (text.isEmpty) return null;
    return _repairMojibake(text);
  }

  static String _repairMojibake(String input) {
    try {
      final latin1Bytes = latin1.encode(input);
      final decoded = utf8.decode(latin1Bytes);
      if (decoded != input) {
        try {
          final latin1Bytes2 = latin1.encode(decoded);
          final doubleDecoded = utf8.decode(latin1Bytes2);
          if (doubleDecoded != decoded) return doubleDecoded;
        } catch (e, stack) {
          debugPrint('Error in database_service: $e\n$stack');
        }
        return decoded;
      }
    } catch (e, stack) {
      debugPrint('Error in database_service _repairMojibake: $e\n$stack');
    }
    return input;
  }
}
