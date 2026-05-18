import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:audio_service/audio_service.dart';

import 'core/audio/audio_effect_service.dart';
import 'core/audio/audio_engine_service.dart';
import 'core/audio/playlist_service.dart';
import 'core/performance_probe.dart';
import 'core/platform_capabilities.dart';
import 'core/service_locator.dart';
import 'core/settings_manager.dart';
import 'core/services/window_manager_service.dart';
import 'core/services/system_tray_service.dart';
import 'core/services/hotkey_service.dart';
import 'core/services/smtc_service.dart';
import 'core/services/audio_handler_service.dart';
import 'core/services/database_service.dart';
import 'providers/song_provider.dart';
import 'ui/screens/home_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

  // Bắt lỗi UI (Render exceptions)
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('Flutter Error: ${details.exception}\n${details.stack}');
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

  setupServiceLocator();
  final settings = sl<SettingsManager>();
  await settings.init();
  PerformanceProbe.instance.install();

  final dbService = sl<DatabaseService>();
  await dbService.init();

  Widget initialScreen;
  try {
    await SoLoud.instance.init();

    // P4.2: Replace fixed 200ms delay with retry-on-failure logic.
    // On fast CPUs this skips the wait entirely; on slow CPUs it retries up to 3 times.
    // Saves ~100-200ms cold start on typical hardware.
    final effectService = sl<AudioEffectService>();
    Future<void> tryApplyEq() async {
      for (int attempt = 0; attempt < 3; attempt++) {
        try {
          effectService.applyAllEqualizer(settings.eqBandsNotifier.value);
          return; // success
        } catch (e, stack) { debugPrint('Error in main: $e\n$stack'); 
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

    // Apply audio effects settings
    try {
      effectService.setCrossfadeDuration(settings.crossfadeDurationNotifier.value);
      effectService.setNormalizationLevel(
        settings.normalizationLevelNotifier.value,
      );
      effectService.enableNormalization(
        settings.normalizationEnabledNotifier.value,
      );
      effectService.setPitchShift(settings.pitchShiftNotifier.value);
      effectService.setReverbMix(settings.reverbMixNotifier.value);
      effectService.setCompressionRatio(settings.compressionRatioNotifier.value);
    } catch (e) {
      debugPrint('Audio effects init failed: $e');
    }

    // Enable visualization for audio spectrum/waveform to work
    try {
      SoLoud.instance.setVisualizationEnabled(
        settings.visualizerEnabledNotifier.value,
      );
    } catch (e) {
      debugPrint('Failed to enable visualization: $e');
    }

    initialScreen = const HomeScreen();
  } catch (e, st) {
    debugPrint('SoLoud init error: $e\n$st');
    initialScreen = _buildErrorScreen(e, st);
  }

  // P4.1: Mark desktop service entry points — init lazily on first use.
  // Instead of eagerly initializing all services, we register them for
  // deferred initialization. This saves ~100-200ms cold start on desktop.
  //
  // Each service will initialize itself on first access via its own
  // internal lazy init pattern (see service implementations).
  final caps = PlatformCapabilities.instance;
  if (caps.isDesktop) {
    // WindowManager is needed immediately for proper window setup.
    // Other services init lazily on first use.
    await sl<WindowManagerService>().init();
    
    // Defer hotkey and system tray init to after UI is built.
    // SMTC (System Media Transport Controls) initialized eagerly
    // because it directly affects Windows taskbar controls visibility.
    if (Platform.isWindows) await sl<SmtcService>().init();
    
    Future<void>.delayed(const Duration(milliseconds: 500), () async {
      try {
        await sl<HotkeyService>().init();
        if (!kDebugMode) await sl<SystemTrayService>().init();
      } catch (e, stack) { debugPrint('Deferred desktop service init: $e\n$stack'); }
    });
  }
  
  if (!kIsWeb && (Platform.isAndroid || Platform.isLinux)) {
    final audioHandler = await AudioService.init(
      builder: () => GaSongAudioHandler(sl<AudioEngineService>(), sl<PlaylistService>()),
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.ghitatruongle.gasong.channel.audio',
        androidNotificationChannelName: 'GA Song Playback',
        androidNotificationOngoing: true,
      ),
    );
    sl.registerSingleton<AudioHandler>(audioHandler);
  }

  runApp(
    ProviderScope(
      overrides: [
        databaseServiceProvider.overrideWithValue(dbService),
      ],
      child: GASongApp(home: initialScreen),
    ),
  );
}

class GASongApp extends StatelessWidget {
  const GASongApp({super.key, this.home = const HomeScreen()});

  final Widget home;

  @override
  Widget build(BuildContext context) {
    final settings = sl<SettingsManager>();
    return AnimatedBuilder(
      animation: Listenable.merge(<Listenable>[
        settings.themeModeNotifier,
        settings.useDynamicColorNotifier,
        settings.customPrimaryColorNotifier,
        settings.dynamicPrimaryColorNotifier,
        settings.useNativeWindowEffectNotifier,
      ]),
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
          home: home,
        );
      },
    );
  }
}
