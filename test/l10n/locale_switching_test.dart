import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ga_song/core/settings_manager.dart';
import 'package:ga_song/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('AppLocalizationsDelegate', () {
    const delegate = AppLocalizationsDelegate();

    test('supports vi and en only', () {
      expect(delegate.isSupported(const Locale('vi')), isTrue);
      expect(delegate.isSupported(const Locale('en')), isTrue);
      expect(delegate.isSupported(const Locale('fr')), isFalse);
    });

    test('load returns localized strings for each locale', () async {
      final vi = await delegate.load(const Locale('vi'));
      final en = await delegate.load(const Locale('en'));
      expect(vi.library, 'Thư viện');
      expect(en.library, 'Library');
    });
  });

  group('MaterialApp locale wiring', () {
    Widget buildApp(Locale locale, void Function(BuildContext) onBuild) {
      return MaterialApp(
        locale: locale,
        supportedLocales: const [Locale('vi'), Locale('en')],
        localizationsDelegates: const [
          AppLocalizationsDelegate(),
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Builder(
          builder: (context) {
            onBuild(context);
            return const SizedBox();
          },
        ),
      );
    }

    testWidgets('AppLocalizations.of resolves English under en locale', (
      tester,
    ) async {
      late AppLocalizations l10n;
      await tester.pumpWidget(
        buildApp(const Locale('en'), (c) => l10n = AppLocalizations.of(c)),
      );
      await tester.pumpAndSettle();
      expect(l10n.locale.languageCode, 'en');
      expect(l10n.home, 'Home');
    });

    testWidgets('AppLocalizations.of resolves Vietnamese under vi locale', (
      tester,
    ) async {
      late AppLocalizations l10n;
      await tester.pumpWidget(
        buildApp(const Locale('vi'), (c) => l10n = AppLocalizations.of(c)),
      );
      await tester.pumpAndSettle();
      expect(l10n.locale.languageCode, 'vi');
      expect(l10n.home, 'Trang chủ');
    });
  });

  group('SettingsManager locale persistence', () {
    test('defaults to vi when nothing is persisted', () async {
      SharedPreferences.setMockInitialValues({});
      final settings = SettingsManager();
      await settings.init();
      expect(settings.localeNotifier.value.languageCode, 'vi');
    });

    test('loads persisted locale on init', () async {
      SharedPreferences.setMockInitialValues({'localeCode': 'en'});
      final settings = SettingsManager();
      await settings.init();
      expect(settings.localeNotifier.value.languageCode, 'en');
    });

    test('ignores unsupported persisted locale codes', () async {
      SharedPreferences.setMockInitialValues({'localeCode': 'fr'});
      final settings = SettingsManager();
      await settings.init();
      expect(settings.localeNotifier.value.languageCode, 'vi');
    });

    test('setLocale updates the notifier and persists the code', () async {
      SharedPreferences.setMockInitialValues({});
      final settings = SettingsManager();
      await settings.init();

      await settings.setLocale(const Locale('en'));

      expect(settings.localeNotifier.value.languageCode, 'en');
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('localeCode'), 'en');
    });
  });
}
