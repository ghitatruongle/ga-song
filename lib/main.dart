import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'core/audio/audio_effect_service.dart';
import 'core/audio/audio_engine_service.dart';
import 'core/audio/playlist_service.dart';
import 'core/audio/smart_shuffle_service.dart';
import 'core/logging/app_logger.dart';
import 'core/performance_probe.dart';
import 'core/platform_capabilities.dart';
import 'core/settings_manager.dart';
import 'core/services/window_manager_service.dart';
import 'core/services/power_state_service.dart';
import 'core/services/system_tray_service.dart';
import 'core/services/hotkey_service.dart';
import 'core/cover_art_repository.dart';
import 'ui/visualizer/visualizer_controller.dart';
import 'core/pip_service.dart';
import 'core/services/smtc_service.dart';
import 'core/services/audio_handler_service.dart';
import 'core/services/db_service_wrapper.dart';
import 'core/services/desktop_lyrics_service.dart';
import 'core/services/protocol_handler_service.dart';
import 'core/services/jump_list_service.dart';
import 'core/crash_reporter.dart';
import 'core/motion/app_motion.dart';
import 'core/theme/tokens.dart';
import 'core/database/app_database.dart';
import 'core/database/migration/migration_service.dart';
import 'l10n/app_localizations.dart';
import 'providers/service_providers.dart';
import 'providers/theme_provider.dart';
import 'core/platforms/platform_service.dart';
import 'core/platforms/macos/macos_integration.dart';
import 'core/platforms/macos/macos_menu_bar.dart';
import 'core/platforms/ios/ios_integration.dart';
import 'ui/screens/home_screen.dart';
import 'ui/widgets/frame_budget_overlay.dart';
import 'ui/widgets/settings_search_dialog.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// Intent to open the Settings Search dialog.
class _OpenSettingsSearchIntent extends Intent {
  const _OpenSettingsSearchIntent();
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Wire the logger to debugPrint BEFORE anything else logs, otherwise all
  // diagnostics are silently dropped (sink defaults to null).
  AppLogger.init();
  final startupStopwatch = Stopwatch()..start();

  // Platform capabilities. Image-cache sizing is applied AFTER
  // SettingsManager.init() so the persisted Reduce Lag flag is honored from
  // the very first frame (see applyImageCacheConfig below).
  final caps = PlatformCapabilities.instance;

  // Initialize sqflite for desktop platforms
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // Initialize crash reporter
  final crashReporter = DebugCrashReporter();
  await crashReporter.init();
  for (final r in AppLogger.drainPendingCrashReports()) {
    crashReporter.reportError(
      r.error ?? StateError(r.msg),
      r.stack ?? StackTrace.current,
      context: r.tag,
    );
  }

  // Render exceptions
  FlutterError.onError = (final FlutterErrorDetails details) {
    FlutterError.presentError(details);
    crashReporter.reportError(
      details.exception,
      details.stack ?? StackTrace.current,
      context: 'FlutterError',
    );
  };

