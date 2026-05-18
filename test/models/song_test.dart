import 'package:flutter_test/flutter_test.dart';
import 'package:ga_song/models/song.dart';

void main() {
  group('Song Model', () {
    test('duration getter returns Duration when durationMs is set', () {
      final song = Song()
        ..name = 'Test'
        ..sourcePath = 'test.mp3'
        ..durationMs = 180000; // 3 minutes

      expect(song.duration, const Duration(minutes: 3));
    });

    test('duration getter returns null when durationMs is null', () {
      final song = Song()
        ..name = 'Test'
        ..sourcePath = 'test.mp3';

      expect(song.durationMs, isNull);
      expect(song.duration, isNull);
    });

    test('fileName extracts filename from sourcePath', () {
      final song = Song()
        ..name = 'Test'
        ..sourcePath = '/path/to/my_song.mp3';

      expect(song.fileName, 'my_song.mp3');
    });

    test('fileName handles Windows backslash paths', () {
      final song = Song()
        ..name = 'Test'
        ..sourcePath = r'C:\Users\music\song.mp3';

      expect(song.fileName, 'song.mp3');
    });

    test('fileName handles nested forward slash paths', () {
      final song = Song()
        ..name = 'Test'
        ..sourcePath = 'assets/song/album/track.mp3';

      expect(song.fileName, 'track.mp3');
    });

    test('dateAdded can be set and retrieved', () {
      final now = DateTime(2026, 5, 18);
      final song = Song()
        ..name = 'Test'
        ..sourcePath = 'test.mp3'
        ..dateAdded = now;

      expect(song.dateAdded, now);
    });

    test('dateAdded defaults to null', () {
      final song = Song()
        ..name = 'Test'
        ..sourcePath = 'test.mp3';

      expect(song.dateAdded, isNull);
    });

    test('peakDb defaults to -12.0', () {
      final song = Song()
        ..name = 'Test'
        ..sourcePath = 'test.mp3';

      expect(song.peakDb, -12.0);
    });

    test('isBuiltIn defaults to false', () {
      final song = Song()
        ..name = 'Test'
        ..sourcePath = 'test.mp3';

      expect(song.isBuiltIn, isFalse);
    });

    test('assetPath returns sourcePath', () {
      final song = Song()
        ..name = 'Test'
        ..sourcePath = 'assets/song/test.mp3';

      expect(song.assetPath, 'assets/song/test.mp3');
    });
  });
}
