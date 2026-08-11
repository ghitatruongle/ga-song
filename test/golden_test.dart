/// Golden Test Suite for G.A - Song
///
/// Tests visual regression across themes, locales, and screen sizes.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ga_song/l10n/app_localizations.dart';
import 'package:ga_song/ui/screens/home_screen.dart';
import 'package:ga_song/ui/widgets/sidebar.dart';
import 'test_helpers.dart';
import 'mocks/mock_settings_manager.dart';
import 'package:ga_song/ui/screens/now_playing_screen.dart';
import 'package:ga_song/ui/screens/mini_player_screen.dart';
import 'package:ga_song/ui/screens/lyrics_editor_screen.dart';
import 'package:ga_song/ui/screens/theme_builder_screen.dart';
import 'package:ga_song/ui/widgets/settings_search_dialog.dart';

void main() {
  // Pin the sidebar greeting clock to the morning so HomeScreen goldens
  // are deterministic regardless of when the tests run (UTC hour changes).
  greetingClock = () => DateTime(2026, 6, 1, 9);

  group('Golden Tests - Visual Regression', () {
    late MockServices mockServices;

    setUp(() async {
      mockServices = MockServices();
      await mockServices.initAll();
    });

    tearDown(() {
      mockServices.disposeAll();
    });

    group('HomeScreen', () {
      testGoldens('HomeScreen - Light Theme - Vietnamese', (
        final WidgetTester tester,
      ) async {
        await _testScreen(
          tester,
          'home_screen_light_vi',
          themeMode: ThemeMode.light,
          locale: const Locale('vi'),
        );
      });

      testGoldens('HomeScreen - Dark Theme - Vietnamese', (
        final WidgetTester tester,
      ) async {
        await _testScreen(
          tester,
          'home_screen_dark_vi',
          themeMode: ThemeMode.dark,
          locale: const Locale('vi'),
        );
      });

      testGoldens('HomeScreen - Light Theme - English', (
        final WidgetTester tester,
      ) async {
        await _testScreen(
          tester,
          'home_screen_light_en',
          themeMode: ThemeMode.light,
          locale: const Locale('en'),
        );
      });

      testGoldens('HomeScreen - Dark Theme - English', (
        final WidgetTester tester,
      ) async {
        await _testScreen(
          tester,
          'home_screen_dark_en',
          themeMode: ThemeMode.dark,
          locale: const Locale('en'),
        );
      });

      testGoldens('HomeScreen - Mobile Size - Light Theme', (
        final WidgetTester tester,
      ) async {
        await _testScreen(
          tester,
          'home_screen_mobile_light',
          themeMode: ThemeMode.light,
          locale: const Locale('vi'),
          size: const Size(375, 667), // iPhone SE
        );
      });

      testGoldens('HomeScreen - Tablet Size - Light Theme', (
        final WidgetTester tester,
      ) async {
        await _testScreen(
          tester,
          'home_screen_tablet_light',
          themeMode: ThemeMode.light,
          locale: const Locale('vi'),
          size: const Size(768, 1024), // iPad
        );
      });

      testGoldens('HomeScreen - Desktop Size - Light Theme', (
        final WidgetTester tester,
      ) async {
        await _testScreen(
          tester,
          'home_screen_desktop_light',
          themeMode: ThemeMode.light,
          locale: const Locale('vi'),
          size: const Size(1200, 800),
        );
      });

      testGoldens('HomeScreen - Reduced Motion', (
        final WidgetTester tester,
      ) async {
        await _testScreen(
          tester,
          'home_screen_reduced_motion',
          themeMode: ThemeMode.light,
          locale: const Locale('vi'),
          disableAnimations: true,
        );
      });
    });

    group('NowPlayingScreen', () {
      testGoldens('NowPlayingScreen - Light Theme', (
        final WidgetTester tester,
      ) async {
        await _testScreen(
          tester,
          'now_playing_light',
          themeMode: ThemeMode.light,
          locale: const Locale('vi'),
          screen: const NowPlayingScreen(),
        );
      });

      testGoldens('NowPlayingScreen - Dark Theme', (
        final WidgetTester tester,
      ) async {
        await _testScreen(
          tester,
          'now_playing_dark',
          themeMode: ThemeMode.dark,
          locale: const Locale('vi'),
          screen: const NowPlayingScreen(),
        );
      });
    });

    group('MiniPlayerScreen', () {
      testGoldens('MiniPlayerScreen - Light Theme', (
        final WidgetTester tester,
      ) async {
        await _testScreen(
          tester,
          'mini_player_light',
          themeMode: ThemeMode.light,
          locale: const Locale('vi'),
          screen: const MiniPlayerScreen(),
        );
      });

      testGoldens('MiniPlayerScreen - Dark Theme', (
        final WidgetTester tester,
      ) async {
        await _testScreen(
          tester,
          'mini_player_dark',
          themeMode: ThemeMode.dark,
          locale: const Locale('vi'),
          screen: const MiniPlayerScreen(),
        );
      });
    });

    group('LyricsEditorScreen', () {
      testGoldens('LyricsEditorScreen - Light Theme', (
        final WidgetTester tester,
      ) async {
        await _testScreen(
          tester,
          'lyrics_editor_light',
          themeMode: ThemeMode.light,
          locale: const Locale('vi'),
          screen: const LyricsEditorScreen(),
        );
      });

      testGoldens('LyricsEditorScreen - Dark Theme', (
        final WidgetTester tester,
      ) async {
        await _testScreen(
          tester,
          'lyrics_editor_dark',
          themeMode: ThemeMode.dark,
          locale: const Locale('vi'),
          screen: const LyricsEditorScreen(),
        );
      });
    });

    group('ThemeBuilderScreen', () {
      testGoldens('ThemeBuilderScreen - Light Theme', (
        final WidgetTester tester,
      ) async {
        await _testScreen(
          tester,
          'theme_builder_light',
          themeMode: ThemeMode.light,
          locale: const Locale('vi'),
          screen: const ThemeBuilderScreen(),
        );
      });

      testGoldens('ThemeBuilderScreen - Dark Theme', (
        final WidgetTester tester,
      ) async {
        await _testScreen(
          tester,
          'theme_builder_dark',
          themeMode: ThemeMode.dark,
          locale: const Locale('vi'),
          screen: const ThemeBuilderScreen(),
        );
      });
    });

    group('SettingsSearchDialog', () {
      testGoldens('SettingsSearchDialog - Light Theme', (
        final WidgetTester tester,
      ) async {
        await _testDialog(
          tester,
          'settings_search_light',
          themeMode: ThemeMode.light,
          locale: const Locale('vi'),
        );
      });

      testGoldens('SettingsSearchDialog - Dark Theme', (
        final WidgetTester tester,
      ) async {
        await _testDialog(
          tester,
          'settings_search_dark',
          themeMode: ThemeMode.dark,
          locale: const Locale('en'),
        );
      });
    });

    group('QueueManagementSheet', () {
      testGoldens('QueueManagementSheet - Light Theme', (
        final WidgetTester tester,
      ) async {
        await _testDialog(
          tester,
          'queue_management_light',
          themeMode: ThemeMode.light,
          locale: const Locale('vi'),
        );
      });

      testGoldens('QueueManagementSheet - Dark Theme', (
        final WidgetTester tester,
      ) async {
        await _testDialog(
          tester,
          'queue_management_dark',
          themeMode: ThemeMode.dark,
          locale: const Locale('en'),
        );
      });
    });

    group('QueueManagementSheet - Multi Select', () {
      testGoldens('QueueManagementSheet - Multi Select Light', (
        final WidgetTester tester,
      ) async {
        await _testDialog(
          tester,
          'queue_management_multiselect_light',
          themeMode: ThemeMode.light,
          locale: const Locale('vi'),
        );
      });
    });
  });
}

