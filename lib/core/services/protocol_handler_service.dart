/// Protocol Handler Service for G.A - Song
///
/// Handles custom URI scheme (gasong://) for deep linking into the app.
/// Supports:
/// - gasong://play?song=<id>&playlist=<id>&position=<seconds>
/// - gasong://playlist?playlist=<id>&shuffle=<bool>
/// - gasong://search?q=<query>
/// - gasong://settings?page=<page_name>
/// - gasong://library?view=<view_name>
library;

import 'dart:async';

import 'package:app_links/app_links.dart';

import '../logging/app_logger.dart';
import '../platform_capabilities.dart';
import '../services/db_service_wrapper.dart';
import '../audio/playlist_service.dart';
import '../audio/audio_engine_service.dart';
import '../settings_manager.dart';
import '../../models/song.dart';

final _appLinks = AppLinks();

/// Supported protocol actions
enum ProtocolAction {
  play,
  playlist,
  search,
  settings,
  library,
  queue,
  lyrics,
  visualizer,
  unknown,
}

/// Result of protocol parsing
class ProtocolResult {
  final ProtocolAction action;
  final Map<String, String> parameters;
  final String rawUri;

  const ProtocolResult({
    required this.action,
    required this.parameters,
    required this.rawUri,
  });

  factory ProtocolResult.fromUri(Uri uri) {
    final action = _parseAction(uri);
    final parameters = _parseParameters(uri);
    return ProtocolResult(
      action: action,
      parameters: parameters,
      rawUri: uri.toString(),
    );
  }

  static ProtocolAction _parseAction(Uri uri) {
    final host = uri.host.toLowerCase();
    switch (host) {
      case 'play':
        return ProtocolAction.play;
      case 'playlist':
        return ProtocolAction.playlist;
      case 'search':
        return ProtocolAction.search;
      case 'settings':
        return ProtocolAction.settings;
      case 'library':
        return ProtocolAction.library;
      case 'queue':
        return ProtocolAction.queue;
      case 'lyrics':
        return ProtocolAction.lyrics;
      case 'visualizer':
        return ProtocolAction.visualizer;
      default:
        return ProtocolAction.unknown;
    }
  }

  static Map<String, String> _parseParameters(Uri uri) {
    final params = <String, String>{};
    for (final entry in uri.queryParameters.entries) {
      params[entry.key] = entry.value;
    }
    return params;
  }
}

/// Protocol Handler Service for gasong:// URIs
class ProtocolHandlerService {
  ProtocolHandlerService({
    DatabaseServiceWrapper? databaseService,
    PlaylistService? playlistService,
    AudioEngineService? audioEngineService,
    SettingsManager? settingsManager,
  }) : _databaseService = databaseService,
       _playlistService = playlistService,
       _audioEngineService = audioEngineService,
       _settingsManager = settingsManager;

  final DatabaseServiceWrapper? _databaseService;
  final PlaylistService? _playlistService;
  final AudioEngineService? _audioEngineService;
  final SettingsManager? _settingsManager;
  StreamSubscription? _uriSubscription;
  bool _initialized = false;

  /// Initialize the protocol handler
  Future<void> init() async {
    if (_initialized || !PlatformCapabilities.instance.isDesktop) return;
    _initialized = true;

    try {
      // Handle initial URI if app was launched via protocol
      final initialUri = await _appLinks.getInitialAppLink();
      if (initialUri != null) {
        await handleUri(initialUri);
      }

      // Listen for subsequent URI links
      _uriSubscription = _appLinks.uriLinkStream.listen(
        (uri) {
          handleUri(uri);
        },
        onError: (err) {
          AppLogger.w('protocol_handler', 'URI link stream error', error: err);
        },
      );

      AppLogger.i('protocol_handler', 'Protocol handler initialized');
    } catch (e, stack) {
      AppLogger.e(
        'protocol_handler',
        'Failed to initialize protocol handler',
        error: e,
        stack: stack,
      );
    }
  }

  /// Handle an incoming URI
  Future<void> handleUri(Uri uri) async {
    if (!uri.scheme.startsWith('gasong')) {
      AppLogger.w('protocol_handler', 'Ignoring non-gasong URI: $uri');
      return;
    }

    AppLogger.i('protocol_handler', 'Handling URI: $uri');

    final result = ProtocolResult.fromUri(uri);

    try {
      switch (result.action) {
        case ProtocolAction.play:
          await _handlePlay(result.parameters);
          break;
        case ProtocolAction.playlist:
          await _handlePlaylist(result.parameters);
          break;
        case ProtocolAction.search:
          await _handleSearch(result.parameters);
          break;
        case ProtocolAction.settings:
          await _handleSettings(result.parameters);
          break;
        case ProtocolAction.library:
          await _handleLibrary(result.parameters);
          break;
        case ProtocolAction.queue:
          await _handleQueue(result.parameters);
          break;
        case ProtocolAction.lyrics:
          await _handleLyrics(result.parameters);
          break;
        case ProtocolAction.visualizer:
          await _handleVisualizer(result.parameters);
          break;
        default:
          AppLogger.w('protocol_handler', 'Unknown action: ${result.action}');
      }
    } catch (e, stack) {
      AppLogger.e(
        'protocol_handler',
        'Failed to handle URI',
        error: e,
        stack: stack,
      );
    }
  }

