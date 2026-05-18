import 'dart:async';
import 'package:flutter/material.dart';

import '../../core/audio/audio_engine_service.dart';
import 'desktop_title_bar.dart';
import '../../core/audio/playlist_service.dart';
import '../../core/service_locator.dart';
import '../../core/settings_manager.dart';
import '../../core/theme_utils.dart';
import 'package:ga_song/models/song.dart';
import 'cover_art_image.dart';
import 'playlist_manager_widget.dart';

class MainContentWidget extends StatefulWidget {
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
  State<MainContentWidget> createState() => _MainContentWidgetState();
}

class _MainContentWidgetState extends State<MainContentWidget> {
  // #6: TextEditingController so the "X" clear button actually clears the UI.
  late final TextEditingController _searchController;
  Timer? _debounceTimer;

  // P-8 fix: Single listener at parent level instead of per-tile listeners.
  late final PlaylistService _playlistService;
  late final AudioEngineService _engineService;
  int _currentPlayingIndex = -1;
  AudioEngineState _engineState = AudioEngineState.stopped;

  void _onPlaybackChanged() {
    final newIndex = _playlistService.currentIndexNotifier.value;
    final newState = _engineService.engineState.value;
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
    // P-8 fix: Register 2 parent-level listeners instead of 200+ per-tile listeners.
    _playlistService = sl<PlaylistService>();
    _engineService = sl<AudioEngineService>();
    _currentPlayingIndex = _playlistService.currentIndexNotifier.value;
    _engineState = _engineService.engineState.value;
    _playlistService.currentIndexNotifier.addListener(_onPlaybackChanged);
    _engineService.engineState.addListener(_onPlaybackChanged);
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
    // P-8 fix: Remove parent-level listeners.
    _playlistService.currentIndexNotifier.removeListener(_onPlaybackChanged);
    _engineService.engineState.removeListener(_onPlaybackChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                ? _buildErrorState(context)
                : widget.songs.isEmpty
                ? _buildEmptyState(context)
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
                  valueListenable: sl<SettingsManager>().isGridViewNotifier,
                  builder: (context, isGrid, _) {
                    return IconButton(
                      icon: Icon(
                        isGrid ? Icons.list_rounded : Icons.grid_view_rounded,
                        color: context.adaptive,
                        size: 20,
                      ),
                      onPressed: () => sl<SettingsManager>().setIsGridView(!isGrid),
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

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(
            Icons.library_music_rounded,
            size: 80,
            color: context.adaptive.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 24),
          Text(
            'Chưa có bài hát nào',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: context.adaptive.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Thêm file nhạc vào thư mục assets/song/\nvà cập nhật file songs.json',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: context.adaptive.withValues(alpha: 0.5),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(
            Icons.error_outline_rounded,
            size: 80,
            color: context.adaptive.withValues(alpha: 0.35),
          ),
          const SizedBox(height: 24),
          Text(
            'Không thể tải thư viện bài hát',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: context.adaptive.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              widget.loadingError!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: context.adaptive.withValues(alpha: 0.6),
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: widget.onRefresh,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Thử tải lại'),
          ),
        ],
      ),
    );
  }

  Widget _buildSongList(BuildContext context) {
    // P-8 fix: Wrap with _SongPlaybackInheritedWidget so tiles can read
    // playback state via context instead of registering individual listeners.
    return _SongPlaybackInheritedWidget(
      currentIndex: _currentPlayingIndex,
      isPlaying: _engineState == AudioEngineState.playing,
      child: ValueListenableBuilder<bool>(
        valueListenable: sl<SettingsManager>().isGridViewNotifier,
        builder: (context, isGrid, _) {
          final itemCount = widget.filteredSongs.length;
          if (isGrid) {
            return RepaintBoundary(
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(40, 0, 40, 140),
                cacheExtent: 500,
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
                  return _SongGridTile(song: song, songIndex: songIndex);
                },
              ),
            );
          }

          return RepaintBoundary(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(40, 0, 40, 140),
              itemExtent: 86.0,
              cacheExtent: 500,
              addAutomaticKeepAlives: false,
              addRepaintBoundaries: false, // items have manual RepaintBoundary
              itemCount: itemCount,
              itemBuilder: (context, index) {
                final song = widget.filteredSongs[index];
                final songIndex =
                    widget.songIndexByFileName[song.fileName] ?? index;
                return _SongListTile(song: song, songIndex: songIndex);
              },
            ),
          );
        },
      ),
    );
  }
}

