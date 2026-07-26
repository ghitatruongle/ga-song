import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:ga_song/models/song.dart';
import 'package:ga_song/core/cover_art_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('resolveEntry verifies asset existence', () async {
    final repository = CoverArtRepository();

    final entry = await repository.resolveEntry(
      (Song(
        id: 1,
        name: 'test',
        sourcePath: 'assets/song/test.mp3',
        isBuiltIn: true,
      )),
    );

    expect(entry.imagePath, 'assets/pic/test.png');
    expect(entry.isAsset, isTrue);
    expect(entry.hasCover, isFalse);
  });

  test('resolveEntry works for songs in subdirectories', () async {
    final repository = CoverArtRepository();

    final entry = await repository.resolveEntry(
      (Song(
        id: 2,
        name: 'het yeu',
        sourcePath: 'assets/song/mat_nham_mat_mo/het_yeu.mp3',
        isBuiltIn: true,
      )),
    );

    expect(entry.imagePath, 'assets/pic/mat_nham_mat_mo/het_yeu.png');
    expect(entry.isAsset, isTrue);
    expect(entry.hasCover, isTrue);
  });

  test('resolveEntry for local song uses FileImage path', () async {
    final repository = CoverArtRepository();

    final entry = await repository.resolveEntry(
      Song(
        id: 3,
        name: 'local song',
        sourcePath: '/data/user/0/local_songs/test.mp3',
        isBuiltIn: false,
      ),
    );

    expect(entry.imagePath, '/data/user/0/local_songs/test.mp3.png');
    expect(entry.isAsset, isFalse);
    // File doesn't exist, so hasCover should be false
    expect(entry.hasCover, isFalse);
  });

  test(
    'resolveEntry falls back to folder cover.png when song-specific cover is missing',
    () async {
      final repository = CoverArtRepository();

      final entry = await repository.resolveEntry(
        Song(
          id: 99,
          name: 'dummy',
          sourcePath: 'assets/song/mat_nham_mat_mo/dummy.mp3',
          isBuiltIn: true,
        ),
      );

      expect(entry.imagePath, 'assets/song/mat_nham_mat_mo/cover.png');
      expect(entry.isAsset, isTrue);
      expect(entry.hasCover, isTrue);
    },
  );

  test('findLocalCoverPath checks sibling and folder covers', () {
    final tempDir = Directory.systemTemp.createTempSync('ga_song_test');
    try {
      final songFile = File('${tempDir.path}/mysong.mp3')..createSync();
      final song = Song(
        id: 101,
        name: 'local',
        sourcePath: songFile.path,
        isBuiltIn: false,
      );

      // Case 1: No cover exists
      expect(CoverArtRepository.findLocalCoverPath(song), isNull);

      // Case 2: Sibling cover.png exists
      final coverFile = File('${tempDir.path}/cover.png')..createSync();
      final resolved = CoverArtRepository.findLocalCoverPath(song);
      expect(resolved, coverFile.path.replaceAll('\\', '/'));

      // Case 3: Sibling song-specific png exists (higher priority)
      final specificCover = File('${tempDir.path}/mysong.png')..createSync();
      final resolved2 = CoverArtRepository.findLocalCoverPath(song);
      expect(resolved2, specificCover.path.replaceAll('\\', '/'));
    } finally {
      tempDir.deleteSync(recursive: true);
    }
  });
}
