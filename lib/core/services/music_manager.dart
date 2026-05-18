import 'dart:io';
import 'package:isar/isar.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:audiotags/audiotags.dart';
import 'package:path/path.dart' as p;
import 'package:flutter/foundation.dart';
import '../../models/song.dart';

/// Quản lý import/xóa bài hát local
class MusicManager {
  final Isar isar;

  MusicManager(this.isar);

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
        
        // Bỏ qua nếu đã tồn tại file cùng tên trong thư mục app
        if (await targetFile.exists()) continue;

        await sourceFile.copy(newPath);

        // Trích xuất metadata
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
            
            // Trích xuất ảnh bìa nếu có
            final pictures = tag.pictures;
            if (pictures.isNotEmpty) {
              final pic = pictures.first;
              final coverPath = '${localSongsDir.path}/${file.name}.png';
              final coverFile = File(coverPath);
              await coverFile.writeAsBytes(pic.bytes);
            }
          }
        } catch (e) {
          debugPrint('Error reading metadata for ${file.name}: $e');
        }

        // Copy lyric file nếu có (cùng tên, đuôi .srt hoặc .lrc)
        final sourceDir = sourceFile.parent.path;
        final baseName = p.basenameWithoutExtension(file.name);
        
        final possibleLyrics = [
          '$sourceDir/$baseName.lrc',
          '$sourceDir/$baseName.srt',
          '$sourceDir/${baseName}_lyric.srt',
        ];
        
        for (final lrcPath in possibleLyrics) {
          final lrcFile = File(lrcPath);
          if (await lrcFile.exists()) {
            final targetLrc = File('${localSongsDir.path}/${p.basename(lrcPath)}');
            await lrcFile.copy(targetLrc.path);
            break; // Chỉ copy 1 file lyric
          }
        }

        final song = Song()
          ..name = name
          ..artist = artist
          ..album = album
          ..sourcePath = newPath
          ..isBuiltIn = false
          ..dateAdded = DateTime.now();

        await isar.writeTxn(() async {
          await isar.songs.put(song);
        });
      }
    } catch (e) {
      debugPrint('Error importing local songs: $e');
    }
  }
  
  Future<void> deleteSong(Song song) async {
    if (song.isBuiltIn) return; // Không cho xóa nhạc built-in

    // Delete physical file
    final file = File(song.sourcePath);
    if (await file.exists()) {
      await file.delete();
    }
    
    // Delete cover art if exists
    final coverFile = File('${song.sourcePath}.png');
    if (await coverFile.exists()) {
      await coverFile.delete();
    }

    // Xóa file lyric nếu có
    final baseName = p.basenameWithoutExtension(song.fileName);
    final dir = file.parent.path;
    final possibleLyrics = [
      '$dir/$baseName.lrc',
      '$dir/$baseName.srt',
      '$dir/${baseName}_lyric.srt',
    ];
    for (final lrcPath in possibleLyrics) {
      final lrcFile = File(lrcPath);
      if (await lrcFile.exists()) {
        await lrcFile.delete();
      }
    }

    // Delete from database
    await isar.writeTxn(() async {
      await isar.songs.delete(song.id);
    });
  }
}
