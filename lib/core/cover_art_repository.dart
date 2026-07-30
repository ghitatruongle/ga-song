import 'logging/app_logger.dart';
import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/song.dart';
import '../models/cover_art_cache.dart';
import 'settings_manager.dart';
import 'platform_capabilities.dart';
import 'services/db_service_wrapper.dart';
import 'performance_probe.dart';

/// P3.3: cache entries older than this are evicted even if LRU hasn't
/// pushed them out. Conservative default per plan.
const Duration _coverArtTtl = Duration(hours: 1);

class CoverArtEntry {
  CoverArtEntry({
    required this.fileName,
    required this.imagePath,
    required this.exists,
    required this.isAsset,
    DateTime? capturedAt,
  }) : capturedAt = capturedAt ?? DateTime.now();

  final String fileName;
  final String imagePath;
  final bool exists;
  final bool isAsset; // true = AssetImage, false = FileImage

  /// When this entry was created. Used for TTL eviction. Defaults to
  /// `DateTime.now()` at construction time.
  final DateTime capturedAt;

  /// True when [capturedAt] is within [ttl] from `DateTime.now()`.
  bool isFresh({required Duration ttl}) {
    return DateTime.now().difference(capturedAt) < ttl;
  }

  bool get hasCover => exists;
}

// Cache sizes are determined at runtime by PlatformCapabilities (Android vs Desktop).
// Desktop: 60 providers / 30 colors; Android: 24 providers / 15 colors.
int get _maxProviderCacheSize =>
    PlatformCapabilities.instance.maxCoverArtCacheEntries;
int get _maxDominantColorCacheSize =>
    PlatformCapabilities.instance.isAndroid ? 15 : 30;

/// Centralizes cover art existence checks, resized providers, palette cache,
/// and SQLite-backed disk cache for persistence across sessions.
///
/// Dependencies are injected via constructor for testability.
class CoverArtRepository with WidgetsBindingObserver {
  CoverArtRepository({
    DatabaseServiceWrapper? databaseService,
    SettingsManager? settingsManager,
  }) : _databaseService = databaseService,
       _settingsManager = settingsManager {
    WidgetsBinding.instance.addObserver(this);
  }

  final DatabaseServiceWrapper? _databaseService;
  final SettingsManager? _settingsManager;

  final Map<String, Future<CoverArtEntry>> _entryFutures =
      <String, Future<CoverArtEntry>>{};
  final Map<String, CoverArtEntry> _entries = <String, CoverArtEntry>{};

  final LinkedHashMap<_CoverArtVariantKey, ImageProvider<Object>>
  _providerCache = LinkedHashMap<_CoverArtVariantKey, ImageProvider<Object>>();
  final LinkedHashMap<String, Future<Color?>> _dominantColorFutures =
      LinkedHashMap<String, Future<Color?>>();

  @override
  void didHaveMemoryPressure() {
    super.didHaveMemoryPressure();
    AppLogger.i(
      'cover_art.repository',
      'Memory pressure detected; clearing caches',
    );
    _providerCache.clear();
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _entryFutures.clear();
    _entries.clear();
    _providerCache.clear();
    _dominantColorFutures.clear();
  }

  /// Reports current provider cache size to [PerformanceProbe].
  void _reportCacheSize() {
    PerformanceProbe.instance.recordCacheSize(_providerCache.length);
  }

  Future<void> primeForSongs(Iterable<Song> songs) async {
    await Future.wait(songs.map(resolveEntry));
  }

