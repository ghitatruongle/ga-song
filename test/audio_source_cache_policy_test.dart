import 'package:flutter_test/flutter_test.dart';
import 'package:ga_song/core/audio_source_cache_policy.dart';

void main() {
  const policy = AudioSourceCachePolicy();

  test('linear window keeps current and sequential neighbors', () {
    final result = policy.linearWindow(currentIndex: 3, playlistLength: 10);
    // Window size depends on preloadConcurrency (tier-aware).
    // On desktop (preloadConcurrency=3): {3, 4, 5}; Android low: {3}.
    expect(result, contains(3));
    expect(result.length, inInclusiveRange(1, 3));
  });

  test('linear window trims at playlist edges', () {
    // First track — includes current + sequential neighbors.
    final first = policy.linearWindow(currentIndex: 0, playlistLength: 3);
    expect(first, contains(0));
    expect(first.length, inInclusiveRange(1, 3));

    // Last track — no next exists, so only currentIndex.
    expect(
      policy.linearWindow(currentIndex: 2, playlistLength: 3),
      equals(<int>{2}),
    );
  });

  test('shuffle window keeps current and planned next', () {
    final result = policy.shuffleWindow(
      currentIndex: 4,
      playlistLength: 10,
      plannedNextIndex: 7,
    );
    expect(result, containsAll([4, 7]));
    // May also include sequential neighbors up to preloadConcurrency.
    expect(result.length, inInclusiveRange(2, 4));
  });
}
