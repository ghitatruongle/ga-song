import '../logging/app_logger.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:audiotags/audiotags.dart';
import 'package:path/path.dart' as p;
import '../../models/song.dart';
import 'db_service_wrapper.dart';

/// Quan ly import/xoa bai hat local
class MusicManager {
  final DatabaseServiceWrapper _db;

  MusicManager(this._db);

  Future<void> importLocalSongs() async {
    try {
      final result = await FilePicker.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['mp3', 'flac', 'wav', 'm4a'],
      );

      if (result == null || result.files.isEmpty) return;

      final appDir = await getApplicationDocumentsDirectory();
      final localSongsDir = Directory('${appDir.path}/local_songs');
      if (!await localSongsDir.exists()) {
        await localSongsDir.create(recursive: true);
      }

      for (final file in result.files) {
        if (file.path == null) continue;
        final sourceFile = File(file.path!);

        final newPath = '${localSongsDir.path}/${file.name}';
        final targetFile = File(newPath);

        // Bo qua neu da ton tai file cung ten trong thu muc app
        if (await targetFile.exists()) continue;

        await sourceFile.copy(newPath);

        // Trich xuat metadata
        String name = p.basenameWithoutExtension(file.name);
        String? artist;
        String? album;

        try {
          final tag = await AudioTags.read(newPath);
          if (tag != null) {
            if (tag.title != null && tag.title!.isNotEmpty) {
              name = tag.title!;
            }
            if (tag.trackArtist != null && tag.trackArtist!.isNotEmpty) {
              artist = tag.trackArtist!;
            }
            if (tag.album != null && tag.album!.isNotEmpty) {
              album = tag.album!;
            }
          }
        } catch (e) {
          AppLogger.w(
            'music_manager.service',
            'audio tags read failed',
            error: e,
          );
        }

        final song = Song(
          name: name,
          artist: artist,
          album: album,
          sourcePath: newPath,
          isBuiltIn: false,
          dateAdded: DateTime.now(),
        );

        await _db.putSong(song);
      }
    } catch (e) {
      AppLogger.w(
        'music_manager.service',
        'local songs import failed',
        error: e,
      );
      rethrow;
    }
  }

  Future<void> deleteSong(Song song) async {
    try {
      if (song.id != null) {
        await _db.deleteSong(song.id!);
      }

      // Delete the actual file if it exists and is not a built-in asset
      if (!song.isBuiltIn) {
        final file = File(song.sourcePath);
        if (await file.exists()) {
          await file.delete();
        }
      }
    } catch (e) {
      AppLogger.w('music_manager.service', 'delete song failed', error: e);
      rethrow;
    }
  }
}
