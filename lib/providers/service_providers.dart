import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/audio/audio_engine_service.dart';
import '../core/audio/audio_effect_service.dart';
import '../core/audio/playlist_service.dart';
import '../core/audio/smart_shuffle_service.dart';
import '../core/cover_art_repository.dart';
import '../core/pip_service.dart';
import '../core/settings_manager.dart';
import '../core/services/hotkey_service.dart';
import '../core/services/system_tray_service.dart';
import '../core/services/window_manager_service.dart';
import '../core/services/db_service_wrapper.dart';
import '../core/database/app_database.dart';
import '../core/services/desktop_lyrics_service.dart';
import '../core/services/smart_playlist_service.dart';
import '../core/services/online_lyrics_service.dart';
import '../core/services/feedback_service.dart';
import '../core/services/jump_list_service.dart';
import '../core/services/protocol_handler_service.dart';
import '../core/services/music_manager.dart';
import '../ui/visualizer/visualizer_controller.dart';
export '../core/settings/settings_notifier.dart';
export 'state_providers.dart';

// ─── Core services ─────────────────────────────────────────────────────

final feedbackServiceProvider = Provider<FeedbackService>(
  (final ref) => FeedbackService(ref.watch(settingsManagerProvider)),
);

/// Database service for songs, playlists, and cover art cache.
final appDatabaseProvider = Provider<AppDatabase>((final ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

/// Database service for songs, playlists, and cover art cache.
final databaseServiceProvider = Provider<DatabaseServiceWrapper>((final ref) {
  final service = DatabaseServiceWrapper(ref.watch(appDatabaseProvider));
  ref.onDispose(() => service.dispose());
  return service;
});

/// Low-level audio playback engine (SoLoud).
final audioEngineServiceProvider = Provider<AudioEngineService>((final ref) {
  final service = AudioEngineService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// Audio effects: EQ, bass, reverb, compressor, normalization.
final audioEffectServiceProvider = Provider<AudioEffectService>((final ref) {
  final service = AudioEffectService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// App settings with SharedPreferences persistence.
final settingsManagerProvider = Provider<SettingsManager>((final ref) {
  final service = SettingsManager();
  ref.onDispose(() => service.dispose());
  return service;
});

/// Cover art 3-tier cache (memory → disk → source).
final coverArtRepositoryProvider = Provider<CoverArtRepository>((final ref) {
  final service = CoverArtRepository();
  ref.onDispose(() => service.dispose());
  return service;
});

/// Playlist management, shuffle, sort, sleep timer.
final playlistServiceProvider = Provider<PlaylistService>((final ref) {
  final engine = ref.read(audioEngineServiceProvider);
  final effect = ref.read(audioEffectServiceProvider);
  final db = ref.read(databaseServiceProvider);
  final service = PlaylistService(engine, effect, db);
  ref.onDispose(() => service.dispose());
  return service;
});

/// Android Picture-in-Picture service.
final pipServiceProvider = Provider<PipService>((final ref) {
  final service = PipService.instance;
  ref.onDispose(() => service.dispose());
  return service;
});

/// Global hotkey registration.
final hotkeyServiceProvider = Provider<HotkeyService>((final ref) {
  final settings = ref.read(settingsManagerProvider);
  return HotkeyService(settingsManager: settings);
});

/// System tray icon and context menu.
final systemTrayServiceProvider = Provider<SystemTrayService>((final ref) {
  final engine = ref.read(audioEngineServiceProvider);
  final playlist = ref.read(playlistServiceProvider);
  return SystemTrayService(
    audioEngineService: engine,
    playlistService: playlist,
  );
});

/// Desktop window management (resize, effects, lifecycle).
final windowManagerServiceProvider = Provider<WindowManagerService>((
  final ref,
) {
  final settings = ref.read(settingsManagerProvider);
  return WindowManagerService(settingsManager: settings);
});

/// Desktop floating lyrics overlay.
final desktopLyricsServiceProvider = Provider<DesktopLyricsService>((
  final ref,
) {
  final settings = ref.read(settingsManagerProvider);
  return DesktopLyricsService(settingsManager: settings);
});

/// Smart playlist generation from database.
final smartPlaylistServiceProvider = Provider<SmartPlaylistService>((
  final ref,
) {
  final db = ref.read(databaseServiceProvider);
  return SmartPlaylistService(db);
});

/// Online lyrics fetching from lrclib.net.
final onlineLyricsServiceProvider = Provider<OnlineLyricsService>(
  (final ref) => OnlineLyricsService(),
);

/// Smart shuffle service for weighted shuffle algorithm.
final smartShuffleServiceProvider = Provider<SmartShuffleService>(
  (final ref) => SmartShuffleService(),
);

/// Windows Jump List service for taskbar integration.
final jumpListServiceProvider = Provider<JumpListService>((final ref) {
  final service = JumpListService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// Protocol handler for gasong:// URIs.
final protocolHandlerServiceProvider = Provider<ProtocolHandlerService>((
  final ref,
) {
  final db = ref.read(databaseServiceProvider);
  final playlist = ref.read(playlistServiceProvider);
  final engine = ref.read(audioEngineServiceProvider);
  final settings = ref.read(settingsManagerProvider);
  final service = ProtocolHandlerService(
    databaseService: db,
    playlistService: playlist,
    audioEngineService: engine,
    settingsManager: settings,
  );
  ref.onDispose(() => service.dispose());
  return service;
});

/// Music manager for importing/deleting local songs.
final musicManagerProvider = Provider<MusicManager>((final ref) {
  final db = ref.read(databaseServiceProvider);
  return MusicManager(db);
});

/// Visualizer controller — singleton per ProviderScope.
/// v0.9.5: Kept for reference; GPU visualizer receives the controller
/// directly via constructor from [PersonalVisualizerWidget].
final visualizerControllerProvider = Provider<VisualizerController?>(
  (final ref) => null,
);
