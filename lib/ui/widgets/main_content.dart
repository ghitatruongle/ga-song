import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  late final TextEditingController _searchController;
  Timer? _debounceTimer;

  final ScrollController _scrollController = ScrollController();

  int _currentPlayingIndex = -1;
  AudioEngineState _engineState = AudioEngineState.stopped;

  void _onPlaybackChanged(final int newIndex, final AudioEngineState newState) {
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
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant final MainContentWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.searchQuery != widget.searchQuery &&
        _searchController.text != widget.searchQuery) {
      _searchController.text = widget.searchQuery;
    }
  }

  @override
  Widget build(final BuildContext context) {
    ref.listen<int>(currentPlayingIndexProvider, (final prev, final next) {
      _onPlaybackChanged(next, ref.read(engineStateProvider));
    });
    ref.listen<AudioEngineState>(engineStateProvider, (final prev, final next) {
      _onPlaybackChanged(ref.read(currentPlayingIndexProvider), next);
    });
    return ColoredBox(
      color: Colors.transparent,
      child: Column(
        children: <Widget>[
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

  Widget _buildHeader(final BuildContext context) => LayoutBuilder(
    builder: (final context, final constraints) {
      final isMobile = constraints.maxWidth <= 600;
      final paddingHorizontal = isMobile ? 16.0 : 40.0;

      return Padding(
        padding: EdgeInsets.fromLTRB(
          paddingHorizontal,
          10,
          paddingHorizontal,
          16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: <Widget>[
                Text(
                  'Thư viện',
                  style: TextStyle(
                    fontSize: isMobile ? 24 : 32,
                    fontWeight: FontWeight.w800,
                    color: context.adaptive,
                    letterSpacing: -0.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(width: 8),
                // Nút Import Nhạc +
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Color(0xFF1DB954),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.add, color: Colors.black, size: 20),
                  ),
                  tooltip: 'Thêm nhạc vào thư viện (Import)',
                  onPressed: () async {
                    HapticFeedback.lightImpact();
                    final manager = ref.read(musicManagerProvider);
                    final messenger = ScaffoldMessenger.of(context);
                    try {
                      await manager.importLocalSongs();
                      widget.onRefresh();
                      if (context.mounted) {
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Đã thêm bài hát vào thư viện thành công',
                            ),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        messenger.showSnackBar(
                          SnackBar(content: Text('Lỗi thêm nhạc: $e')),
                        );
                      }
                    }
                  },
                ),
                const Spacer(),
                // Search box shrinks on narrower windows instead of
                // overflowing (fixed 260px broke windows < ~800px).
                if (!isMobile) ...[
                  Flexible(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 260),
                      child: SizedBox(
                        height: 38,
                        child: TextField(
                          controller: _searchController,
                          onChanged: (final value) {
                            _debounceTimer?.cancel();
                            _debounceTimer = Timer(
                              const Duration(milliseconds: 300),
                              () {
                                widget.onSearchChanged(value);
                              },
                            );
                          },
                          style: TextStyle(
                            color: context.adaptive,
                            fontSize: 13,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Tìm kiếm bài hát...',
                            hintStyle: TextStyle(
                              color: context.adaptive.withValues(alpha: 0.5),
                              fontSize: 13,
                            ),
                            prefixIcon: Icon(
                              Icons.search,
                              color: context.adaptive.withValues(alpha: 0.5),
                              size: 18,
                            ),
                            suffixIcon: widget.searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: Icon(
                                      Icons.clear,
                                      color: context.adaptiveSubtle,
                                      size: 16,
                                    ),
                                    onPressed: () {
                                      _debounceTimer?.cancel();
                                      _searchController.clear();
                                      widget.onSearchChanged('');
                                    },
                                    splashRadius: 18,
                                  )
                                : null,
                            filled: true,
                            fillColor: context.adaptive.withValues(alpha: 0.1),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: context.adaptive.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: ValueListenableBuilder<bool>(
                    valueListenable: ref
                        .read(settingsManagerProvider)
                        .isGridViewNotifier,
                    builder: (final context, final isGrid, _) => IconButton(
                      icon: Icon(
                        isGrid ? Icons.list_rounded : Icons.grid_view_rounded,
                        color: context.adaptive,
                        size: 20,
                      ),
                      onPressed: () => ref
                          .read(settingsManagerProvider)
                          .setIsGridView(!isGrid),
                      tooltip: isGrid ? 'Chế độ danh sách' : 'Chế độ lưới',
                      splashRadius: 24,
                    ),
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
            ),
            if (isMobile) ...[
              const SizedBox(height: 10),
              SizedBox(
                height: 38,
                child: TextField(
                  controller: _searchController,
                  onChanged: (final value) {
                    _debounceTimer?.cancel();
                    _debounceTimer = Timer(
                      const Duration(milliseconds: 300),
                      () {
                        widget.onSearchChanged(value);
                      },
                    );
                  },
                  style: TextStyle(color: context.adaptive, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm bài hát...',
                    hintStyle: TextStyle(
                      color: context.adaptive.withValues(alpha: 0.5),
                      fontSize: 13,
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      color: context.adaptive.withValues(alpha: 0.5),
                      size: 18,
                    ),
                    suffixIcon: widget.searchQuery.isNotEmpty
                        ? IconButton(
                            icon: Icon(
                              Icons.clear,
                              color: context.adaptiveSubtle,
                              size: 16,
                            ),
                            onPressed: () {
                              _debounceTimer?.cancel();
                              _searchController.clear();
                              widget.onSearchChanged('');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: context.adaptive.withValues(alpha: 0.1),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    },
  );

  Widget _buildSongList(final BuildContext context) =>
      SongPlaybackInheritedWidget(
        currentIndex: _currentPlayingIndex,
        isPlaying: _engineState == AudioEngineState.playing,
        child: ValueListenableBuilder<bool>(
          valueListenable: ref.read(settingsManagerProvider).isGridViewNotifier,
          builder: (final context, final isGrid, _) {
            final itemCount = widget.filteredSongs.length;
            if (isGrid) {
              return RepaintBoundary(
                child: GridView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 220,
                    childAspectRatio: 0.82,
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                  ),
                  itemCount: itemCount,
                  itemBuilder: (final context, final index) {
                    final song = widget.filteredSongs[index];
                    final globalIndex =
                        widget.songIndexByFileName[song.fileName] ?? index;
                    return SongGridTile(song: song, songIndex: globalIndex);
                  },
                ),
              );
            }

            return RepaintBoundary(
              child: ListView.builder(
                controller: _scrollController,
                itemCount: itemCount,
                itemExtent: 64,
                padding: const EdgeInsets.only(bottom: 20),
                itemBuilder: (final context, final index) {
                  final song = widget.filteredSongs[index];
                  final globalIndex =
                      widget.songIndexByFileName[song.fileName] ?? index;
                  return SongListTile(song: song, songIndex: globalIndex);
                },
              ),
            );
          },
        ),
      );
}
