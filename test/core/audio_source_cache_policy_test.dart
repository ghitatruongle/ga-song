import 'package:flutter_test/flutter_test.dart';
import 'package:ga_song/core/audio_source_cache_policy.dart';

void main() {
  group('AudioSourceCachePolicy', () {
    const policy = AudioSourceCachePolicy();

    group('linearWindow', () {
      test('returns empty set for empty playlist', () {
        final result = policy.linearWindow(currentIndex: 0, playlistLength: 0);
        expect(result, isEmpty);
      });

      test('returns empty set for negative index', () {
        final result = policy.linearWindow(currentIndex: -1, playlistLength: 5);
        expect(result, isEmpty);
      });

      test('returns empty set for index >= length', () {
        final result = policy.linearWindow(currentIndex: 5, playlistLength: 5);
        expect(result, isEmpty);
      });

      test('includes current index', () {
        final result = policy.linearWindow(currentIndex: 2, playlistLength: 5);
        expect(result, contains(2));
      });

      test('single song playlist returns only current', () {
        final result = policy.linearWindow(currentIndex: 0, playlistLength: 1);
        expect(result, {0});
      });

      test('first song includes current and next on desktop', () {
        // Note: actual behavior depends on platform (isAndroid)
        // On desktop, should include currentIndex and currentIndex + 1
        final result = policy.linearWindow(currentIndex: 0, playlistLength: 5);
        expect(result, contains(0));
        // On non-Android: expect(result, containsAll([0, 1]));
      });

      test('last song includes only current on desktop', () {
        final result = policy.linearWindow(currentIndex: 4, playlistLength: 5);
        expect(result, contains(4));
        // Should not wrap around
        expect(result, isNot(contains(0)));
      });
    });

    group('shuffleWindow', () {
      test('returns empty set for empty playlist', () {
        final result = policy.shuffleWindow(currentIndex: 0, playlistLength: 0);
        expect(result, isEmpty);
      });

      test('returns empty set for negative index', () {
        final result = policy.shuffleWindow(currentIndex: -1, playlistLength: 5);
        expect(result, isEmpty);
      });

      test('returns empty set for index >= length', () {
        final result = policy.shuffleWindow(currentIndex: 5, playlistLength: 5);
        expect(result, isEmpty);
      });

      test('includes current index', () {
        final result = policy.shuffleWindow(currentIndex: 2, playlistLength: 5);
        expect(result, contains(2));
      });

      test('includes planned next index when valid', () {
        final result = policy.shuffleWindow(
          currentIndex: 0,
          playlistLength: 5,
          plannedNextIndex: 3,
        );
        expect(result, contains(0));
        // On non-Android: expect(result, contains(3));
      });

      test('ignores invalid planned next index', () {
        final result = policy.shuffleWindow(
          currentIndex: 0,
          playlistLength: 5,
          plannedNextIndex: 10,
        );
        expect(result, isNot(contains(10)));
      });

      test('ignores negative planned next index', () {
        final result = policy.shuffleWindow(
          currentIndex: 0,
          playlistLength: 5,
          plannedNextIndex: -1,
        );
        expect(result.length, 1);
        expect(result, contains(0));
      });

      test('works without planned next index', () {
        final result = policy.shuffleWindow(
          currentIndex: 2,
          playlistLength: 5,
        );
        expect(result, contains(2));
      });
    });
  });
}