Future<void> _testScreen(
  final WidgetTester tester,
  final String name, {
  required final ThemeMode themeMode,
  required final Locale locale,
  final Widget? screen,
  final Size size = const Size(1000, 700),
  final bool disableAnimations = false,
}) async {
  final settings = MockSettingsManager();
  await settings.init();
  settings.themeModeNotifier.value = themeMode;
  settings.localeNotifier.value = locale;

  final mockServices = MockServices(settings: settings);
  await mockServices.initAll();

  await tester.pumpWidgetBuilder(
    screen ?? const HomeScreen(),
    surfaceSize: size,
    wrapper: (final widget) => MaterialApp(
      locale: locale,
      supportedLocales: const [Locale('vi'), Locale('en')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: MediaQuery(
        data:
            MediaQueryData.fromView(
              TestWidgetsFlutterBinding.instance.platformDispatcher.views.first,
            ).copyWith(
              size: size,
              platformBrightness: themeMode == ThemeMode.dark
                  ? Brightness.dark
                  : Brightness.light,
            ),
        child: ProviderScope(overrides: mockServices.overrides, child: widget),
      ),
    ),
  );

  await tester.pump(const Duration(milliseconds: 300));

  await screenMatchesGolden(tester, name);
}

Future<void> _testDialog(
  final WidgetTester tester,
  final String name, {
  required final ThemeMode themeMode,
  required final Locale locale,
}) async {
  final settings = MockSettingsManager();
  await settings.init();
  settings.themeModeNotifier.value = themeMode;
  settings.localeNotifier.value = locale;

  final mockServices = MockServices(settings: settings);
  await mockServices.initAll();

  await tester.pumpWidgetBuilder(
    const Dialog(
      child: SizedBox(width: 600, height: 600, child: SettingsSearchDialog()),
    ),
    surfaceSize: const Size(1000, 700),
    wrapper: (final widget) => MaterialApp(
      locale: locale,
      supportedLocales: const [Locale('vi'), Locale('en')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: MediaQuery(
        data:
            MediaQueryData.fromView(
              TestWidgetsFlutterBinding.instance.platformDispatcher.views.first,
            ).copyWith(
              size: const Size(1000, 700),
              platformBrightness: themeMode == ThemeMode.dark
                  ? Brightness.dark
                  : Brightness.light,
            ),
        child: ProviderScope(overrides: mockServices.overrides, child: widget),
      ),
    ),
  );

  await tester.pumpAndSettle(const Duration(seconds: 3));

  await screenMatchesGolden(tester, name);
}
