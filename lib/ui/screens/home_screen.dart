import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../core/service_locator.dart';
import '../../core/audio/playlist_service.dart';
import '../../song_model.dart';
import '../../core/cover_art_repository.dart';
import '../../core/performance_probe.dart';
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
import 'package:window_manager/window_manager.dart' hide WindowCaptionButton;
import '../widgets/window_caption_button.dart';
import '../../core/pip_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PlaylistService _playlistService = sl<PlaylistService>();
  final CoverArtRepository _coverArtRepository = sl<CoverArtRepository>();

  List<SongModel> _songs = [];
  Map<String, int> _songIndexByFileName = <String, int>{};
  bool _isLoading = true;
  String? _loadingError;
  String _searchQuery = '';
  TabItem _currentTab = TabItem.home;
  String? _selectedPlaylistName;

  /// Danh sách bài hát đang được nạp vào PlaylistService.
  /// Dùng để tính index cục bộ khi user bấm bài trong playlist view.
  List<SongModel> _activePlaylistSongs = [];

  /// Cached map fileName → index trong _activePlaylistSongs.
  /// Chỉ rebuild khi _activePlaylistSongs thay đổi — tránh tạo Map mới mỗi build.
  Map<String, int> _cachedPlaylistIndexMap = {};

  /// Cached kết quả filter — tránh filter lại toàn bộ mỗi lần setState.
  List<SongModel>? _cachedFilteredSongs;
  String _lastFilterQuery = '';
  TabItem? _lastFilterTab;
  String? _lastFilterPlaylist;

  @override
  void initState() {
    super.initState();
    _loadSongs();
    _playlistService.currentIndexNotifier.addListener(_onSongChanged);
    sl<SettingsManager>().sortModeNotifier.addListener(_applySort);
    sl<SettingsManager>().sortAscendingNotifier.addListener(_applySort);
  }

  @override
  void dispose() {
    _playlistService.currentIndexNotifier.removeListener(_onSongChanged);
    sl<SettingsManager>().sortModeNotifier.removeListener(_applySort);
    sl<SettingsManager>().sortAscendingNotifier.removeListener(_applySort);
    super.dispose();
  }

  void _onSongChanged() {
    _loadDominantColor();
    final currentIndex = _playlistService.currentIndexNotifier.value;
    if (currentIndex >= 0 && currentIndex < _songs.length) {
      _coverArtRepository.preloadNextSongs(_songs, currentIndex, 3);
    }
    if (mounted) {
      setState(() {});
    }
  }

  void _applySort() {
    if (_songs.isEmpty) return;

    final settings = sl<SettingsManager>();
    final mode = settings.sortModeNotifier.value;
    final asc = settings.sortAscendingNotifier.value;
    final int dir = asc ? 1 : -1;

    final sorted = List<SongModel>.from(_songs);
    sorted.sort((a, b) {
      switch (mode) {
        case 0: // Name
          return dir * a.name.toLowerCase().compareTo(b.name.toLowerCase());
        case 1: // Artist
          final aArtist = a.artist?.toLowerCase() ?? '';
          final bArtist = b.artist?.toLowerCase() ?? '';
          if (aArtist.isEmpty && bArtist.isEmpty) return 0;
          if (aArtist.isEmpty) return dir;
          if (bArtist.isEmpty) return -dir;
          return dir * aArtist.compareTo(bArtist);
        case 2: // Date Added
        case 3: // Duration
        default:
          return dir * a.name.toLowerCase().compareTo(b.name.toLowerCase());
      }
    });

    final indexByFileName = <String, int>{
      for (int i = 0; i < sorted.length; i++) sorted[i].fileName: i,
    };

    // Nếu đang xem một playlist cụ thể, re-sort _activePlaylistSongs
    // để giữ đồng bộ với thứ tự mới của _songs.
    List<SongModel>? newActiveSongs;
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

  Future<void> _loadSongs() async {
    setState(() {
      _isLoading = true;
      _loadingError = null;
    });

    try {
      final songs = await SongLoader.loadSongs();
      await _coverArtRepository.primeForSongs(
        songs.map((song) => song.fileName),
      );
      if (!mounted) {
        return;
      }

      // Assign raw list; _applySort() will sort & call setState once
      _songs = songs;
      _applySort();

      // Trigger dominant-color extraction & cover preload (no extra rebuild)
      if (_songs.isNotEmpty) {
        _loadDominantColor();
        final idx = _playlistService.currentIndexNotifier.value;
        if (idx >= 0 && idx < _songs.length) {
          _coverArtRepository.preloadNextSongs(_songs, idx, 3);
        }
      }
    } catch (error, stackTrace) {
      debugPrint('Failed to load songs: $error\n$stackTrace');
      if (!mounted) {
        return;
      }

      setState(() {
        _songs = <SongModel>[];
        _songIndexByFileName = <String, int>{};
        _loadingError =
            'Không thể tải danh sách bài hát. Vui lòng kiểm tra assets/song và thử tải lại.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  List<SongModel> get _currentViewSongs {
    if (_selectedPlaylistName == null) {
      return _songs;
    }
    return _songs.where((s) => s.album == _selectedPlaylistName).toList();
  }

  /// Trả về danh sách đã filter, có cache — tránh rebuild mỗi lần setState.
  List<SongModel> get _filteredSongs {
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

  Widget _buildTitleBar() {
    if (kIsWeb ||
        defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS) {
      return const SizedBox(height: 50); // Keep spacing but no buttons
    }
    return DragToMoveArea(
      child: SizedBox(
        height: 50,
        child: Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              WindowCaptionButton.minimize(
                onPressed: () async => windowManager.minimize(),
                iconNormal: Icon(
                  Icons.remove,
                  color: context.adaptive,
                  size: 20,
                ),
              ),
              const SizedBox(width: 8),
              WindowCaptionButton.maximize(
                onPressed: () async {
                  if (await windowManager.isMaximized()) {
                    await windowManager.unmaximize();
                  } else {
                    await windowManager.maximize();
                  }
                },
                iconNormal: Icon(
                  Icons.crop_square,
                  color: context.adaptive,
                  size: 18,
                ),
              ),
              const SizedBox(width: 8),
              WindowCaptionButton.close(
                onPressed: () async => windowManager.close(),
                iconNormal: Icon(
                  Icons.close,
                  color: context.adaptive,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaylistsGrid() {
    final adaptiveColor = context.adaptive;
    // Chỉ lấy các album được đặt tên — bỏ "ALL" vì Library tab đã là toàn bộ thư viện
    final albums = _songs
        .map((s) => s.album)
        .where((a) => a != null && a.isNotEmpty)
        .cast<String>()
        .toSet()
        .toList();

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
                      final count = _songs
                          .where((s) => s.album == albumName)
                          .length;

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
                              Padding(
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
            onRefresh: _loadSongs,
          ),
        ),
      ],
    );
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
          onRefresh: _loadSongs,
        );
      case TabItem.personal:
        PerformanceProbe.instance.markSurface('Personal Visualizer');
        return const PersonalVisualizerWidget();
      case TabItem.settings:
        PerformanceProbe.instance.markSurface('Settings');
        return const SettingsWidget();
    }
  }

  @override
  Widget build(BuildContext context) {
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
            return Scaffold(
              backgroundColor: Colors.transparent,
              body: Stack(
                children: [
                  // 1. Dynamic Blurred Background
                  // Uses ImageFiltered instead of BackdropFilter for performance:
                  // BackdropFilter re-blurs every pixel every frame (GPU killer).
                  // ImageFiltered blurs only its child; result is cached by compositor.
                  Positioned.fill(
                    child: RepaintBoundary(
                      child: ValueListenableBuilder<bool>(
                        valueListenable:
                            sl<SettingsManager>().enableBlurNotifier,
                        builder: (context, enableBlur, _) {
                          final blurLevel = enableBlur
                              ? sl<SettingsManager>().blurLevelNotifier.value
                              : 0.0;

                          return ValueListenableBuilder<String?>(
                            valueListenable: sl<SettingsManager>()
                                .customBackgroundImageNotifier,
                            builder: (context, customBgPath, _) {
                              // Priority 1: Custom background image
                              if (customBgPath != null &&
                                  customBgPath.isNotEmpty) {
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
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              Container(
                                                color: const Color(0xFF0F0F0F),
                                              ),
                                    ),
                                  ),
                                );
                              }

                              // Priority 2: Cover art of currently playing song
                              return ValueListenableBuilder<int>(
                                valueListenable:
                                    _playlistService.currentIndexNotifier,
                                builder: (context, currentIndex, child) {
                                  final song = _playlistService.currentSong;
                                  if (song != null) {
                                    return _BlurredBackground(
                                      blurLevel: blurLevel,
                                      child: AnimatedSwitcher(
                                        duration: const Duration(
                                          milliseconds: 800,
                                        ),
                                        child: CoverArtImage(
                                          key: ValueKey(song.fileName),
                                          fileName: song.fileName,
                                          cacheWidth: 400,
                                          cacheHeight: 300,
                                          fallbackBuilder: (context) =>
                                              Container(
                                                key: const ValueKey(
                                                  'default_bg',
                                                ),
                                                color: const Color(0xFF0F0F0F),
                                              ),
                                        ),
                                      ),
                                    );
                                  }
                                  return Container(
                                    color: const Color(0xFF0F0F0F),
                                  );
                                },
                              );
                            },
                          );
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
                            ),
                            Expanded(
                              child: RepaintBoundary(child: _buildCurrentTab()),
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
                ],
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
      _extractDominantColor(song.fileName);
    }
  }

  Future<void> _extractDominantColor(String fileName) async {
    try {
      final color = await _coverArtRepository.resolveDominantColor(fileName);
      sl<SettingsManager>().dynamicPrimaryColorNotifier.value = color;
    } catch (_) {}
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