class _SongGridTile extends StatelessWidget {
  const _SongGridTile({required this.song, required this.songIndex});

  final Song song;
  final int songIndex;

  @override
  Widget build(BuildContext context) {
    // P-8 fix: Read playback state from InheritedWidget instead of per-tile listener.
    final playback = _SongPlaybackInheritedWidget.of(context);
    final isContext = playback.currentIndex == songIndex;
    final isPlaying = isContext && playback.isPlaying;

    return RepaintBoundary(
      child: InkWell(
        onTap: () {
          if (sl<PlaylistService>().playMode == PlayMode.playOneStop) {
            sl<PlaylistService>().setPlayMode(PlayMode.sequential);
          }
          sl<PlaylistService>().playSongByFileName(song.fileName);
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: isContext
                ? context.adaptive.withValues(alpha: 0.15)
                : context.adaptive.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isContext
                  ? context.adaptive.withValues(alpha: 0.3)
                  : context.adaptive.withValues(alpha: 0.05),
              width: 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: ColoredBox(
              color: context.adaptive.withValues(alpha: 0.02),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Expanded(
                    flex: 3,
                    child: Stack(
                      fit: StackFit.expand,
                      children: <Widget>[
                        CoverArtImage(
                          song: song,
                          cacheWidth: 320,
                          cacheHeight: 320,
                          fallbackBuilder: (context) => Center(
                            child: Icon(
                              Icons.music_note_rounded,
                              color: context.adaptiveSecondary,
                              size: 40,
                            ),
                          ),
                        ),
                        if (isPlaying)
                          IgnorePointer(
                            child: ColoredBox(
                              color: Colors.black.withValues(alpha: 0.5),
                              child: const Center(
                                child: Icon(
                                  Icons.equalizer_rounded,
                                  color: Colors.white,
                                  size: 40,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            song.name,
                            style: TextStyle(
                              color: context.adaptive,
                              fontWeight: isContext
                                  ? FontWeight.bold
                                  : FontWeight.w600,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  song.artist ?? 'Unknown',
                                  style: TextStyle(
                                    color: context.adaptive.withValues(
                                      alpha: 0.6,
                                    ),
                                    fontSize: 12,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.playlist_add),
                                onPressed: () => PlaylistManagerWidget.showAddToPlaylist(context, song),
                                iconSize: 18,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                color: context.adaptive.withValues(alpha: 0.5),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SongListTile extends StatelessWidget {
  const _SongListTile({required this.song, required this.songIndex});

  final Song song;
  final int songIndex;

  @override
  Widget build(BuildContext context) {
    // P-8 fix: Read playback state from InheritedWidget instead of per-tile listener.
    final playback = _SongPlaybackInheritedWidget.of(context);
    final isContext = playback.currentIndex == songIndex;
    final isPlaying = isContext && playback.isPlaying;

    return RepaintBoundary(
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isContext
              ? context.adaptive.withValues(alpha: 0.15)
              : context.adaptive.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isContext
                ? context.adaptive.withValues(alpha: 0.3)
                : context.adaptive.withValues(alpha: 0.05),
            width: 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          // #9: Removed per-item BackdropFilter (was 26 blur pass/frame).
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 10,
            ),
            hoverColor: context.adaptive.withValues(alpha: 0.08),
            leading: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: context.adaptive.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: <Widget>[
                  Positioned.fill(
                    child: CoverArtImage(
                      song: song,
                      cacheWidth: 104,
                      cacheHeight: 104,
                      fallbackBuilder: (context) => Icon(
                        isPlaying
                            ? Icons.equalizer_rounded
                            : Icons.music_note_rounded,
                        color: isPlaying
                            ? Colors.black
                            : context.adaptiveSecondary,
                        size: 26,
                      ),
                    ),
                  ),
                  if (isPlaying)
                    Positioned.fill(
                      child: ColoredBox(
                        color: context.adaptive.withValues(alpha: 0.7),
                        child: const Icon(
                          Icons.equalizer_rounded,
                          color: Colors.black,
                          size: 26,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            title: Text(
              song.name,
              style: TextStyle(
                color: context.adaptive,
                fontWeight: isPlaying ? FontWeight.bold : FontWeight.w600,
                fontSize: 16,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                song.artist ?? 'Unknown Artist',
                style: TextStyle(
                  color: context.adaptive.withValues(alpha: 0.6),
                  fontSize: 14,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.playlist_add),
                  color: context.adaptive.withValues(alpha: 0.5),
                  onPressed: () => PlaylistManagerWidget.showAddToPlaylist(context, song),
                ),
                const SizedBox(width: 8),
                Text(
                  (songIndex + 1).toString().padLeft(2, '0'),
                  style: TextStyle(
                    color: isContext
                        ? context.adaptive
                        : context.adaptive.withValues(alpha: 0.3),
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            onTap: () {
              if (sl<PlaylistService>().playMode == PlayMode.playOneStop) {
                sl<PlaylistService>().setPlayMode(PlayMode.sequential);
              }
              sl<PlaylistService>().playSongByFileName(song.fileName);
            },
          ),
        ),
      ),
    );
  }
}

/// P-8 fix: InheritedWidget that provides playback state to all song tiles.
/// Replaces per-tile listener registration (200+ listeners → 2 parent listeners).
class _SongPlaybackInheritedWidget extends InheritedWidget {
  const _SongPlaybackInheritedWidget({
    required this.currentIndex,
    required this.isPlaying,
    required super.child,
  });

  final int currentIndex;
  final bool isPlaying;

  static _SongPlaybackInheritedWidget of(BuildContext context) {
    final widget = context.dependOnInheritedWidgetOfExactType<_SongPlaybackInheritedWidget>();
    assert(widget != null, 'No _SongPlaybackInheritedWidget found in context');
    return widget!;
  }

  @override
  bool updateShouldNotify(_SongPlaybackInheritedWidget oldWidget) {
    return currentIndex != oldWidget.currentIndex ||
           isPlaying != oldWidget.isPlaying;
  }
}

class _SongPlaybackAware extends StatefulWidget {
  const _SongPlaybackAware({required this.songIndex, required this.builder});

  final int songIndex;
  final Widget Function(BuildContext, bool isContext, bool isPlaying) builder;

  @override
  State<_SongPlaybackAware> createState() => _SongPlaybackAwareState();
}

class _SongPlaybackAwareState extends State<_SongPlaybackAware> {
  late bool _isContext;
  late bool _isPlaying;
  late final PlaylistService _playlistService;
  late final AudioEngineService _engineService;

  @override
  void initState() {
    super.initState();
    _playlistService = sl<PlaylistService>();
    _engineService = sl<AudioEngineService>();
    _deriveState();
    _playlistService.currentIndexNotifier.addListener(_handlePlaybackChanged);
    _engineService.engineState.addListener(_handlePlaybackChanged);
  }

  @override
  void didUpdateWidget(covariant _SongPlaybackAware oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.songIndex != widget.songIndex) {
      _deriveState();
    }
    // B6 fix: Removed duplicate unconditional _deriveState() call
  }

  @override
  void dispose() {
    _playlistService.currentIndexNotifier.removeListener(
      _handlePlaybackChanged,
    );
    _engineService.engineState.removeListener(_handlePlaybackChanged);
    super.dispose();
  }

  void _handlePlaybackChanged() {
    final nextIsContext =
        _playlistService.currentIndexNotifier.value == widget.songIndex;
    final nextIsPlaying =
        nextIsContext &&
        _engineService.engineState.value == AudioEngineState.playing;
    if (nextIsContext == _isContext && nextIsPlaying == _isPlaying) {
      return;
    }

    setState(() {
      _isContext = nextIsContext;
      _isPlaying = nextIsPlaying;
    });
  }

  void _deriveState() {
    _isContext =
        _playlistService.currentIndexNotifier.value == widget.songIndex;
    _isPlaying =
        _isContext &&
        _engineService.engineState.value == AudioEngineState.playing;
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _isContext, _isPlaying);
  }
}
