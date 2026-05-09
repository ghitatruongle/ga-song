import 'package:flutter_test/flutter_test.dart';
import 'package:ga_song/core/cover_art_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'resolveEntry always returns exists=true (graceful fallback)',
    () async {
      final repository = CoverArtRepository();

      final entry = await repository.resolveEntry('test.mp3');

      expect(entry.assetPath, 'assets/pic/test.png');
      expect(entry.hasCover, isTrue);
    },
  );

  test(
    'resolveEntry works for songs in subdirectories',
    () async {
      final repository = CoverArtRepository();

      final entry = await repository.resolveEntry('mat_nham_mat_mo/het_yeu.mp3');

      expect(entry.assetPath, 'assets/pic/mat_nham_mat_mo/het_yeu.png');
      expect(entry.hasCover, isTrue);
    },
  );
}
