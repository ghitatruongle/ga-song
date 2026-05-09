import 'package:get_it/get_it.dart';
import 'audio/audio_engine_service.dart';
import 'audio/audio_effect_service.dart';
import 'audio/playlist_service.dart';
import 'cover_art_repository.dart';
import 'settings_manager.dart';
import 'view_models/player_view_model.dart';
import 'services/window_manager_service.dart';
import 'services/system_tray_service.dart';
import 'services/hotkey_service.dart';
import 'pip_service.dart';
import 'platform_capabilities.dart';

final sl = GetIt.instance;

void setupServiceLocator() {
  if (!sl.isRegistered<AudioEngineService>()) {
    sl.registerLazySingleton<AudioEngineService>(
      () => AudioEngineService(),
      dispose: (param) async => await param.dispose(),
    );
  }
  if (!sl.isRegistered<AudioEffectService>()) {
    sl.registerLazySingleton<AudioEffectService>(() => AudioEffectService());
  }
  if (!sl.isRegistered<PlaylistService>()) {
    sl.registerLazySingleton<PlaylistService>(
      () => PlaylistService(sl<AudioEngineService>(), sl<AudioEffectService>()),
      dispose: (param) => param.dispose(),
    );
  }
  if (!sl.isRegistered<SettingsManager>()) {
    sl.registerLazySingleton<SettingsManager>(
      () => SettingsManager(),
      dispose: (param) => param.dispose(),
    );
  }
  if (!sl.isRegistered<CoverArtRepository>()) {
    sl.registerLazySingleton<CoverArtRepository>(() => CoverArtRepository());
  }
  if (!sl.isRegistered<PlayerViewModel>()) {
    sl.registerLazySingleton<PlayerViewModel>(
      () => PlayerViewModel(sl<AudioEngineService>(), sl<PlaylistService>()),
      dispose: (param) => param.dispose(),
    );
  }
  if (PlatformCapabilities.instance.isDesktop) {
    if (!sl.isRegistered<WindowManagerService>()) {
      sl.registerLazySingleton<WindowManagerService>(() => WindowManagerService());
    }
    if (!sl.isRegistered<SystemTrayService>()) {
      sl.registerLazySingleton<SystemTrayService>(() => SystemTrayService());
    }
    if (!sl.isRegistered<HotkeyService>()) {
      sl.registerLazySingleton<HotkeyService>(() => HotkeyService());
    }
  }
  if (!sl.isRegistered<PipService>()) {
    sl.registerLazySingleton<PipService>(
      () => PipService.instance..init(),
      dispose: (param) => param.dispose(),
    );
  }
}

/// D3 fix: Gracefully shut down all services and clean up listeners
Future<void> teardownServices() async {
  await sl.reset();
}
