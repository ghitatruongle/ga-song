import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'core/audio/audio_effect_service.dart';
import 'core/audio/audio_engine_service.dart';
import 'core/audio/playlist_service.dart';
import 'core/performance_probe.dart';
import 'core/platform_capabilities.dart';
import 'core/settings_manager.dart';
import 'core/services/window_manager_service.dart';
import 'core/services/system_tray_service.dart';
import 'core/services/hotkey_service.dart';
import 'core/cover_art_repository.dart';
import 'core/view_models/player_view_model.dart';
import 'core/pip_service.dart';
import 'core/services/smtc_service.dart';
import 'core/services/audio_handler_service.dart';
import 'core/services/database_service.dart';
import 'core/services/desktop_lyrics_service.dart';
import 'core/crash_reporter.dart';
import 'providers/service_providers.dart';
import 'ui/screens/home_screen.dart';

Widget _buildErrorScreen(Object error, StackTrace stackTrace) {
  return Scaffold(
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'Lỗi khởi tạo Audio Engine',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: const TextStyle(fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              stackTrace.toString(),
              style: TextStyle(fontSize: 10, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            const Text(
              'Vui lòng khởi động lại ứng dụng',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    ),
  );
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize sqflite for desktop platforms
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // Initialize crash reporter
  final crashReporter = DebugCrashReporter();
  await crashReporter.init();

  // Bắt lỗi UI (Render exceptions)
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    crashReporter.reportError(details.exception, details.stack ?? StackTrace.current,
        context: 'FlutterError');
  };

  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Material(
      color: Colors.black87,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 64),
              const SizedBox(height: 16),
              const Text(
                'Đã xảy ra lỗi hiển thị',
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                details.exceptionAsString(),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  };

  // Create services directly (no get_it)
  final settings = SettingsManager();
  await settings.init();
  PerformanceProbe.instance.install();

  final dbService = DatabaseService();
  await dbService.init();

  final engineService = AudioEngineService();
  final effectService = AudioEffectService();
  final playlistService = PlaylistService(engineService, effectService, dbService);
  final playerViewModel = PlayerViewModel(engineService, playlistService);
  final coverArtRepo = CoverArtRepository();

  Widget initialScreen;
  try {
    await SoLoud.instance.init();

    // P4.2: Replace fixed 200ms delay with retry-on-failure logic.
    Future<void> tryApplyEq() async {
      for (int attempt = 0; attempt < 3; attempt++) {
        try {
          effectService.applyAllEqualizer(settings.eqBandsNotifier.value);
          return;
        } catch (e, stack) {
          debugPrint('Error in main: $e\n$stack');
          if (attempt < 2) {
            await Future<void>.delayed(const Duration(milliseconds: 100));
          }
        }
      }
      debugPrint('EQ init failed after 3 retries (will retry on first play)');
    }

    await tryApplyEq();

    try {
      effectService.setBassLevel(settings.eqBassNotifier.value);
    } catch (e) {
      debugPrint('Bass init failed: $e');
    }

    try {
      effectService.setCrossfadeDuration(settings.crossfadeDurationNotifier.value);
      effectService.crossfadeCurveNotifier.value = settings.crossfadeCurveNotifier.value;
      effectService.setNormalizationLevel(settings.normalizationLevelNotifier.value);
      effectService.enableNormalization(settings.normalizationEnabledNotifier.value);
      effectService.setPitchShift(settings.pitchShiftNotifier.value);
      effectService.setReverbMix(settings.reverbMixNotifier.value);
      effectService.setCompressionRatio(settings.compressionRatioNotifier.value);
    } catch (e) {
      debugPrint('Audio effects init failed: $e');
    }

    try {
      SoLoud.instance.setVisualizationEnabled(settings.visualizerEnabledNotifier.value);
    } catch (e) {
      debugPrint('Failed to enable visualization: $e');
    }

    initialScreen = const HomeScreen();
  } catch (e, st) {
    debugPrint('SoLoud init error: $e\n$st');
    initialScreen = _buildErrorScreen(e, st);
  }

  // Desktop services
  final caps = PlatformCapabilities.instance;
  final windowManager = WindowManagerService(settingsManager: settings);
  final desktopLyricsService = DesktopLyricsService(settingsManager: settings);
  final hotkeyService = HotkeyService(
    settingsManager: settings,
    audioEngineService: engineService,
    playlistService: playlistService,
  );
  final systemTrayService = SystemTrayService(
    audioEngineService: engineService,
    playlistService: playlistService,
  );
  final pipService = PipService.instance;

  if (caps.isDesktop) {
    await windowManager.init();
    desktopLyricsService.init();
    if (Platform.isWindows) {
      final smtcService = SmtcService(engineService, playlistService);
      await smtcService.init();
    }
    Future<void>.delayed(const Duration(milliseconds: 500), () async {
      try {
        await hotkeyService.init();
        if (!kDebugMode) await systemTrayService.init();
      } catch (e, stack) {
        debugPrint('Deferred desktop service init: $e\n$stack');
      }
    });
  }

  if (!kIsWeb && (Platform.isAndroid || Platform.isLinux)) {
    await AudioService.init(
      builder: () => GaSongAudioHandler(engineService, playlistService),
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.ghitatruongle.gasong.channel.audio',
        androidNotificationChannelName: 'GA Song Playback',
        androidNotificationOngoing: true,
      ),
    );
    // AudioHandler is used internally by audio_service, no need to store in providers
  }

  runApp(
    ProviderScope(
      overrides: [
        databaseServiceProvider.overrideWithValue(dbService),
        audioEngineServiceProvider.overrideWithValue(engineService),
        audioEffectServiceProvider.overrideWithValue(effectService),
        playlistServiceProvider.overrideWithValue(playlistService),
        settingsManagerProvider.overrideWithValue(settings),
        coverArtRepositoryProvider.overrideWithValue(coverArtRepo),
        playerViewModelProvider.overrideWithValue(playerViewModel),
        pipServiceProvider.overrideWithValue(pipService),
        hotkeyServiceProvider.overrideWithValue(hotkeyService),
        systemTrayServiceProvider.overrideWithValue(systemTrayService),
        windowManagerServiceProvider.overrideWithValue(windowManager),
        desktopLyricsServiceProvider.overrideWithValue(desktopLyricsService),
      ],
      child: GASongApp(home: initialScreen),
    ),
  );
}

