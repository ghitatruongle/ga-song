/// Mock implementation of [CoverArtRepository] for testing.
/// Provides controlled cover art behavior without file system/network dependencies.
library;

import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ga_song/core/cover_art_repository.dart';
import 'package:ga_song/models/song.dart';

class MockCoverArtRepository implements CoverArtRepository {
  final Map<String, Uint8List> _assetCache = {};
  final Map<String, Uint8List> _localCache = {};
  final Map<String, Uint8List> _networkCache = {};
  final Map<String, String> _localPaths = {};
  final Map<String, String> _assetPaths = {};

  // Track calls for verification
  int findCoverAssetPathCallCount = 0;
  int findLocalCoverPathCallCount = 0;
  int loadAssetCoverCallCount = 0;
  int loadLocalCoverCallCount = 0;
  int fetchNetworkCoverCallCount = 0;
  int getCoverBytesCallCount = 0;
  int extractEmbeddedCoverCallCount = 0;
  int cacheNetworkCoverCallCount = 0;

  Future<String?> findCoverAssetPath(final Song song) async {
    findCoverAssetPathCallCount++;
    return _assetPaths[song.fileName];
  }

  Future<String?> findLocalCoverPath(final Song song) async {
    findLocalCoverPathCallCount++;
    return _localPaths[song.fileName];
  }

  Future<Uint8List?> loadAssetCover(final String assetPath) async {
    loadAssetCoverCallCount++;
    return _assetCache[assetPath];
  }

  Future<Uint8List?> loadLocalCover(final String filePath) async {
    loadLocalCoverCallCount++;
    return _localCache[filePath];
  }

  Future<Uint8List?> fetchNetworkCover(
    final String artist,
    final String album,
  ) async {
    fetchNetworkCoverCallCount++;
    final key = '$artist-$album';
    return _networkCache[key];
  }

  Future<Uint8List?> getCoverBytes(final Song song) async {
    getCoverBytesCallCount++;

    // Priority: local > asset > network
    if (_localPaths.containsKey(song.fileName)) {
      return _localCache[_localPaths[song.fileName]!];
    }
    if (_assetPaths.containsKey(song.fileName)) {
      return _assetCache[_assetPaths[song.fileName]!];
    }
    if (song.artist != null && song.album != null) {
      final key = '${song.artist}-${song.album}';
      return _networkCache[key];
    }
    return null;
  }

  Future<Uint8List?> extractEmbeddedCover(final String filePath) async {
    extractEmbeddedCoverCallCount++;
    return _localCache[filePath];
  }

  Future<void> cacheNetworkCover(
    final String artist,
    final String album,
    final Uint8List bytes,
  ) async {
    cacheNetworkCoverCallCount++;
    final key = '$artist-$album';
    _networkCache[key] = bytes;
  }

  Future<void> clearCache() async {
    _assetCache.clear();
    _localCache.clear();
    _networkCache.clear();
  }

  // Helper methods for test setup
  void setAssetCover(
    final String fileName,
    final String assetPath,
    final Uint8List bytes,
  ) {
    _assetPaths[fileName] = assetPath;
    _assetCache[assetPath] = bytes;
  }

  void setLocalCover(
    final String fileName,
    final String localPath,
    final Uint8List bytes,
  ) {
    _localPaths[fileName] = localPath;
    _localCache[localPath] = bytes;
  }

  void setNetworkCover(
    final String artist,
    final String album,
    final Uint8List bytes,
  ) {
    final key = '$artist-$album';
    _networkCache[key] = bytes;
  }

  @override
  Future<void> primeForSongs(final Iterable<Song> songs) async {}

  @override
  Future<void> preloadNextSongs(
    final List<Song> songs,
    final int currentIndex,
    final int count,
  ) async {}

  Future<CoverArtEntry?> resolveCoverArt(final Song song) async => null;

  ImageProvider<Object>? getCoverProvider(final Song song) => null;

  @override
  Future<Color?> resolveDominantColor(
    final Song song, {
    final int paletteWidth = 192,
    final int paletteHeight = 192,
  }) async => null;

  @override
  CoverArtEntry? getCachedEntry(final String fileName) => null;

  @override
  ImageProvider<Object>? getCachedProvider(
    final String fileName, {
    final int? cacheWidth,
    final int? cacheHeight,
  }) => null;

  @override
  Future<CoverArtEntry> resolveEntry(final Song song) async => CoverArtEntry(
    fileName: song.fileName,
    imagePath: '',
    exists: false,
    isAsset: false,
    tier: CoverArtCacheTier.memory,
  );

  @override
  void invalidateEntry(final Song song) {}

  @override
  dynamic noSuchMethod(final Invocation invocation) =>
      super.noSuchMethod(invocation);
}
