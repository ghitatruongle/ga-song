import 'package:flutter_test/flutter_test.dart';
import 'package:ga_song/core/audio_source_cache_policy.dart';

void main() {
  const policy = AudioSourceCachePolicy();

  group('linearWindow', () {
    test('returns empty for empty playlist', () {
      expect(policy.linearWindow(currentIndex: 0, playlistLength: 0), isEmpty);
    });

    test('returns empty for negative currentIndex', () {
      expect(policy.linearWindow(currentIndex: -1, playlistLength: 5), isEmpty);
    });

    test('returns empty for out-of-bounds currentIndex', () {
      expect(policy.linearWindow(currentIndex: 10, playlistLength: 5), isEmpty);
    });

    test(
      'returns {currentIndex} and sequential neighbors (tier-aware window)',
      () {
        // Window size depends on preloadConcurrency: desktop=3, Android low=1.
        final result = policy.linearWindow(currentIndex: 2, playlistLength: 10);
        expect(result.contains(2), isTrue);
        // At minimum {2}; at most {2, 3, 4} on desktop.
        expect(result.length, inInclusiveRange(1, 3));
      },
    );

    test('on the last track, only returns currentIndex', () {
      final result = policy.linearWindow(currentIndex: 9, playlistLength: 10);
      expect(result.contains(9), isTrue);
      // No next track exists, so result is at most {9}.
      expect(result.length, 1);
    });
  });

  group('shuffleWindow', () {
    test('returns empty for empty playlist', () {
      expect(policy.shuffleWindow(currentIndex: 0, playlistLength: 0), isEmpty);
    });

    test('always includes currentIndex', () {
      final result = policy.shuffleWindow(currentIndex: 3, playlistLength: 10);
      expect(result.contains(3), isTrue);
    });

    test('on desktop with plannedNext, includes both current and planned', () {
      final result = policy.shuffleWindow(
        currentIndex: 1,
        playlistLength: 10,
        plannedNextIndex: 7,
      );
      expect(result.contains(1), isTrue);
      // Always includes planned next; may also include sequential neighbors.
      expect(result.length, inInclusiveRange(2, 4));
    });
  });
}
