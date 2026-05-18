import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../core/service_locator.dart';
import '../../core/audio/playlist_service.dart';
import 'package:ga_song/models/song.dart';
import '../../core/cover_art_repository.dart';
import '../../core/performance_probe.dart';
import '../widgets/desktop_title_bar.dart';
import '../widgets/sidebar.dart';
import '../widgets/main_content.dart';
import '../widgets/bottom_player_bar.dart';
import '../widgets/cover_art_image.dart';
import '../widgets/settings_widget.dart';
import '../widgets/visualizer_widget.dart';
import '../../core/settings_manager.dart';
import '../../core/theme_utils.dart';
import 'mini_player_screen.dart';
import 'dart:io';
import '../../core/pip_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/lyric_provider.dart';
import '../../providers/song_provider.dart';
import '../widgets/lyric_view.dart';
import 'ktv_screen.dart';
import 'online_screen.dart';
import '../../core/services/music_manager.dart';
import '../widgets/playlist_manager_widget.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final PlaylistService _playlistService = sl<PlaylistService>();
  final CoverArtRepository _coverArtRepository = sl<CoverArtRepository>();
  final SettingsManager _settingsManager = sl<SettingsManager>();

  List<Song> _songs = [];
  Map<String, int> _songIndexByFileName = <String, int>{};
  bool _isLoading = true;
  String? _loadingError;
  String _searchQuery = '';
  TabItem _currentTab = TabItem.home;

  // P-1 fix: Cache merged listenable for background to avoid per-frame
  // Listenable.merge allocation and prevent nested ValueListenableBuilder.
  late final Listenable _backgroundListenable;

  // Listen to external tab changes (e.g. from KTVScreen exit button)
  void Function()? _tabListener;

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
      sl<SettingsManager>().useNativeWindowEffectNotifier,
      sl<SettingsManager>().enableBlurNotifier,
      sl<SettingsManager>().blurLevelNotifier,
      sl<SettingsManager>().customBackgroundImageNotifier,
      _playlistService.currentIndexNotifier,
    ]);
    _playlistService.currentIndexNotifier.addListener(_onSongChanged);
    sl<SettingsManager>().sortModeNotifier.addListener(_applySort);
    sl<SettingsManager>().sortAscendingNotifier.addListener(_applySort);
    // Listen for external tab changes (e.g. KTV back button)
    _tabListener = () {
      final tabIndex = _settingsManager.currentTabIndexNotifier.value;
      final tabs = TabItem.values;
      if (tabIndex >= 0 && tabIndex < tabs.length) {
        final newTab = tabs[tabIndex];
        if (newTab != _currentTab) {
          setState(() => _currentTab = newTab);
        }
      }
    };
    _settingsManager.currentTabIndexNotifier.addListener(_tabListener!);
  }

  @override
  void dispose() {
    _playlistService.currentIndexNotifier.removeListener(_onSongChanged);
    sl<SettingsManager>().sortModeNotifier.removeListener(_applySort);
    sl<SettingsManager>().sortAscendingNotifier.removeListener(_applySort);
    if (_tabListener != null) {
      _settingsManager.currentTabIndexNotifier.removeListener(_tabListener!);
    }
    _tabCache.clear();
    super.dispose();
  }

  void _onSongChanged() {
    _loadDominantColor();
    final currentIndex = _playlistService.currentIndexNotifier.value;
    if (currentIndex >= 0 && currentIndex < _songs.length) {
      _coverArtRepository.preloadNextSongs(_songs, currentIndex, 3);
    }
    // No setState here — child widgets observe currentIndexNotifier
    // via ValueListenableBuilder directly. Calling setState({}) was
    // rebuilding the entire HomeScreen tree (including the blurred
    // background) on every song change, which is very expensive.
  }

  /// Q-10 fix: Convert int mode to SortMode enum for consistency with PlaylistService.
  static SortMode _sortModeFromInt(int mode) {
    switch (mode) {
      case 0: return SortMode.name;
      case 1: return SortMode.artist;
      case 2: return SortMode.dateAdded;
      case 3: return SortMode.duration;
      default: return SortMode.name;
    }
  }

  void _applySort() {
    if (_songs.isEmpty) return;

    final settings = sl<SettingsManager>();
    final sortMode = _sortModeFromInt(settings.sortModeNotifier.value);
    final asc = settings.sortAscendingNotifier.value;
    final int dir = asc ? 1 : -1;

    final sorted = List<Song>.from(_songs);
    sorted.sort((a, b) {
      switch (sortMode) {
        case SortMode.name:
          return dir * a.name.toLowerCase().compareTo(b.name.toLowerCase());
        case SortMode.artist:
          final aArtist = a.artist?.toLowerCase() ?? '';
          final bArtist = b.artist?.toLowerCase() ?? '';
          if (aArtist.isEmpty && bArtist.isEmpty) return 0;
          if (aArtist.isEmpty) return dir;
          if (bArtist.isEmpty) return -dir;
          return dir * aArtist.compareTo(bArtist);
        case SortMode.dateAdded:
          final aDate = a.dateAdded ?? DateTime.fromMillisecondsSinceEpoch(0);
          final bDate = b.dateAdded ?? DateTime.fromMillisecondsSinceEpoch(0);
          return dir * aDate.compareTo(bDate);
        case SortMode.duration:
          final aDur = a.durationMs ?? 0;
          final bDur = b.durationMs ?? 0;
          return dir * aDur.compareTo(bDur);
      }
    });

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
    final albumCounts = <String, int>{};
    for (final song in _songs) {
      final album = song.album;
      if (album != null && album.isNotEmpty) {
        albumCounts[album] = (albumCounts[album] ?? 0) + 1;
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
      debugPrint('Failed to process songs: $error\n$stackTrace');
      if (!mounted) return;

      setState(() {
        _songs = <Song>[];
        _songIndexByFileName = <String, int>{};
        _loadingError = 'Không thể nạp danh sách bài hát từ Database.';
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
    if (_cachedViewSongs != null && _cachedViewPlaylistName == _selectedPlaylistName) {
      return _cachedViewSongs!;
    }
    _cachedViewPlaylistName = _selectedPlaylistName;
    _cachedViewSongs = _songs.where((s) => s.album == _selectedPlaylistName).toList();
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

  // Q-3 fix: Use shared DesktopTitleBar widget
  Widget _buildTitleBar() => const DesktopTitleBar();

  Widget _buildPlaylistsGrid() {
    final adaptiveColor = context.adaptive;
    // Use cached album list — rebuilt only when _songs changes (in _rebuildAlbumCache)
    final albums = _cachedAlbums;

    return Column(
      children: [
        _buildTitleBar(),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(40, 10, 40, 40),
            child: albums.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.album_rounded,
                          size: 64,
                          color: adaptiveColor.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Chưa có playlist nào',
                          style: TextStyle(
                            fontSize: 18,
                            color: adaptiveColor.withValues(alpha: 0.6),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Thêm trường "album" vào songs.json để tạo playlist',
                          style: TextStyle(
                            fontSize: 13,
                            color: adaptiveColor.withValues(alpha: 0.4),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 200,
                          childAspectRatio: 1.0,
                          crossAxisSpacing: 24,
                          mainAxisSpacing: 24,
                        ),
                    itemCount: albums.length,
                    itemBuilder: (context, index) {
                      final albumName = albums[index];
                      // O(1) lookup from cached map instead of O(n) scan
                      final count = _cachedAlbumSongCount[albumName] ?? 0;


                      return GestureDetector(
                        onTap: () async {
                          final playlistSongs = _songs
                              .where((s) => s.album == albumName)
                              .toList();
                          await sl<PlaylistService>().setPlaylist(
                            playlistSongs,
                          );
                          if (albumName == 'Mắt Nhắm Mắt Mở') {
                            final trailerIdx = playlistSongs.indexWhere(
                              (s) => s.fileName.contains('trailer'),
                            );
                            if (trailerIdx != -1) {
                              sl<PlaylistService>().setPlayMode(
                                PlayMode.playOneStop,
                              );
                              sl<PlaylistService>().playSongAt(trailerIdx);
                            }
                          }
                          // Lưu active playlist và rebuild cached index map
                          final indexMap = <String, int>{};
                          for (int i = 0; i < playlistSongs.length; i++) {
                            indexMap[playlistSongs[i].fileName] = i;
                          }
                          setState(() {
                            _selectedPlaylistName = albumName;
                            _activePlaylistSongs = playlistSongs;
                            _cachedPlaylistIndexMap = indexMap;
                            _cachedFilteredSongs =
                                null; // Invalidate filter cache
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: adaptiveColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: adaptiveColor.withValues(alpha: 0.2),
                              width: 2,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (albumName == 'Mắt Nhắm Mắt Mở')
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.asset(
                                    'assets/pic/mat_nham_mat_mo/mat_nham_mat_mo_trailer.png',
                                    width: 64,
                                    height: 64,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              else
                                Icon(
                                  Icons.album_rounded,
                                  size: 64,
                                  color: adaptiveColor.withValues(alpha: 0.8),
                                ),
                              const SizedBox(height: 16),
                              Flexible(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  child: Text(
                                    albumName,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: adaptiveColor.withValues(alpha: 0.9),
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '$count bài hát',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: adaptiveColor.withValues(alpha: 0.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlaylistSongsView() {
    return Column(
      children: [
        _buildTitleBar(),
        Padding(
          padding: const EdgeInsets.fromLTRB(40, 10, 40, 10),
          child: Row(
            children: [
              IconButton(
                onPressed: () {
                  setState(() {
                    _selectedPlaylistName = null;
                  });
                },
                icon: Icon(
                  Icons.arrow_back_rounded,
                  color: context.adaptive.withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _selectedPlaylistName ?? '',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: context.adaptive.withValues(alpha: 0.9),
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: MainContentWidget(
            showTitleBar: false,
            isLoading: _isLoading,
            loadingError: _loadingError,
            songs: _currentViewSongs,
            filteredSongs: _filteredSongs,
            // Fix: dùng index cục bộ trong playlist đang active,
            // không phải index toàn cục. Đảm bảo playSongAt() nhận
            // đúng index trong PlaylistService._playlist.
            songIndexByFileName: _cachedPlaylistIndexMap,
            onSearchChanged: _onSearchChanged,
            searchQuery: _searchQuery,
            onRefresh: () {
              // The stream handles real-time updates, but user can still force reload
              final asyncValue = ref.read(songListProvider);
              if (asyncValue.hasValue) {
                _handleSongsUpdate(asyncValue.value!);
              }
            },
          ),
        ),
      ],
    );
  }

  /// U-4 fix: Whether the sidebar is currently visible.
  bool _isSidebarVisible(BuildContext context) {
    return MediaQuery.of(context).size.height > 200;
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
          return _tabCache.putIfAbsent(TabItem.online, () => const OnlineScreen());
        }
        // Fallback về Home nếu bằng cách nào đó desktop chọn tab này
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() => _currentTab = TabItem.home);
        });
        return const SizedBox.shrink();
      case TabItem.ktv:
        PerformanceProbe.instance.markSurface('KTV Screen');
        return _tabCache.putIfAbsent(TabItem.ktv, () => const KTVScreen());
      case TabItem.personal:
        PerformanceProbe.instance.markSurface('Personal Visualizer');
        return _tabCache.putIfAbsent(TabItem.personal, () => const PersonalVisualizerWidget());
      case TabItem.settings:
        PerformanceProbe.instance.markSurface('Settings');
        return _tabCache.putIfAbsent(TabItem.settings, () => const SettingsWidget());
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen to Isar songListProvider
    ref.listen<AsyncValue<List<Song>>>(songListProvider, (previous, next) {
      next.whenData((songs) {
        // If lengths are different, or it's first load, update
        if (previous?.value?.length != songs.length || _songs.isEmpty) {
          _handleSongsUpdate(songs);
        }
      });
    });

    // On Android, also listen for native PiP mode changes
    return ValueListenableBuilder<bool>(
      valueListenable: sl<PipService>().isInPipNotifier,
      builder: (context, isInPip, _) {
        if (isInPip) {
          PerformanceProbe.instance.markSurface('Mini Player (PiP)');
          return const MiniPlayerScreen();
        }
        return ValueListenableBuilder<bool>(
          valueListenable: sl<SettingsManager>().isMiniPlayerNotifier,
          builder: (context, isMiniPlayer, _) {
            if (isMiniPlayer) {
              PerformanceProbe.instance.markSurface('Mini Player');
              return PopScope(
                canPop: false,
                onPopInvokedWithResult: (didPop, result) {
                  if (didPop) return;
                  sl<SettingsManager>().setIsMiniPlayer(false);
                },
                child: const MiniPlayerScreen(),
              );
            }
            return PopScope(
              canPop: _currentTab == TabItem.home && _selectedPlaylistName == null,
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
                          final settings = sl<SettingsManager>();
                          final useNative = settings.useNativeWindowEffectNotifier.value;
                          if (useNative) return const SizedBox.shrink();

                          final enableBlur = settings.enableBlurNotifier.value;
                          final blurLevelVal = settings.blurLevelNotifier.value;
                          final blurLevel = enableBlur ? blurLevelVal : 0.0;
                          final customBgPath = settings.customBackgroundImageNotifier.value;

                          // Priority 1: Custom background image
                          if (customBgPath != null && customBgPath.isNotEmpty) {
                            return _BlurredBackground(
                              blurLevel: blurLevel,
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 800),
                                child: Image.file(
                                  File(customBgPath),
                                  key: ValueKey('custom_bg_$customBgPath'),
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                  filterQuality: FilterQuality.medium,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Container(color: const Color(0xFF0F0F0F)),
                                ),
                              ),
                            );
                          }

                          // Priority 2: Cover art of currently playing song
                          final song = _playlistService.currentSong;
                          if (song != null) {
                            return _BlurredBackground(
                              blurLevel: blurLevel,
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 800),
                                child: CoverArtImage(
                                  key: ValueKey(song.fileName),
                                  song: song,
                                  cacheWidth: 400,
                                  cacheHeight: 300,
                                  fallbackBuilder: (context) => Container(
                                    key: const ValueKey('default_bg'),
                                    color: const Color(0xFF0F0F0F),
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
                                    WidgetsBinding.instance.addPostFrameCallback((_) {
                                      _playlistService.setPlaylist(_songs);
                                    });
                                  }
                                },
                                onImportMusic: _importLocalSongs,
                                onManagePlaylists: () => PlaylistManagerWidget.show(context),
                              ),
                            // U-1 fix: AnimatedSwitcher adds fade transition between tabs
                            Expanded(
                              child: RepaintBoundary(
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 200),
                                  switchInCurve: Curves.easeOut,
                                  switchOutCurve: Curves.easeIn,
                                  transitionBuilder: (child, animation) =>
                                      FadeTransition(opacity: animation, child: child),
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
                  if (_currentTab != TabItem.settings)
                    const Positioned(
                      left: 240,
                      right: 0,
                      bottom: 0,
                      child: RepaintBoundary(child: BottomPlayerBarWidget()),
                    ),
                  
                  // 4. Standard Lyric Overlay (RepaintBoundary isolates
                  // lyric repaints from the background blur and song list)
                  Consumer(
                    builder: (context, ref, child) {
                      final showLyrics = ref.watch(lyricVisibilityProvider);
                      if (!showLyrics || _currentTab == TabItem.ktv) return const SizedBox.shrink();
                      
                      // U-4 fix: Subtract sidebar width from available space
                      final screenWidth = MediaQuery.of(context).size.width;
                      final isSidebarVisible = _isSidebarVisible(context);
                      final availableWidth = isSidebarVisible
                          ? screenWidth - 240 // sidebar width
                          : screenWidth;

                      return Positioned(
                        top: 50,
                        right: 0,
                        bottom: 90, // Leave space for bottom bar
                        width: availableWidth / 2.5,
                        child: RepaintBoundary(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.6),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(24),
                                bottomLeft: Radius.circular(24),
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
      sl<SettingsManager>().dynamicPrimaryColorNotifier.value = color;
    } catch (e, stack) { debugPrint('Error in home_screen: $e\n$stack'); }
  }

  Future<void> _importLocalSongs() async {
    final isar = ref.read(isarProvider);
    final manager = MusicManager(isar);
    final snackMessenger = ScaffoldMessenger.of(context);
    try {
      await manager.importLocalSongs();
      if (!mounted) return;
      snackMessenger.showSnackBar(
        const SnackBar(
          content: Text('Đã import nhạc thành công!'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      snackMessenger.showSnackBar(
        SnackBar(
          content: Text('Lỗi import nhạc: $e'),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}

/// Wraps [child] with an [ImageFiltered] blur and a dark tint.
///
/// Unlike [BackdropFilter], this only blurs the image itself (not the entire
/// scene behind it), and the result is cached by the compositor between frames.
/// This eliminates the per-frame GPU cost that made the old approach a
/// performance bottleneck.
class _BlurredBackground extends StatelessWidget {
  const _BlurredBackground({required this.blurLevel, required this.child});

  final double blurLevel;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Blurred image layer
        if (blurLevel > 0)
          ImageFiltered(
            imageFilter: ImageFilter.blur(
              sigmaX: blurLevel,
              sigmaY: blurLevel,
              tileMode: TileMode.clamp,
            ),
            child: child,
          )
        else
          child,
        // Dark tint overlay
        IgnorePointer(
          child: ColoredBox(color: Colors.black.withValues(alpha: 0.5)),
        ),
      ],
    );
  }
}
