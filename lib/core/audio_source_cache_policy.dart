import 'platform_capabilities.dart';

class AudioSourceCachePolicy {
  const AudioSourceCachePolicy();

  Set<int> linearWindow({
    required final int currentIndex,
    required final int playlistLength,
  }) {
    if (playlistLength <= 0 ||
        currentIndex < 0 ||
        currentIndex >= playlistLength) {
      return <int>{};
    }

    final keep = <int>{currentIndex};

    // Keep enough tracks in the eviction window so preloaded sources aren't
    // immediately discarded. The window is bounded by preloadConcurrency
    // (tier-aware) — on Android low it's 1, mid it's 3, desktop it's 3.
    final caps = PlatformCapabilities.instance;
    final windowSize = caps.preloadConcurrency;
    for (var i = 1; i < windowSize && currentIndex + i < playlistLength; i++) {
      keep.add(currentIndex + i);
    }
    return keep;
  }

  Set<int> shuffleWindow({
    required final int currentIndex,
    required final int playlistLength,
    final int? plannedNextIndex,
  }) {
    if (playlistLength <= 0 ||
        currentIndex < 0 ||
        currentIndex >= playlistLength) {
      return <int>{};
    }

    final keep = <int>{currentIndex};
    // Keep the planned next track if within the preload window so preloaded
    // sources survive eviction.
    final caps = PlatformCapabilities.instance;
    if (plannedNextIndex != null &&
        plannedNextIndex >= 0 &&
        plannedNextIndex < playlistLength &&
        plannedNextIndex != currentIndex) {
      keep.add(plannedNextIndex);
    }
    // Also keep sequential neighbors up to preloadConcurrency.
    for (
      var i = 1;
      i < caps.preloadConcurrency && currentIndex + i < playlistLength;
      i++
    ) {
      keep.add(currentIndex + i);
    }
    return keep;
  }
}
