import 'logging/app_logger.dart';
import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'dart:isolate';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import '../models/song.dart';
import '../models/cover_art_cache.dart';
import 'settings_manager.dart';
import 'platform_capabilities.dart';
import 'services/db_service_wrapper.dart';
import 'performance_probe.dart';

/// P3.3: cache entries older than this are evicted even if LRU hasn't
/// pushed them out. Conservative default per plan.
const Duration _coverArtTtl = Duration(hours: 1);

/// 3-Tier Cache Levels
enum CoverArtCacheTier {
  /// In-memory cache (fastest, ~1-5ms)
  memory,

  /// Disk cache (SQLite, ~10-50ms)
  disk,

  /// Network cache (fetched from online sources, ~100-500ms)
  network,
}

class CoverArtEntry {
  CoverArtEntry({
    required this.fileName,
    required this.imagePath,
    required this.exists,
    required this.isAsset,
    required this.tier,
    final DateTime? capturedAt,
  }) : capturedAt = capturedAt ?? DateTime.now();

  final String fileName;
  final String imagePath;
  final bool exists;
  final bool isAsset; // true = AssetImage, false = FileImage
  final CoverArtCacheTier tier;

  /// When this entry was created. Used for TTL eviction. Defaults to
  /// `DateTime.now()` at construction time.
  final DateTime capturedAt;

  /// True when [capturedAt] is within [ttl] from `DateTime.now()`.
  bool isFresh({required final Duration ttl}) =>
      DateTime.now().difference(capturedAt) < ttl;

  bool get hasCover => exists;
}

// Cache sizes are determined at runtime by PlatformCapabilities (Android vs Desktop).
// Desktop: 60 providers / 30 colors; Android: 24 providers / 15 colors.
int get _maxProviderCacheSize =>
    PlatformCapabilities.instance.maxCoverArtCacheEntries;
int get _maxDominantColorCacheSize =>
    PlatformCapabilities.instance.isAndroid ? 15 : 30;

/// 3-Tier Cache configuration
/// Memory: Hot cache - most recently accessed
/// Disk: Persistent cache - survives app restarts
/// Network: Online fetch - fallback when local not available

/// Centralizes cover art existence checks, resized providers, palette cache,
/// and SQLite-backed disk cache for persistence across sessions.
///
/// Dependencies are injected via constructor for testability.
class CoverArtRepository with WidgetsBindingObserver {
  CoverArtRepository({
    final DatabaseServiceWrapper? databaseService,
    final SettingsManager? settingsManager,
  }) : _databaseService = databaseService,
       _settingsManager = settingsManager {
    WidgetsBinding.instance.addObserver(this);
  }

  final DatabaseServiceWrapper? _databaseService;
  final SettingsManager? _settingsManager;

  // ─── 3-Tier Cache Storage ────────────────────────────────────────────────

  /// Tier 1: In-memory cache (fastest access)
  final Map<String, CoverArtEntry> _memoryCache = <String, CoverArtEntry>{};

  /// Tier 2: Disk cache index (tracks what's in SQLite)
  final Set<String> _diskCacheIndex = <String>{};

  /// Tier 3: Network cache index (tracks what's been fetched online)
  final Set<String> _networkCacheIndex = <String>{};

  /// Entry futures for deduplication
  final Map<String, Future<CoverArtEntry>> _entryFutures =
      <String, Future<CoverArtEntry>>{};

  /// Legacy in-memory entries (for backward compatibility)
  final Map<String, CoverArtEntry> _entries = <String, CoverArtEntry>{};

  final LinkedHashMap<_CoverArtVariantKey, ImageProvider<Object>>
  _providerCache = LinkedHashMap<_CoverArtVariantKey, ImageProvider<Object>>();
  final LinkedHashMap<String, Future<Color?>> _dominantColorFutures =
      LinkedHashMap<String, Future<Color?>>();

  // ─── Concurrent decode limiter ──────────────────────────────────────────
  // Limits concurrent native image decodes to avoid memory spikes.
  int _activeDecodes = 0;
  final List<void Function()> _decodeQueue = [];