  /// Handle play action: gasong://play?song=<id>&playlist=<id>&position=<seconds>
  Future<void> _handlePlay(Map<String, String> params) async {
    final songIdStr = params['song'];
    final playlistIdStr = params['playlist'];
    final positionStr = params['position'];

    if (songIdStr == null) {
      AppLogger.w('protocol_handler', 'Play action requires song parameter');
      return;
    }

    final songId = int.tryParse(songIdStr);
    final playlistId = playlistIdStr != null
        ? int.tryParse(playlistIdStr)
        : null;
    final position = positionStr != null
        ? Duration(seconds: int.tryParse(positionStr) ?? 0)
        : null;

    if (songId == null) {
      AppLogger.w('protocol_handler', 'Invalid song ID: $songIdStr');
      return;
    }

    AppLogger.i(
      'protocol_handler',
      'Play song: $songId, playlist: $playlistId, position: $position',
    );

    try {
      // Get song from database
      final song = await _databaseService?.getSong(songId);
      if (song == null) {
        AppLogger.w('protocol_handler', 'Song not found: $songId');
        return;
      }

      // If playlist is specified, set the playlist first
      if (playlistId != null) {
        final playlistSongs =
            await _databaseService?.getPlaylistSongsDirect(playlistId) ?? [];
        if (playlistSongs.isNotEmpty) {
          // Set playlist with song at specified index
          final index = playlistSongs.indexWhere((s) => s.id == songId);
          if (index >= 0) {
            // Use Riverpod provider to get playlist service and play
            await _playViaProvider(song, playlistSongs, index, position);
            return;
          }
        }
      }

      // Play single song
      await _playSingleSong(song, position);
    } catch (e, stack) {
      AppLogger.e(
        'protocol_handler',
        'Failed to play song',
        error: e,
        stack: stack,
      );
    }
  }

  /// Handle playlist action: gasong://playlist?playlist=<id>&shuffle=<bool>&view=<view_name>
  Future<void> _handlePlaylist(Map<String, String> params) async {
    final playlistIdStr = params['playlist'];
    final shuffleStr = params['shuffle'];
    final view = params['view'];

    final playlistId = playlistIdStr != null
        ? int.tryParse(playlistIdStr)
        : null;
    final shuffle = shuffleStr != null
        ? shuffleStr.toLowerCase() == 'true'
        : null;

    if (playlistId == null) {
      AppLogger.w(
        'protocol_handler',
        'Playlist action requires playlist parameter',
      );
      return;
    }

    AppLogger.i(
      'protocol_handler',
      'Open playlist: $playlistId, shuffle: $shuffle, view: $view',
    );

    try {
      final playlistSongs =
          await _databaseService?.getPlaylistSongsDirect(playlistId) ?? [];
      if (playlistSongs.isEmpty) {
        AppLogger.w(
          'protocol_handler',
          'Playlist not found or empty: $playlistId',
        );
        return;
      }

      // Apply shuffle if requested
      if (shuffle == true) {
        playlistSongs.shuffle();
      }

      await _setPlaylistViaProvider(playlistSongs);
    } catch (e, stack) {
      AppLogger.e(
        'protocol_handler',
        'Failed to open playlist',
        error: e,
        stack: stack,
      );
    }
  }

  /// Handle search action: gasong://search?q=<query>&type=<songs|playlists|artists|albums>
  Future<void> _handleSearch(Map<String, String> params) async {
    final query = params['q'] ?? params['query'];
    final type = params['type'];

    if (query == null || query.isEmpty) {
      AppLogger.w('protocol_handler', 'Search action requires query parameter');
      return;
    }

    AppLogger.i('protocol_handler', 'Search: $query, type: $type');

    try {
      final results = await _databaseService?.searchSongs(query) ?? [];
      if (results.isNotEmpty) {
        await _setPlaylistViaProvider(results);
      } else {
        AppLogger.i('protocol_handler', 'No search results for: $query');
      }
    } catch (e, stack) {
      AppLogger.e(
        'protocol_handler',
        'Failed to search',
        error: e,
        stack: stack,
      );
    }
  }