  ErrorWidget.builder = (final FlutterErrorDetails details) => Material(
    color: Colors.black87,
    child: Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: Colors.orange,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              lookupAppLocalizations(const Locale('vi')).renderError,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
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

  // Create services directly (no get_it)
  final settings = SettingsManager();
  await settings.init(); // Critical: must complete before UI
  PerformanceProbe.instance.install();

  // ─── Image cache + Reduce Lag (Android-only) ─────────────────────────────
  final imageCache = PaintingBinding.instance.imageCache;

  void applyImageCacheConfig() {
    if (caps.reduceLagOverride) {
      imageCache.maximumSizeBytes = 8 * 1024 * 1024; // 8MB — lowest tier
      imageCache.maximumSize = 15;
    } else if (caps.isAndroid && caps.effectiveTier == DeviceTier.low) {
      imageCache.maximumSizeBytes =
          16 * 1024 * 1024; // 16MB for low-spec Android
      imageCache.maximumSize = 25;
    } else if (caps.isAndroid) {
      imageCache.maximumSizeBytes = 32 * 1024 * 1024; // 32MB mid-tier Android
      imageCache.maximumSize = 50;
    } else {
      imageCache.maximumSizeBytes = 120 * 1024 * 1024; // 120MB for Desktop
      imageCache.maximumSize = 150;
    }
  }

  // Reduce Lag runtime override: force visualizer + blur off WITHOUT touching
  // user preferences, pin every PlatformCapabilities knob to low tier, and
  // shrink the image cache. Restores everything when toggled off. Reactive —
  // the VisualizerController already listens to visualizerEnabledNotifier and
  // stops its ticker, so no further wiring is needed.
  bool? userVisualizerEnabled;
  bool? userEnableBlur;
  void applyReduceLag(final bool reduceLag) {
    if (reduceLag) {
      userVisualizerEnabled ??= settings.visualizerEnabledNotifier.value;
      userEnableBlur ??= settings.enableBlurNotifier.value;
      settings.visualizerEnabledNotifier.value = false;
      settings.enableBlurNotifier.value = false;
      caps.reduceLagOverride = true;
      try {
        if (SoLoud.instance.isInitialized) {
          SoLoud.instance.setVisualizationEnabled(false);
        }
      } catch (e) {
        AppLogger.w('main', 'reduce-lag visualization off failed', error: e);
      }
    } else {
      if (userVisualizerEnabled != null) {
        settings.visualizerEnabledNotifier.value = userVisualizerEnabled!;
      }
      if (userEnableBlur != null) {
        settings.enableBlurNotifier.value = userEnableBlur!;
      }
      userVisualizerEnabled = null;
      userEnableBlur = null;
      caps.reduceLagOverride = false;
      try {
        if (SoLoud.instance.isInitialized) {
          SoLoud.instance.setVisualizationEnabled(
            settings.visualizerEnabledNotifier.value,
          );
        }
      } catch (e) {
        AppLogger.w(
          'main',
          'reduce-lag visualization restore failed',
          error: e,
        );
      }
    }
    applyImageCacheConfig();
    if (reduceLag) {
      imageCache.clear();
    }
  }

  settings.reduceLagNotifier.addListener(
    () => applyReduceLag(settings.reduceLagNotifier.value),
  );
  applyReduceLag(settings.reduceLagNotifier.value);

  // Run migration first (critical for data integrity)
  final appDb = AppDatabase();
  final migrationService = MigrationService(appDb);

  // Use the wrapper to interact with Drift
  final dbService = DatabaseServiceWrapper(appDb);

  // DB init is deferred past the first frame for faster startup.
  // The library UI renders immediately and populates reactively via songsStream
  // once migration/seeding completes.
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    final dbSw = Stopwatch()..start();
    try {
      await migrationService.migrateFromSqflite();
      await dbService.init();
      AppLogger.i(
        'main',
        'deferred DB init + migration took '
            '${dbSw.elapsedMilliseconds}ms',
      );
    } catch (e, stack) {
      AppLogger.e(
        'main',
        'deferred database init failed',
        error: e,
        stack: stack,
      );
    }
  });

  // Create services with lazy initialization
  final engineService = AudioEngineService();
  final effectService = AudioEffectService();
  final playlistService = PlaylistService(
    engineService,
    effectService,
    dbService,
  );
  final coverArtRepo = CoverArtRepository();

  // ── Audio engine init is DEFERRED past first frame ─────────────────────────
  // On low-end Android (e.g. SM-J610F) `SoLoud.init()` + effect warmup +
  // `AudioService.init()` can take many seconds — and audio_service's
  // MediaBrowserServiceCompat connection can hang FOREVER on Samsung after a
  // force-stop. Awaiting them before `runApp()` leaves a blank screen with a
  // UI that never appears and playback that never starts.
  // Playback paths call `ensureWarmedUp()` (bounded timeout) before loading
  // audio, so the UI renders immediately and playback still works.

  // P4.2: Replace fixed 200ms delay with retry-on-failure logic.
  Future<void> tryApplyEq() async {
    for (int attempt = 0; attempt < 3; attempt++) {
      try {
        effectService.applyAllEqualizer(settings.eqBandsNotifier.value);
        return;
      } catch (e, stack) {
        AppLogger.e('main', 'EQ apply failed', error: e, stack: stack);
        if (attempt < 2) {
          await Future<void>.delayed(const Duration(milliseconds: 100));
        }
      }
    }
    AppLogger.w('main', 'EQ init failed after 3 retries');
  }

  // SoLoud init + audio-effect warmup, run off the critical first-frame path.
  // Failures are logged; playback will surface an error state instead of
  // blocking startup.
  Future<void> initAudioEngine() async {
    try {
      AppLogger.i('main', 'warming up audio engine (deferred)');
      await engineService.warmupAsync();

      await tryApplyEq();

      try {
        effectService.setBassLevel(settings.eqBassNotifier.value);
      } catch (e) {
        AppLogger.w('main', 'Bass init failed', error: e);
      }

      try {
        effectService.setCrossfadeDuration(
          settings.crossfadeDurationNotifier.value,
        );
        effectService.crossfadeCurveNotifier.value =
            settings.crossfadeCurveNotifier.value;
        effectService.setNormalizationLevel(
          settings.normalizationLevelNotifier.value,
        );
        effectService.enableNormalization(
          settings.normalizationEnabledNotifier.value,
        );
        effectService.setPitchShift(settings.pitchShiftNotifier.value);
        effectService.setReverbMix(settings.reverbMixNotifier.value);
        effectService.setCompressionRatio(
          settings.compressionRatioNotifier.value,
        );
      } catch (e) {
        AppLogger.w('main', 'audio effects init failed', error: e);
      }

      try {
        SoLoud.instance.setVisualizationEnabled(
          settings.visualizerEnabledNotifier.value,
        );
      } catch (e) {
        AppLogger.w('main', 'enable visualization failed', error: e);
      }

      AppLogger.i('main', 'audio engine warmup complete');
    } catch (e, st) {
      AppLogger.e('main', 'audio engine warmup failed', error: e, stack: st);
    }
  }

  // Defer audio engine init until after the first frame presents.
  WidgetsBinding.instance.addPostFrameCallback((_) {
    unawaited(initAudioEngine());
  });

  // Desktop services
  final windowManager = WindowManagerService(settingsManager: settings);
  final desktopLyricsService = DesktopLyricsService(settingsManager: settings);
  final hotkeyService = HotkeyService(
    settingsManager: settings,
    audioEngineService: engineService,
    playlistService: playlistService,
    onOpenSettingsSearch: () {
      navigatorKey.currentState?.push(
        MaterialPageRoute<void>(
          builder: (final context) => const SettingsSearchDialog(),
        ),
      );
    },
    onToggleMiniPlayer: () => windowManager.toggleMacMiniPlayerMode(),
  );
  final systemTrayService = SystemTrayService(
    audioEngineService: engineService,
    playlistService: playlistService,
  );
  final pipService = PipService.instance;

  // Initialize PiP + deep link handling on Android
  if (caps.isAndroid) {
    pipService.init();
  }
  // Track Power Saver to defer background work and adapt visualizer frame rate.
  if (caps.isAndroid || caps.isWindows) {
    PowerStateService.instance.start();
  }

  if (caps.isDesktop) {
    await windowManager.init();
    // Free decoded audio and image caches when hidden to tray.
    windowManager.onHiddenToTray = () {
      engineService.releaseMemoryWhenHidden();
      PaintingBinding.instance.imageCache.clear();
    };
    // Pause visualizer ticker while desktop window is minimized/hidden.
    windowManager.onWindowHiddenChanged = (hidden) {
      VisualizerController.setWindowHidden(hidden);
    };
    desktopLyricsService.init();
    if (Platform.isWindows) {
      final smtcService = SmtcService(engineService, playlistService);
      await smtcService.init();
    }
  }

  if (!kIsWeb &&
      (Platform.isAndroid ||
          Platform.isLinux ||
          Platform.isIOS ||
          Platform.isMacOS)) {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await Future.any([
          AudioService.init(
            builder: () => GaSongAudioHandler(engineService, playlistService),
            config: const AudioServiceConfig(
              androidNotificationChannelId:
                  'com.ghitatruongle.gasong.channel.audio',
              androidNotificationChannelName: 'GA Song Playback',
              androidNotificationOngoing: true,
              fastForwardInterval: Duration(seconds: 10),
              rewindInterval: Duration(seconds: 10),
            ),
          ),
          Future<void>.delayed(const Duration(seconds: 12)),
        ]);
        AppLogger.i('main', 'AudioService initialized');
      } catch (e, stack) {
        AppLogger.w(
          'main',
          'AudioService init failed or timed out '
              '(media notification unavailable)',
          error: e,
          stack: stack,
        );
      }
    });
  }

  // Defer PlatformService initialization (iOS/macOS/Web native features)
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    try {
      await PlatformService.instance.initialize();
    } catch (e, stack) {
      AppLogger.w(
        'main',
        'PlatformService init failed',
        error: e,
        stack: stack,
      );
    }
  });

  // macOS memory pressure → free image and decoded audio caches.
  if (Platform.isMacOS) {
    MacOSIntegration.onMemoryPressureHandler = (level) {
      PaintingBinding.instance.imageCache.clear();
      engineService.releaseMemoryWhenHidden();
      AppLogger.d('main', 'macOS memory pressure ($level): caches released');
    };
    // Dock badge: show track number while playing, clear when paused/stopped.
    engineService.engineState.addListener(() {
      final isPlaying =
          engineService.engineState.value == AudioEngineState.playing;
      final index = playlistService.currentIndex;
      MacOSIntegration.setDockBadge(isPlaying && index >= 0 ? index + 1 : null);
    });
    // Sleep timer expired → show macOS notification.
    playlistService.sleepTimerRemainingNotifier.addListener(() {
      final remaining = playlistService.sleepTimerRemainingNotifier.value;
      if (remaining == null) {
        PlatformService.instance.showNotification(
          title: 'Sleep Timer',
          body: 'Nhạc đã dừng theo hẹn giờ',
        );
      }
    });
  }

  // iOS Low Power Mode and memory warnings handling.
  if (Platform.isIOS) {
    IOSIntegration.onLowPowerModeChanged = (enabled) {
      AppLogger.d('main', 'iOS Low Power Mode: $enabled');
    };
    IOSIntegration.onMemoryWarning = () {
      PaintingBinding.instance.imageCache.clear();
      engineService.releaseMemoryWhenHidden();
      AppLogger.d('main', 'iOS memory warning: caches released');
    };
    // SceneDelegate lifecycle: resume/pause resources based on foreground state.
    const lifecycleChannel = MethodChannel('gasong/lifecycle');
    lifecycleChannel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'onAppResumed':
          AppLogger.d('main', 'iOS scene resumed');
        case 'onAppPaused':
          // Release non-essential caches when entering background.
          PaintingBinding.instance.imageCache.clear();
          engineService.releaseMemoryWhenHidden();
          AppLogger.d('main', 'iOS scene paused: caches released');
      }
    });
  }

  // P3.5: defer non-critical init until after first paint.
  // Future first-frame targets: lyrics DB warmup, smart playlist computation,
  // audio cache prefill, cover-art prime. Currently hosts desktop hotkey
  // registration and (release-only) system tray init — both are not required
  // for playback to start or for the splash to dismiss. Registered BEFORE
  // `runApp(...)` so it fires as soon as the first frame is presented.
  if (caps.isDesktop) {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await hotkeyService.init();
        if (!kDebugMode) await systemTrayService.init();

        // Initialize protocol handler for gasong:// URIs
        final protocolHandler = ProtocolHandlerService(
          databaseService: dbService,
          playlistService: playlistService,
          audioEngineService: engineService,
          settingsManager: settings,
        );
        await protocolHandler.init();

        // Initialize Jump List service on Windows
        if (Platform.isWindows) {
          final jumpListService = JumpListService();
          await jumpListService.init();
        }
      } catch (e, stack) {
        AppLogger.w(
          'main',
          'deferred desktop service init failed',
          error: e,
          stack: stack,
        );
      }
    });
  }

  // Android & iOS: initialize the gasong:// protocol handler post-frame too
  // (deep links arrive via app_links; playback itself never depends on it).
  if (caps.isAndroid || caps.isIOS) {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final protocolHandler = ProtocolHandlerService(
          databaseService: dbService,
          playlistService: playlistService,
          audioEngineService: engineService,
          settingsManager: settings,
        );
        await protocolHandler.init();
      } catch (e, stack) {
        AppLogger.w(
          'main',
          'deferred mobile protocol handler init failed',
          error: e,
          stack: stack,
        );
      }
    });
  }

  AppLogger.i(
    'main',
    'startup: pre-runApp init took ${startupStopwatch.elapsedMilliseconds}ms',
  );
  WidgetsBinding.instance.addPostFrameCallback((_) {
    AppLogger.i(
      'main',
      'first frame presented in ${startupStopwatch.elapsedMilliseconds}ms',
    );
  });

  runApp(
    ProviderScope(
      overrides: [
        databaseServiceProvider.overrideWithValue(dbService),
        audioEngineServiceProvider.overrideWithValue(engineService),
        audioEffectServiceProvider.overrideWithValue(effectService),
        playlistServiceProvider.overrideWithValue(playlistService),
        settingsManagerProvider.overrideWithValue(settings),
        coverArtRepositoryProvider.overrideWithValue(coverArtRepo),
        pipServiceProvider.overrideWithValue(pipService),
        hotkeyServiceProvider.overrideWithValue(hotkeyService),
        systemTrayServiceProvider.overrideWithValue(systemTrayService),
        windowManagerServiceProvider.overrideWithValue(windowManager),
        desktopLyricsServiceProvider.overrideWithValue(desktopLyricsService),
        smartShuffleServiceProvider.overrideWithValue(SmartShuffleService()),
        jumpListServiceProvider.overrideWithValue(JumpListService()),
        protocolHandlerServiceProvider.overrideWithValue(
          ProtocolHandlerService(
            databaseService: dbService,
            playlistService: playlistService,
            audioEngineService: engineService,
            settingsManager: settings,
          ),
        ),
      ],
      child: const GASongApp(),
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

  // Q-12 perf: ColorScheme.fromSeed (esp. the `fidelity` variant) is a very
  // expensive MCU palette computation — seconds on low-end devices
  // (SM-J610F). Memoize the ThemeData instances and recompute only when the
  // seed color or the native-window-effect flag actually changes; otherwise
  // every theme-listenable tick rebuilds MaterialApp and re-runs fromSeed.
  ThemeData? _cachedLightTheme;
  ThemeData? _cachedDarkTheme;
  Color? _cachedSeed;
  bool? _cachedUseNative;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsManagerProvider);
    _themeListenable = Listenable.merge([
      settings.themeModeNotifier,
      settings.localeNotifier,
      settings.useDynamicColorNotifier,
      settings.customPrimaryColorNotifier,
      settings.dynamicPrimaryColorNotifier,
      settings.useNativeWindowEffectNotifier,
    ]);

    // Initialize motion preferences from MediaQuery
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final motionPrefs = MotionPreferences.fromMediaQuery(
          MediaQuery.of(context),
        );
        ref
            .read(motionPreferencesNotifierProvider.notifier)
            .setReduceMotion(motionPrefs.reduceMotion);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Update motion preferences when MediaQuery changes (e.g., system setting
    // changes). Deferred so we don't modify the provider mid-build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final motionPrefs = MotionPreferences.fromMediaQuery(
        MediaQuery.of(context),
      );
      ref
          .read(motionPreferencesNotifierProvider.notifier)
          .setReduceMotion(motionPrefs.reduceMotion);
    });
  }

  @override
  Widget build(final BuildContext context) {
    final settings = ref.read(settingsManagerProvider);

    // Automatically update dynamic color when song changes
    ref.listen(currentSongDominantColorProvider, (final previous, final next) {
      if (next.hasValue && next.value != null) {
        settings.dynamicPrimaryColorNotifier.value = next.value;
      }
    });

    return AnimatedBuilder(
      animation: _themeListenable,
      builder: (final context, _) {
        final themeMode = settings.themeModeNotifier.value;
        final useDynamic = settings.useDynamicColorNotifier.value;
        final customColor = settings.customPrimaryColorNotifier.value;
        final dynamicColor = settings.dynamicPrimaryColorNotifier.value;
        final useNative = settings.useNativeWindowEffectNotifier.value;
        final primaryColor = useDynamic
            ? (dynamicColor ?? customColor)
            : customColor;

        if (primaryColor != _cachedSeed || useNative != _cachedUseNative) {
          _cachedSeed = primaryColor;
          _cachedUseNative = useNative;
          final themeSw = Stopwatch()..start();

          final isAndroid =
              !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
          // Android 8.1 has no Material You; `fidelity` only adds cost on
          // low-tier hardware — use the cheaper tonalSpot there.
          final lowTierAndroid =
              isAndroid &&
              PlatformCapabilities.instance.deviceTier == DeviceTier.low;
          final variant = (isAndroid && !lowTierAndroid)
              ? DynamicSchemeVariant.fidelity
              : DynamicSchemeVariant.tonalSpot;

          _cachedLightTheme = ThemeData(
            useMaterial3: true,
            brightness: Brightness.light,
            // Vietnamese glyph fallback (see pubspec fonts: NotoSans).
            fontFamilyFallback: const ['NotoSans'],
            colorScheme: ColorScheme.fromSeed(
              seedColor: primaryColor,
              dynamicSchemeVariant: variant,
            ).copyWith(surface: AppColors.lightSurface),
            scaffoldBackgroundColor: useNative
                ? Colors.transparent
                : AppColors.lightSurface2,
          );
          _cachedDarkTheme = ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            fontFamilyFallback: const ['NotoSans'],
            colorScheme: ColorScheme.fromSeed(
              seedColor: primaryColor,
              brightness: Brightness.dark,
              dynamicSchemeVariant: variant,
            ).copyWith(surface: AppColors.darkSurface2),
            scaffoldBackgroundColor: useNative
                ? Colors.transparent
                : AppColors.darkBackground,
          );
          AppLogger.i(
            'main',
            'theme rebuilt in ${themeSw.elapsedMilliseconds}ms '
                '(seed=${primaryColor.toARGB32().toRadixString(16)}, '
                'lowTier=$lowTierAndroid)',
          );
        }

        return MaterialApp(
          title: 'G.A - Song',
          debugShowCheckedModeBanner: false,
          locale: settings.localeNotifier.value,
          supportedLocales: const [Locale('vi'), Locale('en')],
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          themeMode: themeMode,
          theme: _cachedLightTheme!,
          darkTheme: _cachedDarkTheme!,
          builder: (final context, final child) {
            // Honor reduced-motion preference: disable all tickers
            // (animations, hero transitions, etc.) when the user has
            // requested reduced motion.
            if (MediaQuery.of(context).disableAnimations) {
              return TickerMode(
                enabled: false,
                child: child ?? const SizedBox.shrink(),
              );
            }
            // v0.8.0: AnimatedTheme cross-fade (600ms) for smooth light↔dark switching.
            return AnimatedTheme(
              data: Theme.of(context),
              duration: AppDurations.extended,
              curve: AppCurves.emphasized,
              child: Shortcuts(
                shortcuts: <LogicalKeySet, Intent>{
                  LogicalKeySet(
                    LogicalKeyboardKey.control,
                    LogicalKeyboardKey.keyK,
                  ): const _OpenSettingsSearchIntent(),
                },
                child: Actions(
                  actions: <Type, Action<Intent>>{
                    _OpenSettingsSearchIntent:
                        CallbackAction<_OpenSettingsSearchIntent>(
                          onInvoke: (_) => SettingsSearchDialog.show(context),
                        ),
                  },
                  child: FrameBudgetOverlayWrapper(
                    child: child ?? const SizedBox.shrink(),
                  ),
                ),
              ),
            );
          },
          home: MacOSMenuBar(child: widget.home),
        );
      },
    );
  }
}
