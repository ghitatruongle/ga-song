import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:ga_song/core/settings_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SettingsManager Tests', () {
    late SettingsManager settingsManager;

    setUp(() async {
      // Keys must match the actual keys used in SettingsManager.init()
      SharedPreferences.setMockInitialValues({
        'themeMode': 'dark',                  // String, not int
        'useDynamicColor': true,
        'useNativeWindowEffect': true,
        'windowOpacity': 0.8,
      });

      settingsManager = SettingsManager();
      await settingsManager.init();
    });

    test('Loads initial values correctly from SharedPreferences', () {
      expect(settingsManager.themeModeNotifier.value, ThemeMode.dark);
      expect(settingsManager.useDynamicColorNotifier.value, isTrue);
      expect(settingsManager.useNativeWindowEffectNotifier.value, isTrue);
    });

    test('Updates theme mode and saves to SharedPreferences', () async {
      await settingsManager.setThemeMode(ThemeMode.light);
      expect(settingsManager.themeModeNotifier.value, ThemeMode.light);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('themeMode'), 'light');
    });

    test('Updates window opacity correctly', () async {
      await settingsManager.setWindowOpacity(0.5);
      expect(settingsManager.windowOpacityNotifier.value, 0.5);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getDouble('windowOpacity'), 0.5);
    });
  });
}