  /// Runs [action] under the platform's concurrent-decode cap.
  Future<T> _withDecodeSlot<T>(final Future<T> Function() action) async {
    final maxConcurrent =
        PlatformCapabilities.instance.maxConcurrentImageDecodes;
    if (_activeDecodes >= maxConcurrent) {
      final completer = Completer<void>();
      _decodeQueue.add(completer.complete);
      await completer.future;
    }
    _activeDecodes++;
    try {
      return await action();
    } finally {
      _activeDecodes--;
      if (_decodeQueue.isNotEmpty) {
        final next = _decodeQueue.removeAt(0);
        next();
      }
    }
  }

  @override
  void didHaveMemoryPressure() {
    super.didHaveMemoryPressure();
    AppLogger.i(
      'cover_art.repository',
      'Memory pressure detected; clearing caches',
    );
    _providerCache.clear();
    _memoryCache.clear();
    _entries.clear();
    _entryFutures.clear();
    _dominantColorFutures.clear();
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();

    // Android: aggressive cleanup on memory pressure
    if (PlatformCapabilities.instance.aggressiveMemoryCleanup) {
      _aggressiveMemoryCleanup();
    }
  }

  /// Aggressive memory cleanup for low-end Android devices.
  void _aggressiveMemoryCleanup() {
    // Clear 50% of provider cache
    final providersToRemove = (_providerCache.length * 0.5).ceil();
    final keys = _providerCache.keys.toList();
    for (int i = 0; i < providersToRemove && i < keys.length; i++) {
      _providerCache.remove(keys[i]);
    }

    // Clear 50% of memory cache
    final memoryToRemove = (_memoryCache.length * 0.5).ceil();
    final memoryKeys = _memoryCache.keys.toList();
    for (int i = 0; i < memoryToRemove && i < memoryKeys.length; i++) {
      _memoryCache.remove(memoryKeys[i]);
    }

    AppLogger.d(
      'cover_art.repository',
      'Aggressive memory cleanup: cleared $providersToRemove providers, '
          '$memoryToRemove memory entries',
    );
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _entryFutures.clear();
    _entries.clear();
    _memoryCache.clear();
    _diskCacheIndex.clear();
    _networkCacheIndex.clear();
    _providerCache.clear();
    _dominantColorFutures.clear();
  }

  /// Reports current provider cache size to [PerformanceProbe].
  void _reportCacheSize() {
    PerformanceProbe.instance.recordCacheSize(_providerCache.length);
  }

  Future<void> primeForSongs(final Iterable<Song> songs) async {
    // Resolve library covers concurrently respecting the platform decode cap.
    final concurrency = PlatformCapabilities.instance.maxConcurrentImageDecodes;
    final iterator = songs.iterator;
    Future<void> worker() async {
      while (true) {
        final bool hasNext;
        try {
          hasNext = iterator.moveNext();
        } catch (_) {
          return;
        }
        if (!hasNext) return;
        try {
          await resolveEntry(iterator.current);
        } catch (e, stack) {
          AppLogger.w(
            'cover_art.repository',
            'prime entry failed',
            error: e,
            stack: stack,
          );
        }
      }
    }

    await Future.wait(List.generate(concurrency, (_) => worker()));
  }

