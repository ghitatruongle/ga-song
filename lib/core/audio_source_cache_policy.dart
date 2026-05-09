import 'platform_capabilities.dart';

class AudioSourceCachePolicy {
  const AudioSourceCachePolicy();

  Set<int> linearWindow({
    required int currentIndex,
    required int playlistLength,
  }) {
    if (playlistLength <= 0 ||
        currentIndex < 0 ||
        currentIndex >= playlistLength) {
      return <int>{};
    }

    final keep = <int>{currentIndex};

    // P2.3: On Android (tighter RAM budget), only keep the current track.
    // On desktop, also preload next track for gapless-ready performance.
    if (!PlatformCapabilities.instance.isAndroid) {
      if (currentIndex + 1 < playlistLength) {
        keep.add(currentIndex + 1);
      }
    }
    return keep;
  }

  Set<int> shuffleWindow({
    required int currentIndex,
    required int playlistLength,
    int? plannedNextIndex,
  }) {
    if (playlistLength <= 0 ||
        currentIndex < 0 ||
        currentIndex >= playlistLength) {
      return <int>{};
    }

    final keep = <int>{currentIndex};
    // On desktop: preload the planned shuffle next track.
    // On Android: keep only current to conserve RAM.
    if (!PlatformCapabilities.instance.isAndroid) {
      if (plannedNextIndex != null &&
          plannedNextIndex >= 0 &&
          plannedNextIndex < playlistLength) {
        keep.add(plannedNextIndex);
      }
    }
    return keep;
  }
}
