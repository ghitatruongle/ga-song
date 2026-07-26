import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/audio/audio_engine_service.dart';
import '../core/audio/audio_effect_service.dart';
import '../core/audio/playlist_service.dart';
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
export '../core/settings/settings_notifier.dart';
export 'state_providers.dart';

// ─── Core services ─────────────────────────────────────────────────────

final feedbackServiceProvider = Provider<FeedbackService>((ref) {
  return FeedbackService(ref.watch(settingsManagerProvider));
});


/// Database service for songs, playlists, and cover art cache.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

/// Database service for songs, playlists, and cover art cache.
final databaseServiceProvider = Provider<DatabaseServiceWrapper>((ref) {
  final service = DatabaseServiceWrapper(ref.watch(appDatabaseProvider));
  ref.onDispose(() => service.dispose());
  return service;
});

/// Low-level audio playback engine (SoLoud).
final audioEngineServiceProvider = Provider<AudioEngineService>((ref) {
  final service = AudioEngineService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// Audio effects: EQ, bass, reverb, compressor, normalization.
final audioEffectServiceProvider = Provider<AudioEffectService>((ref) {
  final service = AudioEffectService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// App settings with SharedPreferences persistence.
final settingsManagerProvider = Provider<SettingsManager>((ref) {
  final service = SettingsManager();
  ref.onDispose(() => service.dispose());
  return service;
});

/// Cover art 3-tier cache (memory → disk → source).
final coverArtRepositoryProvider = Provider<CoverArtRepository>((ref) {
  final service = CoverArtRepository();
  ref.onDispose(() => service.dispose());
  return service;
});

/// Playlist management, shuffle, sort, sleep timer.
final playlistServiceProvider = Provider<PlaylistService>((ref) {
  final engine = ref.read(audioEngineServiceProvider);
  final effect = ref.read(audioEffectServiceProvider);
  final db = ref.read(databaseServiceProvider);
  final service = PlaylistService(engine, effect, db);
  ref.onDispose(() => service.dispose());
  return service;
});

/// Android Picture-in-Picture service.
final pipServiceProvider = Provider<PipService>((ref) {
  final service = PipService.instance;
  ref.onDispose(() => service.dispose());
  return service;
});

/// Global hotkey registration.
final hotkeyServiceProvider = Provider<HotkeyService>((ref) {
  final settings = ref.read(settingsManagerProvider);
  return HotkeyService(settingsManager: settings);
});

/// System tray icon and context menu.
final systemTrayServiceProvider = Provider<SystemTrayService>((ref) {
  final engine = ref.read(audioEngineServiceProvider);
  final playlist = ref.read(playlistServiceProvider);
  return SystemTrayService(
    audioEngineService: engine,
    playlistService: playlist,
  );
});

/// Desktop window management (resize, effects, lifecycle).
final windowManagerServiceProvider = Provider<WindowManagerService>((ref) {
  final settings = ref.read(settingsManagerProvider);
  return WindowManagerService(settingsManager: settings);
});

/// Desktop floating lyrics overlay.
final desktopLyricsServiceProvider = Provider<DesktopLyricsService>((ref) {
  final settings = ref.read(settingsManagerProvider);
  return DesktopLyricsService(settingsManager: settings);
});

/// Smart playlist generation from database.
final smartPlaylistServiceProvider = Provider<SmartPlaylistService>((ref) {
  final db = ref.read(databaseServiceProvider);
  return SmartPlaylistService(db);
});

/// Online lyrics fetching from lrclib.net.
final onlineLyricsServiceProvider = Provider<OnlineLyricsService>((ref) {
  return OnlineLyricsService();
});
