import 'package:flutter_test/flutter_test.dart';
import 'package:ga_song/models/song.dart';
import 'package:ga_song/core/cover_art_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'resolveEntry verifies asset existence',
    () async {
      final repository = CoverArtRepository();

      final entry = await repository.resolveEntry((Song(id: 1, name: 'test', sourcePath: 'assets/song/test.mp3', isBuiltIn: true)));

      expect(entry.imagePath, 'assets/pic/test.png');
      expect(entry.isAsset, isTrue);
      expect(entry.hasCover, isFalse);
    },
  );

  test(
    'resolveEntry works for songs in subdirectories',
    () async {
      final repository = CoverArtRepository();

      final entry = await repository.resolveEntry((Song(id: 2, name: 'het yeu', sourcePath: 'assets/song/mat_nham_mat_mo/het_yeu.mp3', isBuiltIn: true)));

      expect(entry.imagePath, 'assets/pic/mat_nham_mat_mo/het_yeu.png');
      expect(entry.isAsset, isTrue);
      expect(entry.hasCover, isTrue);
    },
  );

  test(
    'resolveEntry for local song uses FileImage path',
    () async {
      final repository = CoverArtRepository();

      final entry = await repository.resolveEntry(Song(
        id: 3,
        name: 'local song',
        sourcePath: '/data/user/0/local_songs/test.mp3',
        isBuiltIn: false,
      ));

      expect(entry.imagePath, '/data/user/0/local_songs/test.mp3.png');
      expect(entry.isAsset, isFalse);
      // File doesn't exist, so hasCover should be false
      expect(entry.hasCover, isFalse);
    },
  );
}