  Future<void> preloadNextSongs(
    final List<Song> songs,
    final int currentIndex,
    final int count,
  ) async {
    if (songs.isEmpty) return;
    // Skip proactive preloads when in battery saver or background work is deferred.
    if (PlatformCapabilities.instance.deferBackgroundWork) return;
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
        toPreload.map((final idx) async {
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

  /// Gets entry from 3-tier cache (memory → disk → network)
  CoverArtEntry? getCachedEntry(final String fileName) {
    // Tier 1: Memory cache (fastest)
    final memoryEntry = _memoryCache[fileName];
    if (memoryEntry != null && memoryEntry.isFresh(ttl: _coverArtTtl)) {
      return memoryEntry;
    }

    // Tier 2: Legacy entries cache
    final legacyEntry = _entries[fileName];
    if (legacyEntry != null && legacyEntry.isFresh(ttl: _coverArtTtl)) {
      // Promote to memory cache
      _memoryCache[fileName] = legacyEntry;
      return legacyEntry;
    }

    // Clean up stale entries
    if (memoryEntry != null) _evictMemoryEntry(fileName);
    if (legacyEntry != null) _evictStaleEntry(fileName);

    return null;
  }

  /// Removes a stale entry from memory cache.
  void _evictMemoryEntry(final String fileName) {
    _memoryCache.remove(fileName);
    _entryFutures.remove(fileName);
    _providerCache.removeWhere((final key, _) => key.fileName == fileName);
    _dominantColorFutures.remove(fileName);
  }

  /// Removes a stale entry from all in-memory caches for [fileName].
  void _evictStaleEntry(final String fileName) {
    _entries.remove(fileName);
    _entryFutures.remove(fileName);
    _providerCache.removeWhere((final key, _) => key.fileName == fileName);
    _dominantColorFutures.remove(fileName);
    _memoryCache.remove(fileName);
  }

  /// Drops the oldest provider entries when the Flutter image cache holds
  /// more bytes than the platform budget.
  void _evictProvidersOverByteBudget() {
    final caps = PlatformCapabilities.instance;
    final int budgetBytes;
    if (caps.reduceLagOverride) {
      budgetBytes = 8 * 1024 * 1024;
    } else if (caps.isAndroid && caps.effectiveTier == DeviceTier.low) {
      budgetBytes = 16 * 1024 * 1024;
    } else if (caps.isAndroid) {
      budgetBytes = 32 * 1024 * 1024;
    } else {
      budgetBytes = 120 * 1024 * 1024;
    }
    final used = PaintingBinding.instance.imageCache.currentSizeBytes;
    if (used < budgetBytes || _providerCache.isEmpty) return;
    final toEvict = (_providerCache.length / 2).ceil();
    for (var i = 0; i < toEvict && _providerCache.isNotEmpty; i++) {
      _providerCache.remove(_providerCache.keys.first);
      PerformanceProbe.instance.recordEviction();
    }
  }

  ImageProvider<Object>? getCachedProvider(
    final String fileName, {
    final int? cacheWidth,
    final int? cacheHeight,
  }) {
    final entry = getCachedEntry(fileName);
    if (entry == null || !entry.hasCover) {
      return null;
    }
    _evictProvidersOverByteBudget();

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

  Future<CoverArtEntry> resolveEntry(final Song song) {
    final existing = _entryFutures[song.fileName];
    if (existing != null) return existing;

    late final Future<CoverArtEntry> future;
    future = _resolveEntry(
      song,
      () => identical(_entryFutures[song.fileName], future),
    );
    _entryFutures[song.fileName] = future;
    return future;
  }

  /// Async body of [resolveEntry]. [isCurrent] is true while this future is
  /// still the registered resolver for the song — protects against:
  /// 1. Stale async results clobbering a newer entry after invalidate/TTL.
  /// 2. A failed future being cached forever (poisoned future).
  Future<CoverArtEntry> _resolveEntry(
    final Song song,
    final bool Function() isCurrent,
  ) async {
    try {
      String imagePath;
      bool exists = false;
      bool isAsset = false;
      CoverArtCacheTier tier = CoverArtCacheTier.memory;

      if (song.isBuiltIn) {
        isAsset = true;
        final resolved = await findCoverAssetPath(song);
        if (resolved != null) {
          imagePath = resolved;
          exists = true;
          tier =
              CoverArtCacheTier.memory; // Built-in assets are always in memory
        } else {
          imagePath = _builtInCoverPath(song);
          exists = false;
        }
      } else {
        isAsset = false;
        final resolved = await findLocalCoverPath(song);
        if (resolved != null) {
          imagePath = resolved;
          exists = true;
          tier = CoverArtCacheTier.disk; // Local files from disk
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
        tier: tier,
      );

      // Only publish if this future is still the current resolver, so a
      // stale in-flight load can't clobber a newer entry.
      if (isCurrent()) {
        // Add to appropriate cache tier
        _memoryCache[song.fileName] = entry;
        _entries[song.fileName] = entry; // Legacy compatibility

        // Track cache tier
        if (tier == CoverArtCacheTier.disk) {
          _diskCacheIndex.add(song.fileName);
        } else if (tier == CoverArtCacheTier.network) {
          _networkCacheIndex.add(song.fileName);
        }

        // Pre-populate the in-memory provider cache from disk or source.
        if (entry.hasCover) {
          _prepopulateProviderFromDiskOrSource(entry, song.fileName);
        }
      }

      return entry;
    } finally {
      // Remove from the futures map so a failure doesn't poison future
      // resolves — but only if we're still the registered resolver.
      if (isCurrent()) {
        _entryFutures.remove(song.fileName);
      }
    }
  }

  /// Fire-and-forget: loads cover bytes (from Isar disk cache or source file)
  /// and pre-populates the in-memory [ImageProvider] cache.
  Future<void> _prepopulateProviderFromDiskOrSource(
    final CoverArtEntry entry,
    final String fileName,
  ) async {
    await _withDecodeSlot(
      () => _prepopulateProviderFromDiskOrSourceLocked(entry, fileName),
    );
  }

  /// Body of [_prepopulateProviderFromDiskOrSource] — runs under the decode
  /// limiter so concurrent memory spikes stay within
  /// [PlatformCapabilities.maxConcurrentImageDecodes].
  Future<void> _prepopulateProviderFromDiskOrSourceLocked(
    final CoverArtEntry entry,
    final String fileName,
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
          // Update tier to disk since we found it in SQLite
          final updatedEntry = CoverArtEntry(
            fileName: entry.fileName,
            imagePath: entry.imagePath,
            exists: entry.exists,
            isAsset: entry.isAsset,
            tier: CoverArtCacheTier.disk,
            capturedAt: entry.capturedAt,
          );
          _memoryCache[fileName] = updatedEntry;
          _entries[fileName] = updatedEntry;
          _diskCacheIndex.add(fileName);
        }
      } catch (e, stack) {
        AppLogger.w(
          'cover_art.repository',
          'disk cache error',
          error: e,
          stack: stack,
        );
      }

      // 2. If disk cache missed, load from the original source.
      if (bytes == null) {
        bytes = await _loadCoverBytes(entry);

        // Save to SQLite disk cache for future sessions (fire-and-forget).
        if (bytes != null) {
          _saveToDiskCache(fileName, bytes);
          _diskCacheIndex.add(fileName);
        }
      }

      // 3. Pre-populate the in-memory provider cache.
      if (bytes != null) {
        _evictProvidersOverByteBudget();
        // Encode to WebP for efficient memory storage
        final webpBytes = await _encodeToWebP(bytes);
        final provider = MemoryImage(webpBytes ?? bytes);

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

  /// Encodes image bytes to a compact format for efficient storage.
  /// Returns null if encoding fails (falls back to original format).
  Future<Uint8List?> _encodeToWebP(final Uint8List bytes) async {
    try {
      final image = img.decodeImage(bytes);
      if (image == null) return null;

      // Store as PNG for lossless compatibility (WebP encode is not
      // available in the pinned image package version). PNG at cover-art
      // sizes is acceptable for the cache.
      final pngBytes = img.encodePng(image);
      return Uint8List.fromList(pngBytes);
    } catch (e) {
      AppLogger.w('cover_art.repository', 'WebP encoding failed', error: e);
      return null;
    }
  }

  /// Loads raw image bytes from the asset bundle or local file.
  Future<Uint8List?> _loadCoverBytes(final CoverArtEntry entry) async {
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
  Future<void> _saveToDiskCache(
    final String fileName,
    final Uint8List bytes,
  ) async {
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
      await db.evictOldestCoverArtCaches(toRemove);
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
      await db.evictHalfCoverArtCaches();
      AppLogger.i('cover_art.repository', 'force-evicted half of disk cache');
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
  void invalidateEntry(final Song song) {
    _entryFutures.remove(song.fileName);
    _entries.remove(song.fileName);
    // Also drop the memory cache — without this, getCachedEntry() keeps
    // returning the STALE cover for up to the TTL (1 hour) after a rewrite.
    _memoryCache.remove(song.fileName);
    // Also remove all provider variants for this song
    _providerCache.removeWhere((final key, _) => key.fileName == song.fileName);
    _dominantColorFutures.remove(song.fileName);
    // Also remove from disk cache
    _removeFromDiskCache(song.fileName);
  }

  /// Removes a single entry from the disk cache.
  Future<void> _removeFromDiskCache(final String fileName) async {
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
    final Song song, {
    final int paletteWidth = 192,
    final int paletteHeight = 192,
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
    // Don't cache FAILED futures forever — otherwise a transient decode
    // error poisons the color for the rest of the session (hot songs never
    // get recomputed). Remove on error so the next call retries.
    future.whenComplete(() {
      if (_dominantColorFutures[song.fileName] == future) {
        future.then<void>((_) {}).catchError((_) {
          _dominantColorFutures.remove(song.fileName);
        });
      }
    });
    return future;
  }

  Future<Color?> _resolveDominantColorAsync(
    final Song song,
    final int paletteWidth,
    final int paletteHeight,
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
  static String _builtInCoverPath(final Song song) {
    final path = song.sourcePath;
    // Replace the audio folder prefix and extension
    final picPath = path
        .replaceFirst('assets/song/', 'assets/pic/')
        .replaceAll(RegExp(r'\.(mp3|flac|wav|m4a)$'), '.png');
    return picPath;
  }

  /// Attempts to find a cover art asset path for a built-in song by checking various locations.
  /// Returns the first path that successfully loads, or null if none are found.
  static Future<String?> findCoverAssetPath(final Song song) async {
    if (!song.isBuiltIn) return null;

    final path = song.sourcePath.replaceAll(r'\', '/');
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

  /// various locations. Returns the first path that exists, or null if none
  /// are found.
  static Future<String?> findLocalCoverPath(final Song song) async {
    if (song.isBuiltIn) return null;

    final path = song.sourcePath;
    final file = File(path);
    final parentDir = file.parent.path.replaceAll(r'\', '/');
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
      if (await File(candidate).exists()) {
        return candidate;
      }
    }

    return null;
  }

  // ─── Background Indexing via Isolate ──────────────────────────────────────

  /// Starts background indexing of cover art for all songs in the library.
  /// Uses an Isolate to avoid blocking the main thread.
  ///
  /// [onProgress] callback receives (processed, total) for progress updates.
  Future<void> startBackgroundIndexing({
    final void Function(int processed, int total)? onProgress,
    final List<Song>? songs,
  }) async {
    if (_indexingInProgress) return;
    _indexingInProgress = true;

    try {
      // If songs not provided, fetch from database
      final songsToIndex = songs ?? await _databaseService?.getAllSongs() ?? [];
      final total = songsToIndex.length;

      AppLogger.i(
        'cover_art.repository',
        'Starting background indexing for $total songs',
      );

      // Spawn isolate for heavy lifting
      final receivePort = ReceivePort();
      _indexingIsolate = await Isolate.spawn(
        _backgroundIndexWorker,
        _BackgroundIndexMessage(
          songs: songsToIndex,
          sendPort: receivePort.sendPort,
        ),
      );
      _indexingPort = receivePort;

      // Listen for progress updates
      await for (final message in receivePort) {
        if (message is _IndexProgress) {
          onProgress?.call(message.processed, message.total);
        } else if (message is _IndexComplete) {
          AppLogger.i(
            'cover_art.repository',
            'Background indexing complete: ${message.results.length} covers indexed',
          );
          _indexingInProgress = false;
          receivePort.close();
          _indexingPort = null;
          _indexingIsolate = null;
          break;
        } else if (message is _IndexError) {
          AppLogger.e(
            'cover_art.repository',
            'Background indexing error',
            error: message.error,
          );
          _indexingInProgress = false;
          receivePort.close();
          _indexingPort = null;
          _indexingIsolate = null;
          break;
        }
      }
    } catch (e, stack) {
      AppLogger.e(
        'cover_art.repository',
        'Background indexing failed to start',
        error: e,
        stack: stack,
      );
      _indexingInProgress = false;
      cancelBackgroundIndexing();
    }
  }

  bool _indexingInProgress = false;

  /// Checks if background indexing is currently in progress.
  bool get isIndexingInProgress => _indexingInProgress;

  Isolate? _indexingIsolate;
  ReceivePort? _indexingPort;

  /// Cancels any ongoing background indexing.
  void cancelBackgroundIndexing() {
    _indexingInProgress = false;
    try {
      _indexingIsolate?.kill(priority: Isolate.immediate);
    } catch (e, stack) {
      AppLogger.w(
        'cover_art.repository',
        'isolate kill failed',
        error: e,
        stack: stack,
      );
    }
    _indexingIsolate = null;
    _indexingPort?.close();
    _indexingPort = null;
  }
}

/// Message sent to background isolate for indexing.
class _BackgroundIndexMessage {
  final List<Song> songs;
  final SendPort sendPort;

  _BackgroundIndexMessage({required this.songs, required this.sendPort});
}

/// Progress update from background isolate.
class _IndexProgress {
  final int processed;
  final int total;

  _IndexProgress({required this.processed, required this.total});
}

/// Completion message from background isolate.
class _IndexComplete {
  final List<_IndexResult> results;

  _IndexComplete({required this.results});
}

/// Error message from background isolate.
class _IndexError {
  final String error;

  _IndexError({required this.error});
}

/// Result of indexing a single song.
class _IndexResult {
  final String fileName;
  final bool success;
  final CoverArtCacheTier tier;

  _IndexResult({
    required this.fileName,
    required this.success,
    required this.tier,
  });
}

/// Background isolate worker function.
/// This runs in a separate isolate to avoid blocking the main thread.
Future<void> _backgroundIndexWorker(
  final _BackgroundIndexMessage message,
) async {
  final sendPort = message.sendPort;
  final songs = message.songs;
  final total = songs.length;
  final results = <_IndexResult>[];

  try {
    for (int i = 0; i < total; i++) {
      final song = songs[i];

      // Check if cover already exists in cache
      // This is a simplified check - in reality you'd check disk/memory cache
      try {
        // Simulate cover art resolution
        String? coverPath;
        CoverArtCacheTier tier = CoverArtCacheTier.memory;

        if (song.isBuiltIn) {
          coverPath = await _findCoverAssetPathInIsolate(song);
          tier = CoverArtCacheTier.memory;
        } else {
          coverPath = await _findLocalCoverPathInIsolate(song);
          tier = coverPath != null
              ? CoverArtCacheTier.disk
              : CoverArtCacheTier.network;
        }

        final success = coverPath != null;
        results.add(
          _IndexResult(
            fileName: song.fileName,
            success: success,
            tier: success ? tier : CoverArtCacheTier.network,
          ),
        );
      } catch (e) {
        results.add(
          _IndexResult(
            fileName: song.fileName,
            success: false,
            tier: CoverArtCacheTier.network,
          ),
        );
      }

      // Send progress update every 10 songs
      if (i % 10 == 0 || i == total - 1) {
        sendPort.send(_IndexProgress(processed: i + 1, total: total));
      }

      // Yield to allow other isolates to run
      await Future.delayed(Duration.zero);
    }

    sendPort.send(_IndexComplete(results: results));
  } catch (e) {
    sendPort.send(_IndexError(error: e.toString()));
  }
}

/// Finds cover asset path in isolate (simplified - no rootBundle access).
/// In a real implementation, you'd pass asset paths or use a different approach.
Future<String?> _findCoverAssetPathInIsolate(final Song song) async {
  // This is a placeholder - in isolate you can't access rootBundle directly
  // You'd need to pre-compute paths or pass them in the message
  return null;
}

/// Finds local cover path in isolate.
Future<String?> _findLocalCoverPathInIsolate(final Song song) async {
  if (song.isBuiltIn) return null;

  final path = song.sourcePath;
  final file = File(path);
  final parentDir = file.parent.path.replaceAll(r'\', '/');
  final fileName = file.path.split(RegExp(r'[/\\]')).last;
  final lastDot = fileName.lastIndexOf('.');
  final fileNameWithoutExt = lastDot != -1
      ? fileName.substring(0, lastDot)
      : fileName;

  final candidates = [
    '$path.png',
    '$path.jpg',
    '$path.jpeg',
    '$parentDir/$fileNameWithoutExt.png',
    '$parentDir/$fileNameWithoutExt.jpg',
    '$parentDir/$fileNameWithoutExt.jpeg',
    '$parentDir/cover.png',
    '$parentDir/cover.jpg',
    '$parentDir/cover.jpeg',
    '$parentDir/folder.png',
    '$parentDir/folder.jpg',
    '$parentDir/folder.jpeg',
  ];

  for (final candidate in candidates) {
    if (await File(candidate).exists()) {
      return candidate;
    }
  }

  return null;
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
  bool operator ==(final Object other) =>
      other is _CoverArtVariantKey &&
      other.fileName == fileName &&
      other.cacheWidth == cacheWidth &&
      other.cacheHeight == cacheHeight;

  @override
  int get hashCode => Object.hash(fileName, cacheWidth, cacheHeight);
}
