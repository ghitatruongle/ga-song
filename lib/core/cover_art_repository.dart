import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:isar/isar.dart';

import 'package:ga_song/models/song.dart';
import 'package:ga_song/models/cover_art_cache.dart';
import 'service_locator.dart';
import 'settings_manager.dart';
import 'platform_capabilities.dart';
import 'services/database_service.dart';

class CoverArtEntry {
  CoverArtEntry({
    required this.fileName,
    required this.imagePath,
    required this.exists,
    required this.isAsset,
  });

  final String fileName;
  final String imagePath;
  final bool exists;
  final bool isAsset; // true = AssetImage, false = FileImage

  bool get hasCover => exists;
}

// Cache sizes are determined at runtime by PlatformCapabilities (Android vs Desktop).
// Desktop: 60 providers / 30 colors; Android: 24 providers / 15 colors.
int get _maxProviderCacheSize =>
    PlatformCapabilities.instance.maxCoverArtCacheEntries;
int get _maxDominantColorCacheSize =>
    PlatformCapabilities.instance.isAndroid ? 15 : 30;

/// Centralizes cover art existence checks, resized providers, palette cache,
/// and Isar-backed disk cache for persistence across sessions.
class CoverArtRepository with WidgetsBindingObserver {
  	  CoverArtRepository() {
  	    WidgetsBinding.instance.addObserver(this);
  	  }
  
  	  final Map<String, Future<CoverArtEntry>> _entryFutures =
  	      <String, Future<CoverArtEntry>>{};
  	  final Map<String, CoverArtEntry> _entries = <String, CoverArtEntry>{};
  
  	  // Use LinkedHashMap for zero-allocation LRU cache
  	  final LinkedHashMap<_CoverArtVariantKey, ImageProvider<Object>> _providerCache =
  	      LinkedHashMap<_CoverArtVariantKey, ImageProvider<Object>>();
  	  final LinkedHashMap<String, Future<Color?>> _dominantColorFutures =
  	      LinkedHashMap<String, Future<Color?>>();
  
  	  @override
  	  void didHaveMemoryPressure() {
  	    super.didHaveMemoryPressure();
  	    debugPrint('CoverArtRepository: Memory pressure detected. Clearing caches.');
  	    _providerCache.clear();
  	    PaintingBinding.instance.imageCache.clear();
  	    PaintingBinding.instance.imageCache.clearLiveImages();
  	  }
  
  	  void dispose() {
  	    WidgetsBinding.instance.removeObserver(this);
  	  }

  Future<void> primeForSongs(Iterable<Song> songs) async {
    await Future.wait(songs.map(resolveEntry));
  }