class GASongApp extends ConsumerStatefulWidget {
  const GASongApp({super.key, this.home = const HomeScreen()});

  final Widget home;

  @override
  ConsumerState<GASongApp> createState() => _GASongAppState();
}

class _GASongAppState extends ConsumerState<GASongApp> {
  late final Listenable _themeListenable;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsManagerProvider);
    _themeListenable = Listenable.merge([
      settings.themeModeNotifier,
      settings.useDynamicColorNotifier,
      settings.customPrimaryColorNotifier,
      settings.dynamicPrimaryColorNotifier,
      settings.useNativeWindowEffectNotifier,
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.read(settingsManagerProvider);
    return AnimatedBuilder(
      animation: _themeListenable,
      builder: (context, _) {
        final themeMode = settings.themeModeNotifier.value;
        final useDynamic = settings.useDynamicColorNotifier.value;
        final customColor = settings.customPrimaryColorNotifier.value;
        final dynamicColor = settings.dynamicPrimaryColorNotifier.value;
        final useNative = settings.useNativeWindowEffectNotifier.value;
        final primaryColor = useDynamic
            ? (dynamicColor ?? customColor)
            : customColor;

        return MaterialApp(
          title: 'G.A - Song',
          debugShowCheckedModeBanner: false,
          themeMode: themeMode,
          theme: ThemeData.light().copyWith(
            scaffoldBackgroundColor: useNative ? Colors.transparent : const Color(0xFFF5F5F5),
            primaryColor: primaryColor,
            colorScheme: ColorScheme.light(
              primary: primaryColor,
              secondary: primaryColor,
              surface: const Color(0xFFFFFFFF),
            ),
            cardColor: const Color(0xFFFFFFFF),
          ),
          darkTheme: ThemeData.dark().copyWith(
            scaffoldBackgroundColor: useNative ? Colors.transparent : const Color(0xFF121212),
            primaryColor: primaryColor,
            colorScheme: ColorScheme.dark(
              primary: primaryColor,
              secondary: primaryColor,
              surface: const Color(0xFF282828),
            ),
            cardColor: const Color(0xFF282828),
          ),
          home: widget.home,
        );
      },
    );
  }
}
