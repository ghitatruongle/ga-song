import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../providers/service_providers.dart';
import '../../core/audio/playlist_service.dart';
import '../../core/utils/sort_utils.dart';
import '../../models/song.dart';
import '../../core/cover_art_repository.dart';
import '../../core/logging/app_logger.dart';
import '../../core/performance_probe.dart';
import '../widgets/sidebar.dart';
import '../widgets/main_content.dart';
import '../widgets/bottom_player_bar.dart';
import '../widgets/cover_art_image.dart';
import '../widgets/settings_widget.dart';
import '../widgets/visualizer_widget.dart';
import '../../core/settings_manager.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme_utils.dart';
import '../utils/theme_helpers.dart';
import 'mini_player_screen.dart';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/lyric_provider.dart';
import '../../providers/song_provider.dart';
import '../widgets/lyric_view.dart';
import 'ktv_screen.dart';
import 'online_screen.dart';
import '../../core/services/music_manager.dart';
import '../../l10n/app_localizations.dart';
import '../widgets/playlist_manager_widget.dart';
import 'blurred_background.dart';
import '../widgets/album_grid_widget.dart';
import '../widgets/playlist_songs_view_widget.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  // ─── Layout Constants ──────────────────────────────────────────────────────
  // Note: sidebar width is now sourced from kSidebarExpandedWidth /
  // kSidebarCollapsedWidth (defined in sidebar.dart) so overlay layers
  // stay aligned to the actual sidebar width when collapsed.
  static const double _kBottomBarHeight = 90.0;
  static const double _kTitleBarTopOffset = 50.0;
  static const int _kPreloadNextSongCount = 3;
  static const double _kMinHeightForSidebar = 200.0;
  static const int _kBackgroundCoverWidth = 400;
  static const int _kBackgroundCoverHeight = 300;
  static const Duration _kBackgroundTransition = Duration(milliseconds: 800);
  static const Duration _kTabSwitchDuration = Duration(milliseconds: 200);

  late final PlaylistService _playlistService = ref.read(
    playlistServiceProvider,
  );
  late final CoverArtRepository _coverArtRepository = ref.read(
    coverArtRepositoryProvider,
  );
  late final SettingsManager _settingsManager = ref.read(
    settingsManagerProvider,
  );

  List<Song> _songs = [];
  Map<String, int> _songIndexByFileName = <String, int>{};
  bool _isLoading = true;
  String? _loadingError;
  String _searchQuery = '';
  TabItem _currentTab = TabItem.home;

  // P-1 fix: Cache merged listenable for background to avoid per-frame
  // Listenable.merge allocation and prevent nested ValueListenableBuilder.
  late final Listenable _backgroundListenable;

  // P2.1: Tab-change handling moved to ref.listen in build().

  /// Cache tabs có widget tĩnh (const) — build 1 lần, tái sử dụng vô hạn.
  /// Giúp chuyển tab về KTV/Personal/Settings/Online gần như tức thời.
  final Map<TabItem, Widget> _tabCache = {};
  String? _selectedPlaylistName;

  /// Danh sách bài hát đang được nạp vào PlaylistService.
  /// Dùng để tính index cục bộ khi user bấm bài trong playlist view.
  List<Song> _activePlaylistSongs = [];

  /// Cached map fileName → index trong _activePlaylistSongs.
  /// Chỉ rebuild khi _activePlaylistSongs thay đổi — tránh tạo Map mới mỗi build.
  Map<String, int> _cachedPlaylistIndexMap = {};

  /// Cached kết quả filter — tránh filter lại toàn bộ mỗi lần setState.
  List<Song>? _cachedFilteredSongs;
  String _lastFilterQuery = '';
  TabItem? _lastFilterTab;
  String? _lastFilterPlaylist;

  /// Cached album list — only rebuilt when _songs changes.
  List<String> _cachedAlbums = <String>[];

  /// Cached album → song count — O(1) lookup instead of O(n) scan per tile.
  Map<String, int> _cachedAlbumSongCount = <String, int>{};

  @override
  void initState() {
    super.initState();
    // P-1 fix: Merge all background-related notifiers into one listenable.
    // This eliminates 5 nested ValueListenableBuilder levels.
    _backgroundListenable = Listenable.merge(<Listenable>[
      _settingsManager.useNativeWindowEffectNotifier,
      _settingsManager.enableBlurNotifier,
      _settingsManager.blurLevelNotifier,
      _settingsManager.customBackgroundImageNotifier,
      _playlistService.currentIndexNotifier,
    ]);
    // P2.1: All sorting/tabIndex propagation now flows through
    // settingsNotifierProvider in build() via ref.listen (added below).
    // The local notifier subscriptions and _tabListener field are no
    // longer needed.
  }

  @override
  void dispose() {
    _tabCache.clear();
    super.dispose();
  }

  void _onSongChanged() {
    _loadDominantColor();
    final currentIndex = _playlistService.currentIndexNotifier.value;
    if (currentIndex >= 0 && currentIndex < _songs.length) {
      _coverArtRepository.preloadNextSongs(
        _songs,
        currentIndex,
        _kPreloadNextSongCount,
      );
    }
    // No setState here — child widgets observe currentIndexNotifier
    // via ValueListenableBuilder directly. Calling setState({}) was
    // rebuilding the entire HomeScreen tree (including the blurred
    // background) on every song change, which is very expensive.
  }

  /// Q-10 fix: Convert int mode to SortMode enum for consistency with PlaylistService.
  static SortMode _sortModeFromInt(int mode) =>
      SongSortUtils.sortModeFromInt(mode);

  void _applySort() {
    if (_songs.isEmpty) return;

    final settings = _settingsManager;
    final sortMode = _sortModeFromInt(settings.sortModeNotifier.value);
    final asc = settings.sortAscendingNotifier.value;
    final sorted = SongSortUtils.sorted(_songs, sortMode, ascending: asc);

    final indexByFileName = <String, int>{
      for (int i = 0; i < sorted.length; i++) sorted[i].fileName: i,
    };

    // Nếu đang xem một playlist cụ thể, re-sort _activePlaylistSongs
    // để giữ đồng bộ với thứ tự mới của _songs.
    List<Song>? newActiveSongs;
    if (_selectedPlaylistName != null && _activePlaylistSongs.isNotEmpty) {
      final activeFileNames = _activePlaylistSongs
          .map((s) => s.fileName)
          .toSet();
      newActiveSongs = sorted
          .where((s) => activeFileNames.contains(s.fileName))
          .toList();
    }

    setState(() {
      _songs = sorted;
      _songIndexByFileName = indexByFileName;
      _cachedFilteredSongs = null; // Invalidate filter cache after sort
      _cachedViewSongs = null; // P-4 fix: Invalidate view songs cache
      _rebuildAlbumCache();
      if (newActiveSongs != null) {
        _activePlaylistSongs = newActiveSongs;
        // Rebuild cached index map for active playlist after sort
        final newIndexMap = <String, int>{};
        for (int i = 0; i < newActiveSongs.length; i++) {
          newIndexMap[newActiveSongs[i].fileName] = i;
        }
        _cachedPlaylistIndexMap = newIndexMap;
      }
    });

    // Reorder playlist trong service theo danh sách đang active
    if (newActiveSongs != null) {
      _playlistService.reorderPlaylist(newActiveSongs);
    } else {
      _playlistService.reorderPlaylist(_songs);
    }
  }

  /// Rebuild album cache from _songs. Called only when _songs changes.
  void _rebuildAlbumCache() {
    const uncategorized = 'Chưa phân loại';
    final albumCounts = <String, int>{};
    for (final song in _songs) {
      final album = song.album;
      if (album != null && album.isNotEmpty) {
        albumCounts[album] = (albumCounts[album] ?? 0) + 1;
      } else {
        albumCounts[uncategorized] = (albumCounts[uncategorized] ?? 0) + 1;
      }
    }
    _cachedAlbums = albumCounts.keys.toList();
    _cachedAlbumSongCount = albumCounts;
  }

  // Database stream listener will update _songs instead
  Future<void> _handleSongsUpdate(List<Song> songs) async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _loadingError = null;
    });

    try {
      await _coverArtRepository.primeForSongs(songs);
      if (!mounted) return;

      _songs = songs;
      _applySort();

      if (_songs.isNotEmpty) {
        _loadDominantColor();
        final idx = _playlistService.currentIndexNotifier.value;
        if (idx >= 0 && idx < _songs.length) {
          _coverArtRepository.preloadNextSongs(_songs, idx, 3);
        }
      }
    } catch (error, stackTrace) {
      AppLogger.e(
        'home_screen',
        'Failed to process songs',
        error: error,
        stack: stackTrace,
      );
      if (!mounted) return;

      setState(() {
        _songs = <Song>[];
        _songIndexByFileName = <String, int>{};
        _loadingError = AppLocalizations.of(context).cannotLoadLibraryDb;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // P-4 fix: Cache filtered view songs to avoid recreating list on every access.
  List<Song>? _cachedViewSongs;
  String? _cachedViewPlaylistName;

  List<Song> get _currentViewSongs {
    if (_selectedPlaylistName == null) {
      return _songs;
    }
    // Return cached if playlist name hasn't changed
    if (_cachedViewSongs != null &&
        _cachedViewPlaylistName == _selectedPlaylistName) {
      return _cachedViewSongs!;
    }
    _cachedViewPlaylistName = _selectedPlaylistName;
    _cachedViewSongs = _selectedPlaylistName == 'Chưa phân loại'
        ? _songs.where((s) => s.album == null || s.album!.isEmpty).toList()
        : _songs.where((s) => s.album == _selectedPlaylistName).toList();
    return _cachedViewSongs!;
  }

  /// Trả về danh sách đã filter, có cache — tránh rebuild mỗi lần setState.
  List<Song> get _filteredSongs {
    final queryMatch = _lastFilterQuery == _searchQuery;
    final tabMatch = _lastFilterTab == _currentTab;
    final playlistMatch = _lastFilterPlaylist == _selectedPlaylistName;
    if (_cachedFilteredSongs != null &&
        queryMatch &&
        tabMatch &&
        playlistMatch) {
      return _cachedFilteredSongs!;
    }
    _lastFilterQuery = _searchQuery;
    _lastFilterTab = _currentTab;
    _lastFilterPlaylist = _selectedPlaylistName;

    final base = _currentTab == TabItem.library ? _songs : _currentViewSongs;
    if (_searchQuery.isEmpty) {
      _cachedFilteredSongs = base;
      return base;
    }
    _cachedFilteredSongs = base.where((song) {
      final nameLower = song.name.toLowerCase();
      final artistLower = song.artist?.toLowerCase() ?? '';
      final queryLower = _searchQuery.toLowerCase();
      return nameLower.contains(queryLower) || artistLower.contains(queryLower);
    }).toList();
    return _cachedFilteredSongs!;
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
      _cachedFilteredSongs = null; // Invalidate cache
    });
  }

  Widget _buildPlaylistsGrid() {
    return AlbumGridWidget(
      albums: _cachedAlbums,
      albumSongCount: _cachedAlbumSongCount,
      songs: _songs,
      onAlbumTap: _onAlbumTap,
    );
  }

  Widget _buildPlaylistSongsView() {
    return PlaylistSongsViewWidget(
      playlistName: _selectedPlaylistName,
      currentViewSongs: _currentViewSongs,
      filteredSongs: _filteredSongs,
      songIndexByFileName: _cachedPlaylistIndexMap,
      isLoading: _isLoading,
      loadingError: _loadingError,
      searchQuery: _searchQuery,
      onBack: () {
        setState(() {
          _selectedPlaylistName = null;
        });
      },
      onSearchChanged: _onSearchChanged,
      onRefresh: () {
        final asyncValue = ref.read(songListProvider);
        if (asyncValue.hasValue) {
          _handleSongsUpdate(asyncValue.value!);
        }
      },
    );
  }

  /// U-4 fix: Whether the sidebar is currently visible.
  bool _isSidebarVisible(BuildContext context) {
    return MediaQuery.of(context).size.height > _kMinHeightForSidebar;
  }

  /// C1/C2 fix: Width of the sidebar at its current collapse state.
  /// Used by overlay layers (bottom player bar, lyric overlay) so they
  /// stay aligned to the actual sidebar edge even when collapsed.
  double _currentSidebarWidth() {
    final isCollapsed = _settingsManager.sidebarCollapsedNotifier.value;
    return isCollapsed ? kSidebarCollapsedWidth : kSidebarExpandedWidth;
  }

  /// Hiển thị thông báo thân thiện khi tính năng không hỗ trợ platform hiện tại.
  Widget _buildUnsupportedPlatformMessage(String featureName, String message) {
    final adaptiveColor = context.adaptive;
    final spacing = ThemeSpacing.of(context);
    return Center(
      child: Padding(
        // 40dp ≈ xl + sm (32 + 8) — closest token composition while
        // preserving the visually distinctive large inset.
        padding: EdgeInsets.all(spacing.xl + spacing.sm),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.phonelink_off_rounded,
              size: 80,
              color: adaptiveColor.withValues(alpha: 0.3),
            ),
            SizedBox(height: spacing.lg),
            Text(
              featureName,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: adaptiveColor.withValues(alpha: 0.8),
              ),
            ),
            SizedBox(height: spacing.sm + spacing.xxs),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: adaptiveColor.withValues(alpha: 0.6),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Xử lý khi user chọn một album từ grid.
  /// Thiết lập playlist, xử lý special case, và cập nhật state.
  Future<void> _onAlbumTap(String albumName, List<Song> playlistSongs) async {
    await _playlistService.setPlaylist(playlistSongs);
    if (albumName == 'Mắt Nhắm Mắt Mở') {
      final trailerIdx = playlistSongs.indexWhere(
        (s) => s.fileName.contains('trailer'),
      );
      if (trailerIdx != -1) {
        _playlistService.setPlayMode(PlayMode.playOneStop);
        _playlistService.playSongAt(trailerIdx);
      }
    }
    // Build cached index map
    final indexMap = <String, int>{};
    for (int i = 0; i < playlistSongs.length; i++) {
      indexMap[playlistSongs[i].fileName] = i;
    }
    setState(() {
      _selectedPlaylistName = albumName;
      _activePlaylistSongs = playlistSongs;
      _cachedPlaylistIndexMap = indexMap;
      _cachedFilteredSongs = null;
    });
  }

  Widget _buildCurrentTab() {
    switch (_currentTab) {
      case TabItem.home:
        PerformanceProbe.instance.markSurface('Home');
        if (_selectedPlaylistName != null) {
          return _buildPlaylistSongsView();
        }
        return _buildPlaylistsGrid();
      case TabItem.library:
        PerformanceProbe.instance.markSurface('Library');
        return MainContentWidget(
          isLoading: _isLoading,
          loadingError: _loadingError,
          songs: _songs,
          filteredSongs: _filteredSongs,
          songIndexByFileName: _songIndexByFileName,
          onSearchChanged: _onSearchChanged,
          searchQuery: _searchQuery,
          onRefresh: () {
            final asyncValue = ref.read(songListProvider);
            if (asyncValue.hasValue) {
              _handleSongsUpdate(asyncValue.value!);
            }
          },
        );
      case TabItem.online:
        // YouTube player chỉ hỗ trợ trên Android (youtube_player_iframe không hỗ trợ Desktop)
        if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
          PerformanceProbe.instance.markSurface('Online Screen');
          return _tabCache.putIfAbsent(
            TabItem.online,
            () => const OnlineScreen(),
          );
        }
        // Hiển thị thông báo trên các nền tảng không hỗ trợ
        return _buildUnsupportedPlatformMessage(
          'YouTube',
          AppLocalizations.of(context).androidOnlyFeature,
        );
      case TabItem.ktv:
        PerformanceProbe.instance.markSurface('KTV Screen');
        return _tabCache.putIfAbsent(TabItem.ktv, () => const KTVScreen());
      case TabItem.personal:
        PerformanceProbe.instance.markSurface('Personal Visualizer');
        return _tabCache.putIfAbsent(
          TabItem.personal,
          () => const PersonalVisualizerWidget(),
        );
      case TabItem.settings:
        PerformanceProbe.instance.markSurface('Settings');
        return _tabCache.putIfAbsent(
          TabItem.settings,
          () => const SettingsWidget(),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Phase 2.3: ref.listen replaces direct addListener call.
    ref.listen<int>(currentPlayingIndexProvider, (_, next) {
      _onSongChanged();
    });
    // Listen to Isar songListProvider
    ref.listen<AsyncValue<List<Song>>>(songListProvider, (previous, next) {
      next.whenData((songs) {
        // If lengths are different, or it's first load, update
        if (previous?.value?.length != songs.length || _songs.isEmpty) {
          _handleSongsUpdate(songs);
        }
      });
    });

    // P2.1: ref.listen replaces local addListener for sort + tab changes.
    // The previous imperative listeners are gone; Riverpod re-runs this
    // listener whenever the relevant SettingsState field changes.
    ref.listen<({int sortMode, bool sortAscending})>(
      settingsNotifierProvider.select(
        (s) => (sortMode: s.sortMode, sortAscending: s.sortAscending),
      ),
      (_, _) => _applySort(),
    );
    ref.listen<int>(settingsNotifierProvider.select((s) => s.currentTabIndex), (
      _,
      next,
    ) {
      const tabs = TabItem.values;
      if (next >= 0 && next < tabs.length) {
        final newTab = tabs[next];
        if (newTab != _currentTab) {
          setState(() => _currentTab = newTab);
        }
      }
    });

    // ref.listen only fires on *state changes*. If the stream already emitted
    // before this widget built, the listener won't fire. Read the current
    // state once to seed _songs on first build.
    if (_songs.isEmpty && _isLoading) {
      final current = ref.read(songListProvider);
      current.whenData((songs) {
        if (songs.isNotEmpty) {
          _handleSongsUpdate(songs);
        }
      });
    }

    // On Android, also listen for native PiP mode changes
    return ValueListenableBuilder<bool>(
      valueListenable: ref.read(pipServiceProvider).isInPipNotifier,
      builder: (context, isInPip, _) {
        if (isInPip) {
          PerformanceProbe.instance.markSurface('Mini Player (PiP)');
          return const MiniPlayerScreen();
        }
        return ValueListenableBuilder<bool>(
          valueListenable: _settingsManager.isMiniPlayerNotifier,
          builder: (context, isMiniPlayer, _) {
            if (isMiniPlayer) {
              PerformanceProbe.instance.markSurface('Mini Player');
              return PopScope(
                canPop: false,
                onPopInvokedWithResult: (didPop, result) {
                  if (didPop) return;
                  _settingsManager.setIsMiniPlayer(false);
                },
                child: const MiniPlayerScreen(),
              );
            }
            return PopScope(
              canPop:
                  _currentTab == TabItem.home && _selectedPlaylistName == null,
              onPopInvokedWithResult: (didPop, result) {
                if (didPop) return;
                // Android back: nếu đang xem playlist -> về playlist grid
                // Nếu đang ở tab khác -> về Home
                if (_selectedPlaylistName != null) {
                  setState(() => _selectedPlaylistName = null);
                } else if (_currentTab != TabItem.home) {
                  setState(() => _currentTab = TabItem.home);
                }
              },
              child: Scaffold(
                backgroundColor: Colors.transparent,
                body: Stack(
                  children: [
                    // 1. Dynamic Blurred Background
                    // Uses ImageFiltered instead of BackdropFilter for performance:
                    // BackdropFilter re-blurs every pixel every frame (GPU killer).
                    // ImageFiltered blurs only its child; result is cached by compositor.
                    // P-1 fix: Single ListenableBuilder with merged listenable
                    // replaces 5 nested ValueListenableBuilder levels.
                    Positioned.fill(
                      child: RepaintBoundary(
                        child: ListenableBuilder(
                          listenable: _backgroundListenable,
                          builder: (context, _) {
                            final settings = _settingsManager;
                            final useNative =
                                settings.useNativeWindowEffectNotifier.value;
                            if (useNative) return const SizedBox.shrink();

                            final enableBlur =
                                settings.enableBlurNotifier.value;
                            final blurLevelVal =
                                settings.blurLevelNotifier.value;
                            final blurLevel = enableBlur ? blurLevelVal : 0.0;
                            final customBgPath =
                                settings.customBackgroundImageNotifier.value;

                            // Priority 1: Custom background image
                            if (customBgPath != null &&
                                customBgPath.isNotEmpty) {
                              return BlurredBackground(
                                blurLevel: blurLevel,
                                child: AnimatedSwitcher(
                                  duration: _kBackgroundTransition,
                                  child: Image.file(
                                    File(customBgPath),
                                    key: ValueKey('custom_bg_$customBgPath'),
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: double.infinity,
                                    filterQuality: FilterQuality.medium,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            Container(
                                              color: AppColors.darkBackground,
                                            ),
                                  ),
                                ),
                              );
                            }

                            // Priority 2: Cover art of currently playing song
                            final song = _playlistService.currentSong;
                            if (song != null) {
                              return BlurredBackground(
                                blurLevel: blurLevel,
                                child: AnimatedSwitcher(
                                  duration: _kBackgroundTransition,
                                  child: CoverArtImage(
                                    key: ValueKey(song.fileName),
                                    song: song,
                                    cacheWidth: _kBackgroundCoverWidth,
                                    cacheHeight: _kBackgroundCoverHeight,
                                    fallbackBuilder: (context) => Container(
                                      key: const ValueKey('default_bg'),
                                      color: AppColors.darkBackground,
                                    ),
                                  ),
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ),
                    ),

                    // 2. Main Content
                    Column(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              // Sidebar only shown when NOT in mini player mode
                              // and window has enough height
                              if (MediaQuery.of(context).size.height > 200)
                                SidebarWidget(
                                  currentTab: _currentTab,
                                  onTabChanged: (tab) {
                                    setState(() {
                                      _currentTab = tab;
                                      if (tab == TabItem.library) {
                                        _selectedPlaylistName = null;
                                        _cachedFilteredSongs = null;
                                      }
                                    });
                                    if (tab == TabItem.library) {
                                      WidgetsBinding.instance
                                          .addPostFrameCallback((_) {
                                            _playlistService.setPlaylist(
                                              _songs,
                                            );
                                          });
                                    }
                                  },
                                  onImportMusic: _importLocalSongs,
                                  onManagePlaylists: () =>
                                      PlaylistManagerWidget.show(context),
                                ),
                              // U-1 fix: AnimatedSwitcher adds fade transition between tabs
                              Expanded(
                                child: RepaintBoundary(
                                  child: AnimatedSwitcher(
                                    duration: _kTabSwitchDuration,
                                    switchInCurve: Curves.easeOut,
                                    switchOutCurve: Curves.easeIn,
                                    transitionBuilder: (child, animation) =>
                                        FadeTransition(
                                          opacity: animation,
                                          child: child,
                                        ),
                                    child: KeyedSubtree(
                                      key: ValueKey(_currentTab),
                                      child: _buildCurrentTab(),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    // 3. Floating Player Overlay (hidden on Settings tab)
                    // C1/C2 fix: use real sidebar width (220 expanded / 64
                    // collapsed) instead of the hardcoded 240 which both
                    // mismatched the actual sidebar AND ignored collapse state.
                    if (_currentTab != TabItem.settings)
                      Positioned(
                        left: _currentSidebarWidth(),
                        right: 0,
                        bottom: 0,
                        child: const RepaintBoundary(
                          child: BottomPlayerBarWidget(),
                        ),
                      ),

                    // 4. Standard Lyric Overlay (RepaintBoundary isolates
                    // lyric repaints from the background blur and song list)
                    Consumer(
                      builder: (context, ref, child) {
                        final showLyrics = ref.watch(lyricVisibilityProvider);
                        if (!showLyrics || _currentTab == TabItem.ktv) {
                          return const SizedBox.shrink();
                        }

                        // U-4 fix: Subtract sidebar width from available space.
                        // C1/C2 fix: use real sidebar width including collapse.
                        final screenWidth = MediaQuery.of(context).size.width;
                        final isSidebarVisible = _isSidebarVisible(context);
                        final availableWidth = isSidebarVisible
                            ? screenWidth - _currentSidebarWidth()
                            : screenWidth;
                        final radius = ThemeRadius.of(context);

                        return Positioned(
                          top: _kTitleBarTopOffset,
                          right: 0,
                          bottom: _kBottomBarHeight,
                          width: availableWidth / 2.5,
                          child: RepaintBoundary(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.6),
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(radius.xl),
                                  bottomLeft: Radius.circular(radius.xl),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.3),
                                    blurRadius: 10,
                                    offset: const Offset(-5, 0),
                                  ),
                                ],
                              ),
                              child: const LyricView(isFullScreen: false),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _loadDominantColor() async {
    final currentIndex = _playlistService.currentIndexNotifier.value;
    if (currentIndex >= 0 && currentIndex < _songs.length) {
      final song = _songs[currentIndex];
      _extractDominantColor(song);
    }
  }

  Future<void> _extractDominantColor(Song song) async {
    try {
      final color = await _coverArtRepository.resolveDominantColor(song);
      _settingsManager.dynamicPrimaryColorNotifier.value = color;
    } catch (e, stack) {
      AppLogger.e('home_screen', 'operation failed', error: e, stack: stack);
    }
  }

  Future<void> _importLocalSongs() async {
    final db = ref.read(databaseServiceProvider);
    final manager = MusicManager(db);
    final snackMessenger = ScaffoldMessenger.of(context);
    try {
      await manager.importLocalSongs();
      if (!mounted) return;
      snackMessenger.showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).importSuccess),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      snackMessenger.showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(
              context,
            ).translateWith('importErrorWithMsg', {'error': e.toString()}),
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}