  Future<void> preloadNextSongs(
    List<Song> songs,
    int currentIndex,
    int count,
  ) async {
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
      await Future.wait(
        toPreload.map((idx) async {
          try {
            final song = songs[idx];
            await resolveEntry(song);
            getCachedProvider(song.fileName, cacheWidth: 200, cacheHeight: 200);
            PerformanceProbe.instance.recordPreload();
          } catch (e, stack) {
            AppLogger.w(
              'cover_art.repository',
              'preload cover art failed at index $idx',
              error: e,
              stack: stack,
            );
          }
        }),
      );
    } else {
      // Android: sequential preload to prevent OOM
      for (final idx in toPreload) {
        try {
          final song = songs[idx];
          await resolveEntry(song);
          getCachedProvider(song.fileName, cacheWidth: 200, cacheHeight: 200);
          PerformanceProbe.instance.recordPreload();
        } catch (e, stack) {
          AppLogger.w(
            'cover_art.repository',
            'preload cover art failed at index $idx',
            error: e,
            stack: stack,
          );
        }
      }
    }
  }

  CoverArtEntry? getCachedEntry(String fileName) {
    final entry = _entries[fileName];
    if (entry != null && !entry.isFresh(ttl: _coverArtTtl)) {
      _evictStaleEntry(fileName);
      return null;
    }
    return entry;
  }

  /// Removes a stale entry from all in-memory caches for [fileName].
  void _evictStaleEntry(String fileName) {
    _entries.remove(fileName);
    _entryFutures.remove(fileName);
    _providerCache.removeWhere((key, _) => key.fileName == fileName);
    _dominantColorFutures.remove(fileName);
  }

  ImageProvider<Object>? getCachedProvider(
    String fileName, {
    int? cacheWidth,
    int? cacheHeight,
  }) {
    final entry = _entries[fileName];
    if (entry == null || !entry.hasCover) {
      return null;
    }

    if (!entry.isFresh(ttl: _coverArtTtl)) {
      _evictStaleEntry(fileName);
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
          PerformanceProbe.instance.recordEviction();
        }
        _providerCache[key] = resized;
        _reportCacheSize();
        return resized;
      }
    }

    if (_providerCache.length >= _maxProviderCacheSize) {
      _providerCache.remove(_providerCache.keys.first);
      PerformanceProbe.instance.recordEviction();
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
    _reportCacheSize();
    return provider;
  }

  Future<CoverArtEntry> resolveEntry(Song song) {
    return _entryFutures.putIfAbsent(song.fileName, () async {
      String imagePath;
      bool exists = false;
      bool isAsset = false;

      if (song.isBuiltIn) {
        isAsset = true;
        final resolved = await findCoverAssetPath(song);
        if (resolved != null) {
          imagePath = resolved;
          exists = true;
        } else {
          imagePath = _builtInCoverPath(song);
          exists = false;
        }
      } else {
        isAsset = false;
        final resolved = findLocalCoverPath(song);
        if (resolved != null) {
          imagePath = resolved;
          exists = true;
        } else {
          imagePath = '${song.sourcePath}.png';
          exists = false;
        }
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

      // 1. Try SQLite disk cache first (persisted from a previous session).
      try {
        final db = _databaseService;
        if (db == null) return;
        final cached = await db.getCoverArtCacheByFileName(fileName);
        if (cached != null) {
          bytes = Uint8List.fromList(cached.bytes);
          // Update LRU access timestamp (fire-and-forget, don't fail the read)
          try {
            cached.lastAccessed = DateTime.now();
            await db.putCoverArtCache(cached);
          } catch (writeError) {
            if (writeError.toString().contains('database is full')) {
              // Evict oldest entries to free space, then retry once
              await _forceEvictDiskCache();
              try {
                cached.lastAccessed = DateTime.now();
                await db.putCoverArtCache(cached);
              } catch (retryError) {
                AppLogger.w(
                  'cover_art.repository',
                  'LRU timestamp retry write failed after eviction',
                  error: retryError,
                );
              }
            }
          }
        }
      } catch (e, stack) {
        AppLogger.w(
          'cover_art.repository',
          'disk cache error',
          error: e,
          stack: stack,
        );
        // Database not ready yet — will fall through to source load
      }

      // 2. If disk cache missed, load from the original source.
      if (bytes == null) {
        bytes = await _loadCoverBytes(entry);

        // Save to SQLite disk cache for future sessions (fire-and-forget).
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
          PerformanceProbe.instance.recordEviction();
        }
        _providerCache[key] = provider;
        _reportCacheSize();
      }
    } catch (e, stack) {
      AppLogger.w(
        'cover_art.repository',
        'pre-populate failed for $fileName',
        error: e,
        stack: stack,
      );
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
      AppLogger.w(
        'cover_art.repository',
        'load cover bytes failed',
        error: e,
        stack: stack,
      );
    }
    return null;
  }

  /// Saves cover bytes to the SQLite disk cache, evicting oldest entries first if needed.
  Future<void> _saveToDiskCache(String fileName, Uint8List bytes) async {
    final db = _databaseService;
    if (db == null) return;
    try {
      // Evict BEFORE saving to ensure there's space.
      await _evictDiskCache();

      final existing = await db.getCoverArtCacheByFileName(fileName);

      if (existing != null) {
        existing
          ..bytes = bytes.toList()
          ..lastAccessed = DateTime.now();
        await db.putCoverArtCache(existing);
      } else {
        await db.putCoverArtCache(
          CoverArtCache(
            fileName: fileName,
            bytes: bytes.toList(),
            lastAccessed: DateTime.now(),
          ),
        );
      }
    } catch (e, stack) {
      // If save failed (e.g. database full), force-evict and retry once.
      if (e.toString().contains('database is full')) {
        await _forceEvictDiskCache();
        try {
          final db = _databaseService;
          if (db == null) return;
          await db.putCoverArtCache(
            CoverArtCache(
              fileName: fileName,
              bytes: bytes.toList(),
              lastAccessed: DateTime.now(),
            ),
          );
        } catch (retryError, retryStack) {
          AppLogger.w(
            'cover_art.repository',
            'save after eviction failed',
            error: retryError,
            stack: retryStack,
          );
        }
      } else {
        AppLogger.w(
          'cover_art.repository',
          'save cover art failed',
          error: e,
          stack: stack,
        );
      }
    }
  }

  /// LRU-evicts oldest disk cache entries if the total exceeds the limit.
  Future<void> _evictDiskCache() async {
    final db = _databaseService;
    if (db == null) return;
    try {
      final maxEntries = CoverArtCache.maxDiskCacheEntries(
        PlatformCapabilities.instance.isAndroid,
      );
      final count = await db.getCoverArtCacheCount();
      if (count <= maxEntries) return;

      final toRemove = count - maxEntries;
      final allEntries = await db.getAllCoverArtCaches();
      allEntries.sort((a, b) => a.lastAccessed.compareTo(b.lastAccessed));
      final oldest = allEntries.take(toRemove).toList();

      await db.deleteCoverArtCachesByFileNames(
        oldest.map((e) => e.fileName).toList(),
      );
    } catch (e, stack) {
      AppLogger.w(
        'cover_art.repository',
        'evict disk cache failed',
        error: e,
        stack: stack,
      );
    }
  }

  /// Force-evicts half of the disk cache to free space when database is full.
  Future<void> _forceEvictDiskCache() async {
    final db = _databaseService;
    if (db == null) return;
    try {
      final count = await db.getCoverArtCacheCount();
      if (count == 0) return;

      final toRemove = (count / 2).ceil();
      final allEntries = await db.getAllCoverArtCaches();
      allEntries.sort((a, b) => a.lastAccessed.compareTo(b.lastAccessed));
      final oldest = allEntries.take(toRemove).toList();

      await db.deleteCoverArtCachesByFileNames(
        oldest.map((e) => e.fileName).toList(),
      );
      AppLogger.i('cover_art.repository', 'force-evicted \$toRemove entries');
    } catch (e, stack) {
      AppLogger.w(
        'cover_art.repository',
        'force-evict failed',
        error: e,
        stack: stack,
      );
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
    final db = _databaseService;
    if (db == null) return;
    try {
      final cached = await db.getCoverArtCacheByFileName(fileName);
      if (cached != null) {
        await db.deleteCoverArtCache(fileName);
      }
    } catch (e, stack) {
      AppLogger.w(
        'cover_art.repository',
        'remove disk cache error',
        error: e,
        stack: stack,
      );
    }
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
    final cachedColor = _settingsManager?.getSongColor(song.fileName);
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
      final colorScheme = await ColorScheme.fromImageProvider(
        provider: provider,
      );
      final color = colorScheme.primary;

      // 3. Persist to disk so we never compute again
      await _settingsManager?.saveSongColor(song.fileName, color);
      return color;
    } catch (e, stack) {
      AppLogger.w(
        'cover_art.repository',
        'compute dominant color failed',
        error: e,
        stack: stack,
      );
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

  /// Attempts to find a cover art asset path for a built-in song by checking various locations.
  /// Returns the first path that successfully loads, or null if none are found.
  static Future<String?> findCoverAssetPath(Song song) async {
    if (!song.isBuiltIn) return null;

    final path = song.sourcePath.replaceAll('\\', '/');
    final lastSlash = path.lastIndexOf('/');
    final parentDir = lastSlash != -1 ? path.substring(0, lastSlash) : '';
    final lastDot = path.lastIndexOf('.');
    final fileNameWithoutExt = (lastDot != -1 && lastDot > lastSlash)
        ? path.substring(lastSlash + 1, lastDot)
        : (lastSlash != -1 ? path.substring(lastSlash + 1) : path);

    // List of candidate paths in order of preference
    final candidates = [
      // 1. Default mapped path (assets/pic/...)
      path
          .replaceFirst('assets/song/', 'assets/pic/')
          .replaceAll(RegExp(r'\.(mp3|flac|wav|m4a)$'), '.png'),
      path
          .replaceFirst('assets/song/', 'assets/pic/')
          .replaceAll(RegExp(r'\.(mp3|flac|wav|m4a)$'), '.jpg'),
      path
          .replaceFirst('assets/song/', 'assets/pic/')
          .replaceAll(RegExp(r'\.(mp3|flac|wav|m4a)$'), '.jpeg'),

      // 2. Sibling path in same folder (assets/song/...)
      '$parentDir/$fileNameWithoutExt.png',
      '$parentDir/$fileNameWithoutExt.jpg',
      '$parentDir/$fileNameWithoutExt.jpeg',

      // 3. Album cover in same folder
      '$parentDir/cover.png',
      '$parentDir/cover.jpg',
      '$parentDir/cover.jpeg',
      '$parentDir/folder.png',
      '$parentDir/folder.jpg',
      '$parentDir/folder.jpeg',

      // 4. Album cover in pic folder
      '${parentDir.replaceFirst('assets/song/', 'assets/pic/')}/cover.png',
      '${parentDir.replaceFirst('assets/song/', 'assets/pic/')}/cover.jpg',
      '${parentDir.replaceFirst('assets/song/', 'assets/pic/')}/cover.jpeg',
      '${parentDir.replaceFirst('assets/song/', 'assets/pic/')}/folder.png',
      '${parentDir.replaceFirst('assets/song/', 'assets/pic/')}/folder.jpg',
      '${parentDir.replaceFirst('assets/song/', 'assets/pic/')}/folder.jpeg',
    ];

    for (final candidate in candidates) {
      try {
        await rootBundle.load(candidate);
        return candidate;
      } catch (_) {
        // Continue to next candidate
      }
    }

    return null;
  }

  /// Attempts to find a cover art image path for a local song by checking various locations.
  /// Returns the first path that exists, or null if none are found.
  static String? findLocalCoverPath(Song song) {
    if (song.isBuiltIn) return null;

    final path = song.sourcePath;
    final file = File(path);
    final parentDir = file.parent.path.replaceAll('\\', '/');
    final fileName = file.path.split(RegExp(r'[/\\]')).last;
    final lastDot = fileName.lastIndexOf('.');
    final fileNameWithoutExt = lastDot != -1
        ? fileName.substring(0, lastDot)
        : fileName;

    final candidates = [
      // 1. Sibling with extension appended (legacy)
      '$path.png',
      '$path.jpg',
      '$path.jpeg',

      // 2. Sibling with extension replaced
      '$parentDir/$fileNameWithoutExt.png',
      '$parentDir/$fileNameWithoutExt.jpg',
      '$parentDir/$fileNameWithoutExt.jpeg',

      // 3. Album cover in same folder
      '$parentDir/cover.png',
      '$parentDir/cover.jpg',
      '$parentDir/cover.jpeg',
      '$parentDir/folder.png',
      '$parentDir/folder.jpg',
      '$parentDir/folder.jpeg',
    ];

    for (final candidate in candidates) {
      if (File(candidate).existsSync()) {
        return candidate;
      }
    }

    return null;
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