  /// Handle settings action: gasong://settings?page=<page_name>&subsection=<subsection>
  Future<void> _handleSettings(Map<String, String> params) async {
    final page = params['page'];
    final subsection = params['subsection'];

    AppLogger.i(
      'protocol_handler',
      'Open settings: page=$page, subsection=$subsection',
    );

    // Navigate to settings tab via provider
    try {
      final settings = _getSettingsManager();
      if (settings != null) {
        // Switch to settings tab (index 5)
        settings.currentTabIndexNotifier.value = 5;
        AppLogger.i('protocol_handler', 'Navigated to settings tab');
      }
    } catch (e, stack) {
      AppLogger.e(
        'protocol_handler',
        'Failed to open settings',
        error: e,
        stack: stack,
      );
    }
  }

  /// Handle library action: gasong://library?view=<view_name>&filter=<filter>
  Future<void> _handleLibrary(Map<String, String> params) async {
    final view = params['view'];
    final filter = params['filter'];

    AppLogger.i('protocol_handler', 'Open library: view=$view, filter=$filter');

    // Navigate to library tab via provider
    try {
      final settings = _getSettingsManager();
      if (settings != null) {
        // Switch to library tab (index 1)
        settings.currentTabIndexNotifier.value = 1;
        AppLogger.i('protocol_handler', 'Navigated to library tab');
      }
    } catch (e, stack) {
      AppLogger.e(
        'protocol_handler',
        'Failed to open library',
        error: e,
        stack: stack,
      );
    }
  }

  /// Handle queue action: gasong://queue?action=<add|remove|clear>&song=<id>
  Future<void> _handleQueue(Map<String, String> params) async {
    final action = params['action'];
    final songIdStr = params['song'];
    final songId = songIdStr != null ? int.tryParse(songIdStr) : null;

    AppLogger.i('protocol_handler', 'Queue action: $action, song: $songId');

    try {
      final playlist = _getPlaylistService();
      if (playlist == null) return;

      switch (action) {
        case 'add':
          if (songId != null) {
            final song = await _databaseService?.getSong(songId);
            if (song != null) {
              await playlist.add(song);
              AppLogger.i('protocol_handler', 'Added song $songId to queue');
            }
          }
          break;
        case 'remove':
          if (songId != null) {
            final index = playlist.playlist.indexWhere((s) => s.id == songId);
            if (index >= 0) {
              await playlist.remove(index);
              AppLogger.i(
                'protocol_handler',
                'Removed song $songId from queue',
              );
            }
          }
          break;
        case 'clear':
          await playlist.clear();
          AppLogger.i('protocol_handler', 'Cleared queue');
          break;
        default:
          AppLogger.w('protocol_handler', 'Unknown queue action: $action');
      }
    } catch (e, stack) {
      AppLogger.e(
        'protocol_handler',
        'Failed to manipulate queue',
        error: e,
        stack: stack,
      );
    }
  }

  /// Handle lyrics action: gasong://lyrics?song=<id>&line=<line_number>
  Future<void> _handleLyrics(Map<String, String> params) async {
    final songIdStr = params['song'];
    final lineStr = params['line'];
    final songId = songIdStr != null ? int.tryParse(songIdStr) : null;
    final line = lineStr != null ? int.tryParse(lineStr) : null;

    AppLogger.i('protocol_handler', 'Open lyrics: song=$songId, line=$line');

    // Show lyrics overlay via provider
    try {
      final settings = _getSettingsManager();
      if (settings != null) {
        settings.currentTabIndexNotifier.value = 3; // KTV tab shows lyrics
        AppLogger.i('protocol_handler', 'Navigated to KTV tab for lyrics');
      }
    } catch (e, stack) {
      AppLogger.e(
        'protocol_handler',
        'Failed to open lyrics',
        error: e,
        stack: stack,
      );
    }
  }

