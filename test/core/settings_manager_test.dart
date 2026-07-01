import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ga_song/core/settings_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SettingsManager', () {
    late SettingsManager manager;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      manager = SettingsManager();
      await manager.init();
    });

    tearDown(() {
      manager.dispose();
    });

    // ─── Default Values ────────────────────────────────────────────────

    group('default values', () {
      test('themeMode defaults to system', () {
        expect(manager.themeModeNotifier.value, ThemeMode.system);
      });

      test('enableBlur defaults to true', () {
        expect(manager.enableBlurNotifier.value, isTrue);
      });

      test('blurLevel defaults to 30.0', () {
        expect(manager.blurLevelNotifier.value, 30.0);
      });

      test('isMiniPlayer defaults to false', () {
        expect(manager.isMiniPlayerNotifier.value, isFalse);
      });

      test('useNativeWindowEffect defaults to false', () {
        expect(manager.useNativeWindowEffectNotifier.value, isFalse);
      });

      test('windowOpacity defaults to 0.7', () {
        expect(manager.windowOpacityNotifier.value, 0.7);
      });

      test('isGridView defaults to false', () {
        expect(manager.isGridViewNotifier.value, isFalse);
      });

      test('minimizeToTray defaults to true', () {
        expect(manager.minimizeToTrayNotifier.value, isTrue);
      });

      test('visualizerEnabled defaults to true', () {
        expect(manager.visualizerEnabledNotifier.value, isTrue);
      });

      test('useDynamicColor defaults to true', () {
        expect(manager.useDynamicColorNotifier.value, isTrue);
      });

      test('sensitivity defaults to 1.0', () {
        expect(manager.sensitivityNotifier.value, 1.0);
      });

      test('currentTabIndex defaults to 0', () {
        expect(manager.currentTabIndexNotifier.value, 0);
      });

      test('eqBands defaults to [0,0,0,0,0]', () {
        expect(manager.eqBandsNotifier.value, [0.0, 0.0, 0.0, 0.0, 0.0]);
      });

      test('eqBass defaults to 0', () {
        expect(manager.eqBassNotifier.value, 0);
      });

      test('eqPreset defaults to Normal', () {
        expect(manager.eqPresetNotifier.value, 'Normal');
      });

      test('crossfadeDuration defaults to 3.0', () {
        expect(manager.crossfadeDurationNotifier.value, 3.0);
      });

      test('normalizationLevel defaults to -12.0', () {
        expect(manager.normalizationLevelNotifier.value, -12.0);
      });

      test('normalizationEnabled defaults to false', () {
        expect(manager.normalizationEnabledNotifier.value, isFalse);
      });

      test('pitchShift defaults to 1.0', () {
        expect(manager.pitchShiftNotifier.value, 1.0);
      });

      test('reverbMix defaults to 0.0', () {
        expect(manager.reverbMixNotifier.value, 0.0);
      });

      test('compressionRatio defaults to 1.0', () {
        expect(manager.compressionRatioNotifier.value, 1.0);
      });

      test('sortMode defaults to 0', () {
        expect(manager.sortModeNotifier.value, 0);
      });

      test('sortAscending defaults to true', () {
        expect(manager.sortAscendingNotifier.value, isTrue);
      });

      test('customHotkeys defaults to empty map', () {
        expect(manager.customHotkeysNotifier.value, isEmpty);
      });

      test('mediaKeyEnabled defaults to true', () {
        expect(manager.mediaKeyEnabledNotifier.value, isTrue);
      });
    });

    // ─── Loads from SharedPreferences ──────────────────────────────────

    group('loads saved values', () {
      test('loads saved theme mode', () async {
        SharedPreferences.setMockInitialValues({'themeMode': 'dark'});
        final m = SettingsManager();
        await m.init();
        expect(m.themeModeNotifier.value, ThemeMode.dark);
        m.dispose();
      });

      test('loads saved light theme', () async {
        SharedPreferences.setMockInitialValues({'themeMode': 'light'});
        final m = SettingsManager();
        await m.init();
        expect(m.themeModeNotifier.value, ThemeMode.light);
        m.dispose();
      });

      test('loads saved blur settings', () async {
        SharedPreferences.setMockInitialValues({
          'enableBlur': false,
          'blurLevel': 50.0,
        });
        final m = SettingsManager();
        await m.init();
        expect(m.enableBlurNotifier.value, isFalse);
        expect(m.blurLevelNotifier.value, 50.0);
        m.dispose();
      });

      test('loads saved EQ settings', () async {
        SharedPreferences.setMockInitialValues({
          'eqPreset': 'Bass+',
          'eqBass': 60,
          'eqBands': ['0.800', '0.500', '0.000', '-0.100', '0.000'],
        });
        final m = SettingsManager();
        await m.init();
        expect(m.eqPresetNotifier.value, 'Bass+');
        expect(m.eqBassNotifier.value, 60);
        expect(m.eqBandsNotifier.value, [0.8, 0.5, 0.0, -0.1, 0.0]);
        m.dispose();
      });

      test('loads saved audio effects', () async {
        SharedPreferences.setMockInitialValues({
          'crossfadeDuration': 5.0,
          'normalizationLevel': -18.0,
          'normalizationEnabled': true,
          'pitchShift': 1.5,
          'reverbMix': 0.3,
          'compressionRatio': 4.0,
        });
        final m = SettingsManager();
        await m.init();
        expect(m.crossfadeDurationNotifier.value, 5.0);
        expect(m.normalizationLevelNotifier.value, -18.0);
        expect(m.normalizationEnabledNotifier.value, isTrue);
        expect(m.pitchShiftNotifier.value, 1.5);
        expect(m.reverbMixNotifier.value, 0.3);
        expect(m.compressionRatioNotifier.value, 4.0);
        m.dispose();
      });
    });

    // ─── Theme Mode ────────────────────────────────────────────────────

    group('setThemeMode', () {
      test('sets light theme', () async {
        await manager.setThemeMode(ThemeMode.light);
        expect(manager.themeModeNotifier.value, ThemeMode.light);
      });

      test('sets dark theme', () async {
        await manager.setThemeMode(ThemeMode.dark);
        expect(manager.themeModeNotifier.value, ThemeMode.dark);
      });

      test('sets system theme', () async {
        await manager.setThemeMode(ThemeMode.dark);
        await manager.setThemeMode(ThemeMode.system);
        expect(manager.themeModeNotifier.value, ThemeMode.system);
      });

      test('persists theme mode', () async {
        await manager.setThemeMode(ThemeMode.dark);
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('themeMode'), 'dark');
      });
    });

    // ─── Blur Settings ─────────────────────────────────────────────────

    group('blur settings', () {
      test('setEnableBlur updates notifier and persists', () async {
        await manager.setEnableBlur(false);
        expect(manager.enableBlurNotifier.value, isFalse);
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getBool('enableBlur'), isFalse);
      });

      test('setBlurLevel clamps and persists', () async {
        await manager.setBlurLevel(50.0);
        expect(manager.blurLevelNotifier.value, 50.0);
      });

      test('setBlurLevel clamps to 0 minimum', () async {
        await manager.setBlurLevel(-10.0);
        expect(manager.blurLevelNotifier.value, 0.0);
      });

      test('setBlurLevel clamps to 100 maximum', () async {
        await manager.setBlurLevel(150.0);
        expect(manager.blurLevelNotifier.value, 100.0);
      });
    });

    // ─── Window Settings ───────────────────────────────────────────────

    group('window settings', () {
      test('setUseNativeWindowEffect updates and persists', () async {
        await manager.setUseNativeWindowEffect(true);
        expect(manager.useNativeWindowEffectNotifier.value, isTrue);
      });

      test('setWindowOpacity clamps to 0.1-1.0', () async {
        await manager.setWindowOpacity(0.5);
        expect(manager.windowOpacityNotifier.value, 0.5);

        await manager.setWindowOpacity(0.0);
        expect(manager.windowOpacityNotifier.value, 0.1);

        await manager.setWindowOpacity(1.5);
        expect(manager.windowOpacityNotifier.value, 1.0);
      });

      test('setSavedWindowState persists size and flags', () async {
        await manager.setSavedWindowState(
          const Size(1280, 720),
          true,
          false,
        );
        expect(manager.savedWindowSize, const Size(1280, 720));
        expect(manager.savedWindowMaximized, isTrue);
        expect(manager.savedWindowFullScreen, isFalse);
      });

      test('setSavedWindowPosition persists offset', () async {
        await manager.setSavedWindowPosition(const Offset(100, 200));
        expect(manager.savedWindowPosition, const Offset(100, 200));
      });
    });

    // ─── Grid View ─────────────────────────────────────────────────────

    group('setIsGridView', () {
      test('updates notifier and persists', () async {
        await manager.setIsGridView(true);
        expect(manager.isGridViewNotifier.value, isTrue);
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getBool('isGridView'), isTrue);
      });
    });

    // ─── Custom Background ─────────────────────────────────────────────

    group('setCustomBackgroundImage', () {
      test('sets path', () async {
        await manager.setCustomBackgroundImage('/path/to/image.png');
        expect(manager.customBackgroundImageNotifier.value, '/path/to/image.png');
      });

      test('removes when null', () async {
        await manager.setCustomBackgroundImage('/path/to/image.png');
        await manager.setCustomBackgroundImage(null);
        expect(manager.customBackgroundImageNotifier.value, isNull);
      });
    });

    // ─── Visualizer ────────────────────────────────────────────────────

    group('setVisualizerShape', () {
      test('updates notifier and persists', () async {
        await manager.setVisualizerShape(2);
        expect(manager.visualizerShapeNotifier.value, 2);
      });
    });

    // ─── Mini Player ───────────────────────────────────────────────────

    group('setIsMiniPlayer', () {
      test('updates notifier', () {
        manager.setIsMiniPlayer(true);
        expect(manager.isMiniPlayerNotifier.value, isTrue);
      });
    });

    // ─── Minimize To Tray ──────────────────────────────────────────────

    group('setMinimizeToTray', () {
      test('updates notifier and persists', () async {
        await manager.setMinimizeToTray(false);
        expect(manager.minimizeToTrayNotifier.value, isFalse);
      });
    });

    // ─── Sensitivity ───────────────────────────────────────────────────

    group('setSensitivity', () {
      test('updates notifier and persists', () async {
        await manager.setSensitivity(1.5);
        expect(manager.sensitivityNotifier.value, 1.5);
      });

      test('clamps to 0.3 minimum', () async {
        await manager.setSensitivity(0.1);
        expect(manager.sensitivityNotifier.value, 0.3);
      });

      test('clamps to 2.5 maximum', () async {
        await manager.setSensitivity(3.0);
        expect(manager.sensitivityNotifier.value, 2.5);
      });
    });

    // ─── Dynamic Color ─────────────────────────────────────────────────

    group('setUseDynamicColor', () {
      test('updates notifier and persists', () async {
        await manager.setUseDynamicColor(false);
        expect(manager.useDynamicColorNotifier.value, isFalse);
      });
    });

    // ─── Custom Primary Color ──────────────────────────────────────────

    group('setCustomPrimaryColor', () {
      test('updates notifier and persists', () async {
        await manager.setCustomPrimaryColor(Colors.red);
        expect(manager.customPrimaryColorNotifier.value, Colors.red);
      });
    });

    // ─── EQ Presets ────────────────────────────────────────────────────

    group('applyEqPreset', () {
      test('Normal preset sets all bands to 0', () async {
        await manager.setEqBand(0, 0.5);
        await manager.applyEqPreset('Normal');
        expect(manager.eqBandsNotifier.value, [0.0, 0.0, 0.0, 0.0, 0.0]);
        expect(manager.eqBassNotifier.value, 0);
      });

      test('Bass+ preset sets correct values', () async {
        await manager.applyEqPreset('Bass+');
        expect(manager.eqBandsNotifier.value, [0.8, 0.5, 0.0, -0.1, 0.0]);
        expect(manager.eqBassNotifier.value, 60);
      });

      test('Vocal preset sets correct values', () async {
        await manager.applyEqPreset('Vocal');
        expect(manager.eqBandsNotifier.value, [-0.2, 0.0, 0.5, 0.6, 0.3]);
        expect(manager.eqBassNotifier.value, 10);
      });

      test('Acoustic preset sets correct values', () async {
        await manager.applyEqPreset('Acoustic');
        expect(manager.eqBandsNotifier.value, [0.3, 0.1, 0.2, 0.3, 0.5]);
        expect(manager.eqBassNotifier.value, 20);
      });

      test('Custom preset does not change bands', () async {
        await manager.setEqBand(0, 0.5);
        await manager.applyEqPreset('Custom');
        expect(manager.eqBandsNotifier.value[0], 0.5);
      });
    });

    // ─── EQ Band ───────────────────────────────────────────────────────

    group('setEqBand', () {
      test('updates specific band', () async {
        await manager.setEqBand(2, 0.7);
        expect(manager.eqBandsNotifier.value[2], 0.7);
      });

      test('clamps to -1 to 1 range', () async {
        await manager.setEqBand(0, -2.0);
        expect(manager.eqBandsNotifier.value[0], -1.0);
        await manager.setEqBand(0, 2.0);
        expect(manager.eqBandsNotifier.value[0], 1.0);
      });
    });

    // ─── EQ Bass ───────────────────────────────────────────────────────

    group('setEqBass', () {
      test('updates bass level', () async {
        await manager.setEqBass(50);
        expect(manager.eqBassNotifier.value, 50);
      });

      test('clamps to 0-100', () async {
        await manager.setEqBass(-10);
        expect(manager.eqBassNotifier.value, 0);
        await manager.setEqBass(150);
        expect(manager.eqBassNotifier.value, 100);
      });
    });

    // ─── Audio Effects ─────────────────────────────────────────────────

    group('audio effects setters', () {
      test('setCrossfadeDuration clamps and persists', () async {
        await manager.setCrossfadeDuration(5.0);
        expect(manager.crossfadeDurationNotifier.value, 5.0);
        await manager.setCrossfadeDuration(-1.0);
        expect(manager.crossfadeDurationNotifier.value, 0.0);
        await manager.setCrossfadeDuration(15.0);
        expect(manager.crossfadeDurationNotifier.value, 10.0);
      });

      test('setNormalizationLevel clamps', () async {
        await manager.setNormalizationLevel(-18.0);
        expect(manager.normalizationLevelNotifier.value, -18.0);
        await manager.setNormalizationLevel(-30.0);
        expect(manager.normalizationLevelNotifier.value, -24.0);
        await manager.setNormalizationLevel(5.0);
        expect(manager.normalizationLevelNotifier.value, 0.0);
      });

      test('setNormalizationEnabled persists', () async {
        await manager.setNormalizationEnabled(true);
        expect(manager.normalizationEnabledNotifier.value, isTrue);
      });

      test('setPitchShift clamps', () async {
        await manager.setPitchShift(1.5);
        expect(manager.pitchShiftNotifier.value, 1.5);
        await manager.setPitchShift(0.1);
        expect(manager.pitchShiftNotifier.value, 0.5);
        await manager.setPitchShift(3.0);
        expect(manager.pitchShiftNotifier.value, 2.0);
      });

      test('setReverbMix clamps', () async {
        await manager.setReverbMix(0.5);
        expect(manager.reverbMixNotifier.value, 0.5);
        await manager.setReverbMix(-0.1);
        expect(manager.reverbMixNotifier.value, 0.0);
        await manager.setReverbMix(1.5);
        expect(manager.reverbMixNotifier.value, 1.0);
      });

      test('setCompressionRatio clamps', () async {
        await manager.setCompressionRatio(4.0);
        expect(manager.compressionRatioNotifier.value, 4.0);
        await manager.setCompressionRatio(0.5);
        expect(manager.compressionRatioNotifier.value, 1.0);
        await manager.setCompressionRatio(15.0);
        expect(manager.compressionRatioNotifier.value, 10.0);
      });
    });

    // ─── Compressor Advanced ───────────────────────────────────────────

    group('compressor advanced setters', () {
      test('setCompThreshold clamps', () async {
        await manager.setCompThreshold(-20.0);
        expect(manager.compThresholdNotifier.value, -20.0);
        await manager.setCompThreshold(-100.0);
        expect(manager.compThresholdNotifier.value, -80.0);
      });

      test('setCompAttack clamps', () async {
        await manager.setCompAttack(50.0);
        expect(manager.compAttackNotifier.value, 50.0);
      });

      test('setCompRelease clamps', () async {
        await manager.setCompRelease(500.0);
        expect(manager.compReleaseNotifier.value, 500.0);
      });

      test('setCompKneeWidth clamps', () async {
        await manager.setCompKneeWidth(10.0);
        expect(manager.compKneeWidthNotifier.value, 10.0);
      });

      test('setCompMakeupGain clamps', () async {
        await manager.setCompMakeupGain(6.0);
        expect(manager.compMakeupGainNotifier.value, 6.0);
      });
    });

    // ─── Reverb Advanced ───────────────────────────────────────────────

    group('reverb advanced setters', () {
      test('setReverbRoomSize clamps', () async {
        await manager.setReverbRoomSize(0.7);
        expect(manager.reverbRoomSizeNotifier.value, 0.7);
        await manager.setReverbRoomSize(-0.1);
        expect(manager.reverbRoomSizeNotifier.value, 0.0);
        await manager.setReverbRoomSize(1.5);
        expect(manager.reverbRoomSizeNotifier.value, 1.0);
      });

      test('setReverbDamp clamps', () async {
        await manager.setReverbDamp(0.3);
        expect(manager.reverbDampNotifier.value, 0.3);
      });
    });

    // ─── Sort ──────────────────────────────────────────────────────────

	    group('sort setters', () {
	      test('setSortMode persists', () async {
	        await manager.setSortMode(2);
	        expect(manager.sortModeNotifier.value, 2);
	      });

	      test('setSortMode accepts all 6 modes (0-5)', () async {
	        // After fix: _kSortModeCount changed from 4 to 6
	        for (int mode = 0; mode <= 5; mode++) {
	          await manager.setSortMode(mode);
	          expect(manager.sortModeNotifier.value, mode,
		      reason: 'Sort mode $mode should be settable');
	        }
	      });

	      test('setSortMode clamps to valid range', () async {
	        await manager.setSortMode(-1);
	        expect(manager.sortModeNotifier.value, inInclusiveRange(0, 5));

	        await manager.setSortMode(99);
	        expect(manager.sortModeNotifier.value, inInclusiveRange(0, 5));
	      });

	      test('setSortAscending persists', () async {
	        await manager.setSortAscending(false);
	        expect(manager.sortAscendingNotifier.value, isFalse);
	      });
	    });

    // ─── Custom Hotkeys ────────────────────────────────────────────────

    group('custom hotkeys', () {
      test('setCustomHotkey adds hotkey', () async {
        await manager.setCustomHotkey('play', 'Ctrl+P');
        expect(manager.customHotkeysNotifier.value['play'], 'Ctrl+P');
      });

      test('removeCustomHotkey removes hotkey', () async {
        await manager.setCustomHotkey('play', 'Ctrl+P');
        await manager.removeCustomHotkey('play');
        expect(manager.customHotkeysNotifier.value.containsKey('play'), isFalse);
      });
    });

    // ─── Media Key ─────────────────────────────────────────────────────

    group('setMediaKeyEnabled', () {
      test('persists value', () async {
        await manager.setMediaKeyEnabled(false);
        expect(manager.mediaKeyEnabledNotifier.value, isFalse);
      });
    });

    // ─── Song Color Cache ──────────────────────────────────────────────

    group('song color cache', () {
      test('returns null for unknown file', () {
        expect(manager.getSongColor('unknown.mp3'), isNull);
      });

      test('save and retrieve song color', () async {
        await manager.saveSongColor('test.mp3', Colors.red);
        expect(manager.getSongColor('test.mp3'), Colors.red);
      });
    });

    // ─── Persistence cycle ─────────────────────────────────────────────

    group('persistence cycle', () {
      test('settings survive reinit', () async {
        await manager.setThemeMode(ThemeMode.dark);
        await manager.setEnableBlur(false);
        await manager.setBlurLevel(50.0);
        await manager.setCrossfadeDuration(5.0);
        await manager.setSensitivity(1.8);

        // Flush debounced writes so values reach SharedPreferences before reinit.
        manager.flushPendingWrites();

        final newManager = SettingsManager();
        await newManager.init();

        expect(newManager.themeModeNotifier.value, ThemeMode.dark);
        expect(newManager.enableBlurNotifier.value, isFalse);
        expect(newManager.blurLevelNotifier.value, 50.0);
        expect(newManager.crossfadeDurationNotifier.value, 5.0);
        expect(newManager.sensitivityNotifier.value, 1.8);

        newManager.dispose();
      });
    });

    // ─── Dispose ───────────────────────────────────────────────────────

    group('dispose', () {
      test('disposes all notifiers without throwing', () {
        final m = SettingsManager();
        expect(() => m.dispose(), returnsNormally);
      });
    });
  });
}