  Future<void> preloadNextSongs(List<Song> songs, int currentIndex, int count) async {
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
          final song = songs[idx];
          await resolveEntry(song);
          getCachedProvider(song.fileName, cacheWidth: 200, cacheHeight: 200);
        } catch (e, stack) {
          debugPrint('Failed to preload cover art for song at index $idx: $e\n$stack');
        }
      }));
    } else {
      // Android: sequential preload to prevent OOM
      for (final idx in toPreload) {
        try {
          final song = songs[idx];
          await resolveEntry(song);
          getCachedProvider(song.fileName, cacheWidth: 200, cacheHeight: 200);
        } catch (e, stack) {
          debugPrint('Failed to preload cover art for song at index $idx: $e\n$stack');
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

    // If we have the full-resolution variant cached, wrap it with ResizeImage
    // instead of creating a new FileImage/AssetImage.
    if (cacheWidth != null || cacheHeight != null) {
      final fullKey = _CoverArtVariantKey(
        fileName: fileName,
        cacheWidth: null,
        cacheHeight: null,
      );
      final fullProvider = _providerCache[fullKey];
      if (fullProvider != null) {
        final resized = ResizeImage(
          fullProvider,
          width: cacheWidth,
          height: cacheHeight,
          allowUpscaling: true,
        );
        if (_providerCache.length >= _maxProviderCacheSize) {
          _providerCache.remove(_providerCache.keys.first);
        }
        _providerCache[key] = resized;
        return resized;
      }
    }

    if (_providerCache.length >= _maxProviderCacheSize) {
      _providerCache.remove(_providerCache.keys.first);
    }

    final ImageProvider<Object> baseProvider = entry.isAsset
        ? AssetImage(entry.imagePath)
        : FileImage(File(entry.imagePath)) as ImageProvider<Object>;

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

  Future<CoverArtEntry> resolveEntry(Song song) {
    return _entryFutures.putIfAbsent(song.fileName, () async {
      String imagePath;
      bool exists = false;
      bool isAsset = false;

      if (song.isBuiltIn) {
        // Built-in asset: map audio path to image path
        imagePath = _builtInCoverPath(song);
        isAsset = true;
        try {
          await rootBundle.load(imagePath);
          exists = true;
        } catch (e, stack) { debugPrint('Error in cover_art_repository: $e\n$stack');
          exists = false;
        }
      } else {
        // Local file: cover is stored alongside source as <sourcePath>.png
        imagePath = '${song.sourcePath}.png';
        isAsset = false;
        exists = File(imagePath).existsSync();
      }

      final entry = CoverArtEntry(
        fileName: song.fileName,
        imagePath: imagePath,
        exists: exists,
        isAsset: isAsset,
      );
      _entries[song.fileName] = entry;

      // Pre-populate the in-memory provider cache from disk (Isar) or file/asset.
      if (entry.hasCover) {
        _prepopulateProviderFromDiskOrSource(entry, song.fileName);
      }

      return entry;
    });
  }

  /// Fire-and-forget: loads cover bytes (from Isar disk cache or source file)
  /// and pre-populates the in-memory [ImageProvider] cache.
  Future<void> _prepopulateProviderFromDiskOrSource(
    CoverArtEntry entry,
    String fileName,
  ) async {
    try {
      Uint8List? bytes;

      // 1. Try Isar disk cache first (persisted from a previous session).
      try {
        final db = sl<DatabaseService>();
        final cached = await db.isar.coverArtCaches.getByFileName(fileName);
        if (cached != null) {
          bytes = Uint8List.fromList(cached.bytes);
          // Update LRU access timestamp (fire-and-forget, don't fail the read)
          try {
            cached.lastAccessed = DateTime.now();
            await db.isar.writeTxn(() => db.isar.coverArtCaches.put(cached));
          } catch (writeError) {
            if (writeError.toString().contains('database is full')) {
              // Evict oldest entries to free space, then retry once
              await _forceEvictDiskCache();
              try {
                cached.lastAccessed = DateTime.now();
                await db.isar.writeTxn(() => db.isar.coverArtCaches.put(cached));
              } catch (_) {}
            }
          }
        }
      } catch (e, stack) {
        debugPrint("CoverArtRepo disk cache error: $e\n$stack");
        // Isar not ready yet — will fall through to source load
      }

      // 2. If disk cache missed, load from the original source.
      if (bytes == null) {
        bytes = await _loadCoverBytes(entry);

        // Save to Isar disk cache for future sessions (fire-and-forget).
        if (bytes != null) {
          _saveToDiskCache(fileName, bytes);
        }
      }

      // 3. Pre-populate the in-memory provider cache.
      if (bytes != null) {
        final provider = MemoryImage(bytes);
        final key = _CoverArtVariantKey(
          fileName: fileName,
          cacheWidth: null,
          cacheHeight: null,
        );
        // LRU eviction before insert
        if (_providerCache.length >= _maxProviderCacheSize) {
          _providerCache.remove(_providerCache.keys.first);
        }
        _providerCache[key] = provider;
      }
    } catch (e, stack) {
      debugPrint('Failed to pre-populate cover art for $fileName: $e\n$stack');
    }
  }

  /// Loads raw image bytes from the asset bundle or local file.
  Future<Uint8List?> _loadCoverBytes(CoverArtEntry entry) async {
    try {
      if (entry.isAsset) {
        final data = await rootBundle.load(entry.imagePath);
        // Use offset & length to get only the relevant bytes from the buffer
        return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      } else {
        final file = File(entry.imagePath);
        if (await file.exists()) {
          return await file.readAsBytes();
        }
      }
    } catch (e, stack) {
      debugPrint('Failed to load cover bytes: $e\n$stack');
    }
    return null;
  }

  /// Saves cover bytes to the Isar disk cache, evicting oldest entries first if needed.
  Future<void> _saveToDiskCache(String fileName, Uint8List bytes) async {
    try {
      final db = sl<DatabaseService>();

      // Evict BEFORE saving to ensure there's space.
      await _evictDiskCache();

      final existing = await db.isar.coverArtCaches.getByFileName(fileName);

      await db.isar.writeTxn(() async {
        if (existing != null) {
          existing
            ..bytes = bytes.toList()
            ..lastAccessed = DateTime.now();
          await db.isar.coverArtCaches.put(existing);
        } else {
          await db.isar.coverArtCaches.put(CoverArtCache()
            ..fileName = fileName
            ..bytes = bytes.toList()
            ..lastAccessed = DateTime.now());
        }
      });
    } catch (e, stack) {
      // If save failed (e.g. database full), force-evict and retry once.
      if (e.toString().contains('database is full')) {
        await _forceEvictDiskCache();
        try {
          final db = sl<DatabaseService>();
          await db.isar.writeTxn(() async {
            await db.isar.coverArtCaches.put(CoverArtCache()
              ..fileName = fileName
              ..bytes = bytes.toList()
              ..lastAccessed = DateTime.now());
          });
        } catch (retryError, retryStack) {
          debugPrint('Failed to save cover art after eviction: $retryError\n$retryStack');
        }
      } else {
        debugPrint('Failed to save cover art to disk cache: $e\n$stack');
      }
    }
  }

  /// LRU-evicts oldest disk cache entries if the total exceeds the limit.
  Future<void> _evictDiskCache() async {
    try {
      final maxEntries =
          CoverArtCache.maxDiskCacheEntries(PlatformCapabilities.instance.isAndroid);
      final db = sl<DatabaseService>();
      final count = await db.isar.coverArtCaches.count();
      if (count <= maxEntries) return;

      final toRemove = count - maxEntries;
      final allEntries = await db.isar.coverArtCaches.where().anyId().findAll();
      allEntries.sort((a, b) => a.lastAccessed.compareTo(b.lastAccessed));
      final oldest = allEntries.take(toRemove).toList();

      await db.isar.writeTxn(() async {
        for (final entry in oldest) {
          await db.isar.coverArtCaches.delete(entry.id);
        }
      });
    } catch (e, stack) {
      debugPrint('Failed to evict disk cache: $e\n$stack');
    }
  }

  /// Force-evicts half of the disk cache to free space when database is full.
  Future<void> _forceEvictDiskCache() async {
    try {
      final db = sl<DatabaseService>();
      final count = await db.isar.coverArtCaches.count();
      if (count == 0) return;

      final toRemove = (count / 2).ceil();
      final allEntries = await db.isar.coverArtCaches.where().anyId().findAll();
      allEntries.sort((a, b) => a.lastAccessed.compareTo(b.lastAccessed));
      final oldest = allEntries.take(toRemove).toList();

      await db.isar.writeTxn(() async {
        for (final entry in oldest) {
          await db.isar.coverArtCaches.delete(entry.id);
        }
      });
      debugPrint('Force-evicted $toRemove disk cache entries');
    } catch (e, stack) {
      debugPrint('Failed to force-evict disk cache: $e\n$stack');
    }
  }

  /// Invalidate cache for a single song (e.g. after cover art is written to disk)
  void invalidateEntry(Song song) {
    _entryFutures.remove(song.fileName);
    _entries.remove(song.fileName);
    // Also remove all provider variants for this song
    _providerCache.removeWhere((key, _) => key.fileName == song.fileName);
    _dominantColorFutures.remove(song.fileName);
    // Also remove from disk cache
    _removeFromDiskCache(song.fileName);
  }

  /// Removes a single entry from the disk cache.
  Future<void> _removeFromDiskCache(String fileName) async {
    try {
      final db = sl<DatabaseService>();
      final cached = await db.isar.coverArtCaches.getByFileName(fileName);
      if (cached != null) {
        await db.isar.writeTxn(() => db.isar.coverArtCaches.delete(cached.id));
      }
    } catch (e, stack) { debugPrint("CoverArtRepo remove disk cache error: $e\n$stack"); }
  }

  Future<Color?> resolveDominantColor(
    Song song, {
    int paletteWidth = 192,
    int paletteHeight = 192,
  }) {
    if (_dominantColorFutures.containsKey(song.fileName)) {
      // Move to end
      final future = _dominantColorFutures.remove(song.fileName)!;
      _dominantColorFutures[song.fileName] = future;
      return future;
    }

    if (_dominantColorFutures.length >= _maxDominantColorCacheSize) {
      _dominantColorFutures.remove(_dominantColorFutures.keys.first);
    }

    final future = _resolveDominantColorAsync(
      song,
      paletteWidth,
      paletteHeight,
    );
    _dominantColorFutures[song.fileName] = future;
    return future;
  }

  Future<Color?> _resolveDominantColorAsync(
    Song song,
    int paletteWidth,
    int paletteHeight,
  ) async {
    // 1. Check persistent cache first — instant return (~0ms)
    final cachedColor = sl<SettingsManager>().getSongColor(song.fileName);
    if (cachedColor != null) {
      return cachedColor;
    }

    // 2. Compute from image (expensive, ~100-200ms — only once per song ever)
    final entry = await resolveEntry(song);
    if (!entry.hasCover) {
      return null;
    }

    final provider = getCachedProvider(
      song.fileName,
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
      await sl<SettingsManager>().saveSongColor(song.fileName, color);
      return color;
    } catch (e, stack) {
      debugPrint('Failed to compute dominant color (image might not exist): $e\n$stack');
      return null;
    }
  }

  /// Maps built-in song source path to cover art asset path.
  /// e.g. assets/song/mat_nham_mat_mo/song.mp3 → assets/pic/mat_nham_mat_mo/song.png
  static String _builtInCoverPath(Song song) {
    final path = song.sourcePath;
    // Replace the audio folder prefix and extension
    final picPath = path
        .replaceFirst('assets/song/', 'assets/pic/')
        .replaceAll(RegExp(r'\.(mp3|flac|wav|m4a)$'), '.png');
    return picPath;
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
