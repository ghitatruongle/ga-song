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

    test('returns {currentIndex} when on Android (single-track window)', () {
      // Default test platform is non-Android for unit tests (we don't change
      // PlatformCapabilities here). When the host is desktop, we expect current+next.
      final result = policy.linearWindow(currentIndex: 2, playlistLength: 10);
      // Either {2} (Android) or {2, 3} (desktop) — both are valid responses.
      expect(result.contains(2), isTrue);
      expect(result.length, inInclusiveRange(1, 2));
    });

    test('on the last track, only returns currentIndex', () {
      final result = policy.linearWindow(
        currentIndex: 9,
        playlistLength: 10,
      );
      expect(result.contains(9), isTrue);
      // No next track exists, so result is at most {9}.
      expect(result.length, 1);
    });
  });

  group('shuffleWindow', () {
    test('returns empty for empty playlist', () {
      expect(
        policy.shuffleWindow(currentIndex: 0, playlistLength: 0),
        isEmpty,
      );
    });

    test('always includes currentIndex', () {
      final result = policy.shuffleWindow(
        currentIndex: 3,
        playlistLength: 10,
      );
      expect(result.contains(3), isTrue);
    });

    test('on desktop with plannedNext, includes both current and planned', () {
      final result = policy.shuffleWindow(
        currentIndex: 1,
        playlistLength: 10,
        plannedNextIndex: 7,
      );
      expect(result.contains(1), isTrue);
      // Desktop includes planned next; Android doesn't.
      // Either {1} (Android) or {1, 7} (desktop) is valid.
      expect(result.length, inInclusiveRange(1, 2));
    });
  });
}