  /// Handle visualizer action: gasong://visualizer?shape=<shape_id>&fullscreen=<bool>
  Future<void> _handleVisualizer(Map<String, String> params) async {
    final shapeStr = params['shape'];
    final fullscreenStr = params['fullscreen'];
    final shape = shapeStr != null ? int.tryParse(shapeStr) : null;
    final fullscreen = fullscreenStr != null
        ? fullscreenStr.toLowerCase() == 'true'
        : null;

    AppLogger.i(
      'protocol_handler',
      'Open visualizer: shape=$shape, fullscreen=$fullscreen',
    );

    try {
      final settings = _getSettingsManager();
      if (settings != null) {
        // Set visualizer shape if specified
        if (shape != null && shape >= 0 && shape <= 7) {
          settings.visualizerShapeNotifier.value = shape;
        }
        // Navigate to Personal tab (index 4) which shows the visualizer
        settings.currentTabIndexNotifier.value = 4;
        AppLogger.i('protocol_handler', 'Navigated to visualizer tab');
      }
    } catch (e, stack) {
      AppLogger.e(
        'protocol_handler',
        'Failed to open visualizer',
        error: e,
        stack: stack,
      );
    }
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────

  /// Gets the PlaylistService (injected via constructor).
  PlaylistService? _getPlaylistService() => _playlistService;

  /// Gets the SettingsManager (injected via constructor).
  SettingsManager? _getSettingsManager() => _settingsManager;

  /// Gets the AudioEngineService (injected via constructor).
  AudioEngineService? _getAudioEngineService() => _audioEngineService;

  /// Plays a single song with optional position.
  Future<void> _playSingleSong(Song song, Duration? position) async {
    final playlist = _getPlaylistService();
    if (playlist == null) {
      AppLogger.w('protocol_handler', 'Playlist service not available');
      return;
    }

    await playlist.setPlaylist([song]);
    await playlist.playSongAt(0);

    if (position != null && position > Duration.zero) {
      final engine = _getAudioEngineService();
      await engine?.seek(position);
    }
  }

  /// Plays a song within a playlist.
  Future<void> _playViaProvider(
    Song song,
    List<Song> playlistSongs,
    int index,
    Duration? position,
  ) async {
    final playlist = _getPlaylistService();
    if (playlist == null) return;

    await playlist.setPlaylist(playlistSongs, startIndex: index);
    await playlist.playSongAt(index);

    if (position != null && position > Duration.zero) {
      final engine = _getAudioEngineService();
      await engine?.seek(position);
    }
  }

  /// Sets playlist without playing.
  Future<void> _setPlaylistViaProvider(List<Song> songs) async {
    final playlist = _getPlaylistService();
    if (playlist == null) return;
    await playlist.setPlaylist(songs);
  }

  /// Generate a protocol URI for sharing or deep linking
  static String generatePlayUri({
    required int songId,
    int? playlistId,
    Duration? position,
  }) {
    final params = <String, String>{'song': songId.toString()};
    if (playlistId != null) params['playlist'] = playlistId.toString();
    if (position != null) params['position'] = position.inSeconds.toString();

    return Uri(
      scheme: 'gasong',
      host: 'play',
      queryParameters: params,
    ).toString();
  }

  static String generatePlaylistUri({
    required int playlistId,
    bool? shuffle,
    String? view,
  }) {
    final params = <String, String>{};
    params['playlist'] = playlistId.toString();
    if (shuffle != null) params['shuffle'] = shuffle.toString();
    if (view != null) params['view'] = view;

    return Uri(
      scheme: 'gasong',
      host: 'playlist',
      queryParameters: params,
    ).toString();
  }

  static String generateSearchUri({required String query, String? type}) {
    final params = <String, String>{'q': query};
    if (type != null) params['type'] = type;

    return Uri(
      scheme: 'gasong',
      host: 'search',
      queryParameters: params,
    ).toString();
  }

  static String generateSettingsUri({String? page, String? subsection}) {
    final params = <String, String>{};
    if (page != null) params['page'] = page;
    if (subsection != null) params['subsection'] = subsection;

    return Uri(
      scheme: 'gasong',
      host: 'settings',
      queryParameters: params,
    ).toString();
  }

  static String generateLibraryUri({String? view, String? filter}) {
    final params = <String, String>{};
    if (view != null) params['view'] = view;
    if (filter != null) params['filter'] = filter;

    return Uri(
      scheme: 'gasong',
      host: 'library',
      queryParameters: params,
    ).toString();
  }

  static String generateQueueUri({required String action, int? songId}) {
    final params = <String, String>{'action': action};
    if (songId != null) params['song'] = songId.toString();

    return Uri(
      scheme: 'gasong',
      host: 'queue',
      queryParameters: params,
    ).toString();
  }

  static String generateLyricsUri({required int songId, int? line}) {
    final params = <String, String>{'song': songId.toString()};
    if (line != null) params['line'] = line.toString();

    return Uri(
      scheme: 'gasong',
      host: 'lyrics',
      queryParameters: params,
    ).toString();
  }

  static String generateVisualizerUri({int? shape, bool? fullscreen}) {
    final params = <String, String>{};
    if (shape != null) params['shape'] = shape.toString();
    if (fullscreen != null) params['fullscreen'] = fullscreen.toString();

    return Uri(
      scheme: 'gasong',
      host: 'visualizer',
      queryParameters: params,
    ).toString();
  }

  void dispose() {
    _uriSubscription?.cancel();
    _initialized = false;
  }
}
