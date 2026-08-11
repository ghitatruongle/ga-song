/// Lyrics Editor Widget for G.A - Song
///
/// Provides inline editing of lyrics with real-time preview,
/// auto-fetch from LRCLIB API, and synchronization with playback.
library;

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/audio/lyric_parser.dart';
import '../../core/services/online_lyrics_service.dart';
import '../../providers/service_providers.dart';
import 'lyric_provider.dart';

/// Provider for the lyrics editor state
class LyricsEditorState {
  final String plainLyrics;
  final String syncedLyrics;
  final bool isEditing;
  final bool isLoading;
  final String? errorMessage;
  final List<LyricsSearchResult> searchResults;
  final int? selectedResultIndex;

  const LyricsEditorState({
    this.plainLyrics = '',
    this.syncedLyrics = '',
    this.isEditing = false,
    this.isLoading = false,
    this.errorMessage,
    this.searchResults = const [],
    this.selectedResultIndex,
  });

  LyricsEditorState copyWith({
    String? plainLyrics,
    String? syncedLyrics,
    bool? isEditing,
    bool? isLoading,
    String? errorMessage,
    List<LyricsSearchResult>? searchResults,
    int? selectedResultIndex,
  }) {
    return LyricsEditorState(
      plainLyrics: plainLyrics ?? this.plainLyrics,
      syncedLyrics: syncedLyrics ?? this.syncedLyrics,
      isEditing: isEditing ?? this.isEditing,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      searchResults: searchResults ?? this.searchResults,
      selectedResultIndex: selectedResultIndex ?? this.selectedResultIndex,
    );
  }
}

/// Notifier for lyrics editor state
class LyricsEditorNotifier extends Notifier<LyricsEditorState> {
  @override
  LyricsEditorState build() {
    return const LyricsEditorState();
  }

  void startEditing() {
    state = state.copyWith(isEditing: true);
  }

  void stopEditing() {
    state = state.copyWith(isEditing: false);
  }

  void updatePlainLyrics(String lyrics) {
    state = state.copyWith(plainLyrics: lyrics);
  }

  void updateSyncedLyrics(String lyrics) {
    state = state.copyWith(syncedLyrics: lyrics);
  }

  void setError(String? error) {
    state = state.copyWith(errorMessage: error);
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  void setLoading(bool loading) {
    state = state.copyWith(isLoading: loading);
  }

  /// Search for lyrics on LRCLIB
  Future<void> searchLyrics({
    required String title,
    String? artist,
    String? album,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final service = ref.read(onlineLyricsServiceProvider);
      final results = await service.search(
        title: title,
        artist: artist,
        album: album,
      );

      state = state.copyWith(
        isLoading: false,
        searchResults: results,
        selectedResultIndex: results.isNotEmpty ? 0 : null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Tìm kiếm thất bại: $e',
      );
    }
  }

  /// Select a search result and load its lyrics
  void selectResult(int index) {
    if (index < 0 || index >= state.searchResults.length) return;

    final result = state.searchResults[index];

    state = state.copyWith(
      selectedResultIndex: index,
      plainLyrics: result.plainLyrics ?? '',
      syncedLyrics: result.syncedLyrics ?? '',
    );
  }

  /// Apply the selected result's lyrics
  void applySelectedResult() {
    if (state.selectedResultIndex == null) return;

    final result = state.searchResults[state.selectedResultIndex!];

    state = state.copyWith(
      plainLyrics: result.plainLyrics ?? '',
      syncedLyrics: result.syncedLyrics ?? '',
      searchResults: [],
      selectedResultIndex: null,
    );
  }

  /// Clear search results
  void clearSearch() {
    state = state.copyWith(searchResults: [], selectedResultIndex: null);
  }

  /// Save lyrics to database and update provider
  Future<void> saveLyrics({
    required int songId,
    required String title,
    String? artist,
  }) async {
    final db = ref.read(databaseServiceProvider);
    final synced = state.syncedLyrics.isNotEmpty ? state.syncedLyrics : null;
    final plain = state.plainLyrics.isNotEmpty ? state.plainLyrics : null;

    await db.cacheLyrics(
      songId: songId,
      plainLyrics: plain,
      syncedLyrics: synced,
      source: 'editor',
    );

    // Update the lyric provider
    final parsed = LyricParser.parse(
      state.syncedLyrics.isNotEmpty
          ? state.syncedLyrics
          : (state.plainLyrics.isNotEmpty ? state.plainLyrics : ''),
    );
    ref.read(lyricProvider.notifier).state = parsed;
  }

  /// Generate synced lyrics from plain text using timing estimation
  void generateSyncedFromPlain() {
    if (state.plainLyrics.isEmpty) return;

    final lines = state.plainLyrics
        .split('\n')
        .where((l) => l.trim().isNotEmpty)
        .toList();

    if (lines.isEmpty) return;

    // Estimate timing: assume ~3 seconds per line
    final syncedLines = <String>[];
    Duration currentTime = Duration.zero;
    const estimatedLineDuration = Duration(seconds: 3);

    for (int i = 0; i < lines.length; i++) {
      final mm = currentTime.inMinutes.toString().padLeft(2, '0');
      final ss = (currentTime.inSeconds % 60).toString().padLeft(2, '0');
      final ms = ((currentTime.inMilliseconds % 1000) ~/ 10).toString().padLeft(
        2,
        '0',
      );

      syncedLines.add('[$mm:$ss.$ms]${lines[i]}');
      currentTime += estimatedLineDuration;
    }

    state = state.copyWith(syncedLyrics: syncedLines.join('\n'));
  }

  /// Parse synced lyrics and validate format
  bool validateSyncedFormat() {
    if (state.syncedLyrics.isEmpty) return false;
    try {
      LyricParser.parse(state.syncedLyrics);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Reset editor state for a new song
  void resetForSong({String? initialPlain, String? initialSynced}) {
    state = LyricsEditorState(
      plainLyrics: initialPlain ?? '',
      syncedLyrics: initialSynced ?? '',
    );
  }
}

final lyricsEditorProvider =
    NotifierProvider<LyricsEditorNotifier, LyricsEditorState>(
      LyricsEditorNotifier.new,
    );
