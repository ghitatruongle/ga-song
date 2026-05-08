import 'package:flutter_test/flutter_test.dart';
import 'package:ga_song/core/audio_source_cache_policy.dart';

void main() {
  const policy = AudioSourceCachePolicy();

  test('linear window keeps current/next only (D5 fix - no previous)', () {
    expect(
      policy.linearWindow(currentIndex: 3, playlistLength: 10),
      equals(<int>{3, 4}),
    );
  });

  test('linear window trims at playlist edges', () {
    expect(
      policy.linearWindow(currentIndex: 0, playlistLength: 3),
      equals(<int>{0, 1}),
    );
    expect(
      policy.linearWindow(currentIndex: 2, playlistLength: 3),
      equals(<int>{2}),
    );
  });

  test('shuffle window keeps current and planned next only', () {
    expect(
      policy.shuffleWindow(
        currentIndex: 4,
        playlistLength: 10,
        plannedNextIndex: 7,
      ),
      equals(<int>{4, 7}),
    );
  });
}
