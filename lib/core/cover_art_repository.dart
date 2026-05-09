import 'dart:collection';

import 'package:flutter/material.dart';

import '../song_model.dart';
import 'service_locator.dart';
import 'settings_manager.dart';
import 'platform_capabilities.dart';

class CoverArtEntry {
  CoverArtEntry({
    required this.fileName,
    required this.assetPath,
    required this.exists,
  });

  final String fileName;
  final String assetPath;
  final bool exists;

  bool get hasCover => exists;
}

// Cache sizes are determined at runtime by PlatformCapabilities (Android vs Desktop).
// Desktop: 60 providers / 30 colors; Android: 24 providers / 20 colors.
int get _maxProviderCacheSize =>
    PlatformCapabilities.instance.maxCoverArtCacheEntries;
const int _maxDominantColorCacheSize = 30;

/// Centralizes cover art existence checks, resized providers and palette cache.
class CoverArtRepository with WidgetsBindingObserver {
  CoverArtRepository() {
    WidgetsBinding.instance.addObserver(this);
  }

  final Map<String, Future<CoverArtEntry>> _entryFutures =
      <String, Future<CoverArtEntry>>{};
  final Map<String, CoverArtEntry> _entries = <String, CoverArtEntry>{};
  
  // P2.4: Use LinkedHashMap for zero-allocation LRU cache
  final LinkedHashMap<_CoverArtVariantKey, ImageProvider<Object>> _providerCache =
      LinkedHashMap<_CoverArtVariantKey, ImageProvider<Object>>();
  final LinkedHashMap<String, Future<Color?>> _dominantColorFutures =
      LinkedHashMap<String, Future<Color?>>();

  @override
  void didHaveMemoryPressure() {
    super.didHaveMemoryPressure();
    // P2.2: Memory pressure callback (Android didHaveMemoryPressure)
    debugPrint('CoverArtRepository: Memory pressure detected. Clearing caches.');
    _providerCache.clear();
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
  }

  Future<void> primeForSongs(Iterable<String> fileNames) async {
    await Future.wait(fileNames.map(resolveEntry));
  }

  Future<void> preloadNextSongs(List<SongModel> songs, int currentIndex, int count) async {
    final concurrency = PlatformCapabilities.instance.preloadConcurrency;
    final toPreload = <int>[];
    for (int i = 1; i <= count; i++) {
      final nextIndex = (currentIndex + i) % songs.length;
      if (nextIndex != currentIndex) {
        toPreload.add(nextIndex);
      }
    }

    if (concurrency >= toPreload.length) {
      // Desktop: parallel preload
      await Future.wait(toPreload.map((idx) async {
        try {
          final fileName = songs[idx].fileName;
          await resolveEntry(fileName);
          getCachedProvider(fileName, cacheWidth: 200, cacheHeight: 200);
        } catch (e) {
          debugPrint('Failed to preload cover art for song at index $idx: $e');
        }
      }));
    } else {
      // Android: sequential preload to prevent OOM
      for (final idx in toPreload) {
        try {
          final fileName = songs[idx].fileName;
          await resolveEntry(fileName);
          getCachedProvider(fileName, cacheWidth: 200, cacheHeight: 200);
        } catch (e) {
          debugPrint('Failed to preload cover art for song at index $idx: $e');
        }
      }
    }
  }

  CoverArtEntry? getCachedEntry(String fileName) => _entries[fileName];

  ImageProvider<Object>? getCachedProvider(
    String fileName, {
    int? cacheWidth,
    int? cacheHeight,
  }) {
    final entry = _entries[fileName];
    if (entry == null || !entry.hasCover) {
      return null;
    }

    final key = _CoverArtVariantKey(
      fileName: fileName,
      cacheWidth: cacheWidth,
      cacheHeight: cacheHeight,
    );

    if (_providerCache.containsKey(key)) {
      // Move to end (most recently used)
      final provider = _providerCache.remove(key)!;
      _providerCache[key] = provider;
      return provider;
    }

    if (_providerCache.length >= _maxProviderCacheSize) {
      _providerCache.remove(_providerCache.keys.first);
    }

    final ImageProvider<Object> baseProvider = AssetImage(entry.assetPath);
    final ImageProvider<Object> provider =
        cacheWidth == null && cacheHeight == null
        ? baseProvider
        : ResizeImage(
            baseProvider,
            width: cacheWidth,
            height: cacheHeight,
            allowUpscaling: true,
          );

    _providerCache[key] = provider;
    return provider;
  }

  Future<CoverArtEntry> resolveEntry(String fileName) {
    return _entryFutures.putIfAbsent(fileName, () async {
      final assetPath = _coverPath(fileName);
      final entry = CoverArtEntry(
        fileName: fileName,
        assetPath: assetPath,
        exists: true, // We assume true and let AssetImage fail gracefully
      );
      _entries[fileName] = entry;
      return entry;
    });
  }

  Future<Color?> resolveDominantColor(
    String fileName, {
    int paletteWidth = 192,
    int paletteHeight = 192,
  }) {
    if (_dominantColorFutures.containsKey(fileName)) {
      // Move to end
      final future = _dominantColorFutures.remove(fileName)!;
      _dominantColorFutures[fileName] = future;
      return future;
    }

    if (_dominantColorFutures.length >= _maxDominantColorCacheSize) {
      _dominantColorFutures.remove(_dominantColorFutures.keys.first);
    }

    final future = _resolveDominantColorAsync(
      fileName,
      paletteWidth,
      paletteHeight,
    );
    _dominantColorFutures[fileName] = future;
    return future;
  }

  Future<Color?> _resolveDominantColorAsync(
    String fileName,
    int paletteWidth,
    int paletteHeight,
  ) async {
    // 1. Check persistent cache first — instant return (~0ms)
    final cachedColor = sl<SettingsManager>().getSongColor(fileName);
    if (cachedColor != null) {
      return cachedColor;
    }

    // 2. Compute from image (expensive, ~100-200ms — only once per song ever)
    final entry = await resolveEntry(fileName);
    if (!entry.hasCover) {
      return null;
    }

    final provider = getCachedProvider(
      fileName,
      cacheWidth: paletteWidth,
      cacheHeight: paletteHeight,
    );
    if (provider == null) {
      return null;
    }

    try {
      final colorScheme = await ColorScheme.fromImageProvider(provider: provider);
      final color = colorScheme.primary;

      // 3. Persist to disk so we never compute again
      await sl<SettingsManager>().saveSongColor(fileName, color);
      return color;
    } catch (e) {
      debugPrint('Failed to compute dominant color (image might not exist): $e');
      return null;
    }
  }



  static String _coverPath(String fileName) {
    return 'assets/pic/${fileName.replaceAll('.mp3', '.png')}';
  }
}

@immutable
class _CoverArtVariantKey {
  const _CoverArtVariantKey({
    required this.fileName,
    required this.cacheWidth,
    required this.cacheHeight,
  });

  final String fileName;
  final int? cacheWidth;
  final int? cacheHeight;

  @override
  bool operator ==(Object other) {
    return other is _CoverArtVariantKey &&
        other.fileName == fileName &&
        other.cacheWidth == cacheWidth &&
        other.cacheHeight == cacheHeight;
  }

  @override
  int get hashCode => Object.hash(fileName, cacheWidth, cacheHeight);
}
