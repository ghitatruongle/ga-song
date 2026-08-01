/// Mock implementation of [CoverArtRepository] for testing.
/// Provides controlled cover art behavior without file system/network dependencies.

import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
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

  @override
  Future<String?> findCoverAssetPath(Song song) async {
    findCoverAssetPathCallCount++;
    return _assetPaths[song.fileName];
  }

  @override
  Future<String?> findLocalCoverPath(Song song) async {
    findLocalCoverPathCallCount++;
    return _localPaths[song.fileName];
  }

  @override
  Future<Uint8List?> loadAssetCover(String assetPath) async {
    loadAssetCoverCallCount++;
    return _assetCache[assetPath];
  }

  @override
  Future<Uint8List?> loadLocalCover(String filePath) async {
    loadLocalCoverCallCount++;
    return _localCache[filePath];
  }

  @override
  Future<Uint8List?> fetchNetworkCover(String artist, String album) async {
    fetchNetworkCoverCallCount++;
    final key = '$artist-$album';
    return _networkCache[key];
  }

  @override
  Future<Uint8List?> getCoverBytes(Song song) async {
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

  @override
  Future<Uint8List?> extractEmbeddedCover(String filePath) async {
    extractEmbeddedCoverCallCount++;
    return _localCache[filePath];
  }

  @override
  Future<void> cacheNetworkCover(String artist, String album, Uint8List bytes) async {
    cacheNetworkCoverCallCount++;
    final key = '$artist-$album';
    _networkCache[key] = bytes;
  }

  @override
  Future<void> clearCache() async {
    _assetCache.clear();
    _localCache.clear();
    _networkCache.clear();
  }

  // Helper methods for test setup
  void setAssetCover(String fileName, String assetPath, Uint8List bytes) {
    _assetPaths[fileName] = assetPath;
    _assetCache[assetPath] = bytes;
  }

  void setLocalCover(String fileName, String localPath, Uint8List bytes) {
    _localPaths[fileName] = localPath;
    _localCache[localPath] = bytes;
  }

  void setNetworkCover(String artist, String album, Uint8List bytes) {
    final key = '$artist-$album';
    _networkCache[key] = bytes;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}