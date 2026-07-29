import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ga_song/core/database/app_database.dart';
import 'package:ga_song/core/services/db_service_wrapper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DatabaseServiceWrapper built-in seeding', () {
    late AppDatabase db;
    late DatabaseServiceWrapper wrapper;

    setUp(() {
      db = AppDatabase(executor: NativeDatabase.memory());
      wrapper = DatabaseServiceWrapper(db);
    });

    tearDown(() async {
      wrapper.dispose();
      await db.close();
    });

    test('init seeds built-in songs from songs.json into an empty DB',
        () async {
      await wrapper.init();

      final songs = await wrapper.getAllSongs();
      expect(songs, isNotEmpty,
          reason: 'fresh install must not show an empty library');
      expect(songs.every((s) => s.isBuiltIn), isTrue);
      expect(
        songs.every((s) => s.sourcePath.startsWith('assets/song/')),
        isTrue,
      );
      // Metadata from songs.json is applied (not derived from file names).
      expect(songs.any((s) => s.name == 'Chờ Anh Về'), isTrue);
    });

    test('re-running init is idempotent (no duplicates)', () async {
      await wrapper.init();
      final first = await wrapper.getAllSongs();

      await wrapper.init();
      final second = await wrapper.getAllSongs();

      expect(second.length, first.length);
    });

    test('re-seeds when built-in rows were partially deleted', () async {
      await wrapper.init();
      final seeded = await wrapper.getAllSongs();

      // Simulate a corrupt/partial library.
      await wrapper.deleteSong(seeded.first.id!);

      await wrapper.init();
      final restored = await wrapper.getAllSongs();
      expect(restored.length, seeded.length);
    });
  });
}
