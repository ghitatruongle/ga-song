import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/audio/audio_engine_service.dart';
import 'desktop_title_bar.dart';
import '../../providers/service_providers.dart';
import '../../core/theme_utils.dart';
import '../../models/song.dart';
import 'main_content_states.dart';
import 'song_tiles.dart';

class MainContentWidget extends ConsumerStatefulWidget {
  const MainContentWidget({
    super.key,
    required this.isLoading,
    required this.loadingError,
    required this.songs,
    required this.filteredSongs,
    required this.songIndexByFileName,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.onRefresh,
    this.showTitleBar = true,
  });

  final bool isLoading;
  final String? loadingError;
  final List<Song> songs;
  final List<Song> filteredSongs;
  final Map<String, int> songIndexByFileName;
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onRefresh;
  final bool showTitleBar;

  @override
  ConsumerState<MainContentWidget> createState() => _MainContentWidgetState();
}

class _MainContentWidgetState extends ConsumerState<MainContentWidget> {
  // #6: TextEditingController so the "X" clear button actually clears the UI.
  late final TextEditingController _searchController;
  Timer? _debounceTimer;

  // P-8 fix + Phase 2.3: Cached playback state, kept in sync via ref.listen
  // on [currentPlayingIndexProvider] and [engineStateProvider].
  int _currentPlayingIndex = -1;
  AudioEngineState _engineState = AudioEngineState.stopped;

  void _onPlaybackChanged(int newIndex, AudioEngineState newState) {
    if (newIndex == _currentPlayingIndex && newState == _engineState) return;
    setState(() {
      _currentPlayingIndex = newIndex;
      _engineState = newState;
    });
  }

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.searchQuery);
    // P-8 fix: Riverpod subscriptions replace direct addListener calls so
    // disposal is automatic on widget unmount.
  }

  @override
  void didUpdateWidget(covariant MainContentWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Keep controller in sync when parent changes searchQuery externally
    if (oldWidget.searchQuery != widget.searchQuery &&
        _searchController.text != widget.searchQuery) {
      _searchController.text = widget.searchQuery;
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // P-8 fix + Phase 2.3: Use ref.listen to subscribe to playback state
    // changes via Riverpod state providers; cleaner than direct addListener.
    ref.listen<int>(currentPlayingIndexProvider, (prev, next) {
      _onPlaybackChanged(next, ref.read(engineStateProvider));
    });
    ref.listen<AudioEngineState>(engineStateProvider, (prev, next) {
      _onPlaybackChanged(ref.read(currentPlayingIndexProvider), next);
    });
    return ColoredBox(
      color: Colors.transparent,
      child: Column(
        children: <Widget>[
          // Q-3 fix: Use shared DesktopTitleBar widget
          if (widget.showTitleBar) const DesktopTitleBar(),
          _buildHeader(context),
          Expanded(
            child: widget.isLoading
                ? Center(
                    child: CircularProgressIndicator(color: context.adaptive),
                  )
                : widget.loadingError != null
                ? ErrorLoadingState(
                    errorMessage: widget.loadingError!,
                    onRetry: widget.onRefresh,
                  )
                : widget.songs.isEmpty
                ? const EmptyLibraryState()
                : _buildSongList(context),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(40, 10, 40, 30),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final showSearchBox = constraints.maxWidth > 600;
          return Row(
            children: <Widget>[
              Flexible(
                child: Text(
                  'Trang chủ',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: context.adaptive,
                    letterSpacing: -0.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (showSearchBox) ...[
                const SizedBox(width: 16),
                Flexible(
                  child: SizedBox(
                    width: 320,
                    height: 44,
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) {
                        _debounceTimer?.cancel();
                        _debounceTimer = Timer(const Duration(milliseconds: 300), () {
                          widget.onSearchChanged(value);
                        });
                      },
                      style: TextStyle(color: context.adaptive, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Tìm kiếm bài hát...',
                        hintStyle: TextStyle(
                          color: context.adaptive.withValues(alpha: 0.5),
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          color: context.adaptive.withValues(alpha: 0.5),
                          size: 20,
                        ),
                        suffixIcon: widget.searchQuery.isNotEmpty
                            ? IconButton(
                                icon: Icon(
                                  Icons.clear,
                                  color: context.adaptiveSubtle,
                                  size: 18,
                                ),
                                onPressed: () {
                                  _debounceTimer?.cancel();
                                  _searchController.clear();
                                  widget.onSearchChanged('');
                                },
                                splashRadius: 20,
                              )
                            : null,
                        filled: true,
                        fillColor: context.adaptive.withValues(alpha: 0.1),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(22),
                          borderSide: BorderSide(
                            color: context.adaptive.withValues(alpha: 0.15),
                            width: 1,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(22),
                          borderSide: BorderSide(
                            color: context.adaptive.withValues(alpha: 0.15),
                            width: 1,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(22),
                          borderSide: BorderSide(
                            color: context.adaptive.withValues(alpha: 0.4),
                            width: 2,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 0,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(width: 16),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: context.adaptive.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: ValueListenableBuilder<bool>(
                  valueListenable: ref.read(settingsManagerProvider).isGridViewNotifier,
                  builder: (context, isGrid, _) {
                    return IconButton(
                      icon: Icon(
                        isGrid ? Icons.list_rounded : Icons.grid_view_rounded,
                        color: context.adaptive,
                        size: 20,
                      ),
                      onPressed: () => ref.read(settingsManagerProvider).setIsGridView(!isGrid),
                      tooltip: isGrid ? 'Chế độ danh sách' : 'Chế độ lưới',
                      splashRadius: 24,
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: context.adaptive.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.refresh_rounded,
                    color: context.adaptive,
                    size: 20,
                  ),
                  onPressed: widget.onRefresh,
                  tooltip: 'Làm mới danh sách',
                  splashRadius: 24,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSongList(BuildContext context) {
    // P-8 fix: Wrap with SongPlaybackInheritedWidget so tiles can read
    // playback state via context instead of registering individual listeners.
    return SongPlaybackInheritedWidget(
      currentIndex: _currentPlayingIndex,
      isPlaying: _engineState == AudioEngineState.playing,
      child: ValueListenableBuilder<bool>(
        valueListenable: ref.read(settingsManagerProvider).isGridViewNotifier,
        builder: (context, isGrid, _) {
          final itemCount = widget.filteredSongs.length;
          if (isGrid) {
            return RepaintBoundary(
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(40, 0, 40, 140),
                scrollCacheExtent: const ScrollCacheExtent.pixels(500),
                addAutomaticKeepAlives: false,
                addRepaintBoundaries: false, // items have manual RepaintBoundary
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 200,
                  childAspectRatio: 0.8,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: itemCount,
                itemBuilder: (context, index) {
                  final song = widget.filteredSongs[index];
                  final songIndex =
                      widget.songIndexByFileName[song.fileName] ?? index;
                  return SongGridTile(song: song, songIndex: songIndex);
                },
              ),
            );
          }

          return RepaintBoundary(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(40, 0, 40, 140),
              itemExtent: 86.0,
              scrollCacheExtent: const ScrollCacheExtent.pixels(500),
              addAutomaticKeepAlives: false,
              addRepaintBoundaries: false, // items have manual RepaintBoundary
              itemCount: itemCount,
              itemBuilder: (context, index) {
                final song = widget.filteredSongs[index];
                final songIndex =
                    widget.songIndexByFileName[song.fileName] ?? index;
                return SongListTile(song: song, songIndex: songIndex);
              },
            ),
          );
        },
      ),
    );
  }
}

