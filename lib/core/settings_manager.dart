import 'dart:async';

import 'logging/app_logger.dart';
import 'dart:convert';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─── Default Constants ───────────────────────────────────────────────────────

/// Default blur level (0–100 scale).
const double _kDefaultBlurLevel = 30.0;

/// Default window opacity (0.1–1.0).
const double _kDefaultWindowOpacity = 0.7;

/// Default crossfade duration in seconds (0–10).
const double _kDefaultCrossfadeDuration = 3.0;

/// Target normalization level in dB (−24 ... 0).
const double _kDefaultNormalizationLevel = -12.0;

/// Equalizer band count.
const int _kEqBandCount = 5;

/// Number of sort modes defined in the app.
const int _kSortModeCount = 6;

/// Manages all application settings with persistence via [SharedPreferences].
///
/// Each setting is exposed as a [ValueNotifier] for reactive UI updates.
/// Settings are grouped by category:
/// - **Theme**: theme mode, dynamic color, custom primary color
/// - **Window**: blur, opacity, native effects, grid view
/// - **Equalizer**: 5-band EQ, bass level, presets
/// - **Audio Effects**: crossfade, normalization, pitch, reverb, compressor
/// - **Sort & Filter**: sort mode, ascending/descending
/// - **Hotkeys**: custom key bindings
/// - **Media**: media key support, visualizer
///
/// Call [init] before using any notifier to load persisted values.
class SettingsManager {
  late SharedPreferences _prefs;
  Size? _savedWindowSize;
  Offset? _savedWindowPosition;
  bool _savedWindowMaximized = false;
  bool _savedWindowFullScreen = false;

  final ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier(
    ThemeMode.system,
  );
  final ValueNotifier<bool> enableBlurNotifier = ValueNotifier(true);
  final ValueNotifier<double> blurLevelNotifier = ValueNotifier(
    _kDefaultBlurLevel,
  );
  final ValueNotifier<bool> isMiniPlayerNotifier = ValueNotifier(false);

  final ValueNotifier<bool> useNativeWindowEffectNotifier = ValueNotifier(false);
  final ValueNotifier<double> windowOpacityNotifier = ValueNotifier(
    _kDefaultWindowOpacity,
  );

  final ValueNotifier<bool> isGridViewNotifier = ValueNotifier(false);
  final ValueNotifier<String?> customBackgroundImageNotifier = ValueNotifier(
    null,
  );
  final ValueNotifier<int> visualizerShapeNotifier = ValueNotifier(0);

  final ValueNotifier<bool> minimizeToTrayNotifier = ValueNotifier(true);
  final ValueNotifier<bool> visualizerEnabledNotifier = ValueNotifier(true);
  final ValueNotifier<bool> useDynamicColorNotifier = ValueNotifier(true);
  final ValueNotifier<bool> sidebarCollapsedNotifier = ValueNotifier(false);

  // Desktop Lyrics Window
  final ValueNotifier<bool> desktopLyricsEnabledNotifier = ValueNotifier(false);
  final ValueNotifier<double> desktopLyricsFontSizeNotifier = ValueNotifier(24.0);
  final ValueNotifier<double> desktopLyricsOpacityNotifier = ValueNotifier(0.9);
  final ValueNotifier<bool> desktopLyricsClickThroughNotifier = ValueNotifier(false);
  final ValueNotifier<double> sensitivityNotifier = ValueNotifier(1.0);
  final ValueNotifier<Color> customPrimaryColorNotifier = ValueNotifier(
    const Color(0xFF1DB954),
  );
  final ValueNotifier<Color?> dynamicPrimaryColorNotifier = ValueNotifier(null);

  // Current tab index (0=home, 1=library, 2=online, 3=ktv, 4=personal, 5=settings)
  final ValueNotifier<int> currentTabIndexNotifier = ValueNotifier(0);

  // Equalizer
  final ValueNotifier<List<double>> eqBandsNotifier = ValueNotifier(
    List<double>.filled(_kEqBandCount, 0.0),
  );
  final ValueNotifier<int> eqBassNotifier = ValueNotifier(0);
  final ValueNotifier<String> eqPresetNotifier = ValueNotifier('Normal');

  // Audio Effects
  final ValueNotifier<double> crossfadeDurationNotifier = ValueNotifier(
    _kDefaultCrossfadeDuration,
  );
  final ValueNotifier<int> crossfadeCurveNotifier = ValueNotifier(0); // 0=linear, 1=exponential, 2=sCurve
  final ValueNotifier<double> normalizationLevelNotifier = ValueNotifier(
    _kDefaultNormalizationLevel,
  );
  final ValueNotifier<bool> normalizationEnabledNotifier = ValueNotifier(false);
  final ValueNotifier<double> pitchShiftNotifier = ValueNotifier(1.0);
  final ValueNotifier<double> reverbMixNotifier = ValueNotifier(0.0);
  final ValueNotifier<double> compressionRatioNotifier = ValueNotifier(1.0);

  // Reverb (Freeverb) advanced params
  final ValueNotifier<double> reverbRoomSizeNotifier = ValueNotifier(0.5);
  final ValueNotifier<double> reverbDampNotifier = ValueNotifier(0.5);

  // Compressor advanced params
  final ValueNotifier<double> compThresholdNotifier = ValueNotifier(-6.0);
  final ValueNotifier<double> compAttackNotifier = ValueNotifier(10.0);
  final ValueNotifier<double> compReleaseNotifier = ValueNotifier(100.0);
  final ValueNotifier<double> compKneeWidthNotifier = ValueNotifier(2.0);
  final ValueNotifier<double> compMakeupGainNotifier = ValueNotifier(0.0);

  // Sort & Filter
  final ValueNotifier<int> sortModeNotifier = ValueNotifier(0);
  final ValueNotifier<bool> sortAscendingNotifier = ValueNotifier(true);

  // Custom Hotkeys
  final ValueNotifier<Map<String, String>> customHotkeysNotifier =
      ValueNotifier({});

  // Media Key Support
  final ValueNotifier<bool> mediaKeyEnabledNotifier = ValueNotifier(true);

  // ─── Debounced Persistence ────────────────────────────────────────────────
  // Slider onChanged fires on every pixel; writing to SharedPreferences each
  // time blocks the UI thread (especially in debug).  We debounce the disk
  // write so only the *final* value is persisted after the user stops dragging.
  final Map<String, _DebouncedWrite> _pendingWrites = {};
  static const int _persistDebounceMs = 300;

  /// Schedules a debounced SharedPreferences write for a continuous setting.
  /// The [ValueNotifier] is updated immediately (UI stays responsive); only
  /// the disk I/O is deferred.
  void _debouncePersist(String key, Future<void> Function() write) {
    _pendingWrites[key]?.timer.cancel();
    _pendingWrites[key] = _DebouncedWrite(
      timer: Timer(const Duration(milliseconds: _persistDebounceMs), () {
        _pendingWrites.remove(key);
        write();
      }),
      write: write,
    );
  }

  /// Flushes any pending debounced writes.  Call before app exit or test teardown.
  void flushPendingWrites() {
    for (final entry in _pendingWrites.values) {
      entry.timer.cancel();
      entry.write();
    }
    _pendingWrites.clear();
  }

  // Dominant color cache (in-memory mirror of persisted values)
  final Map<String, Color> _songColorCache = <String, Color>{};

  // Sleep Timer (transient - not persisted)
  final ValueNotifier<Duration?> sleepTimerDurationNotifier = ValueNotifier(
    null,
  );

  // Preset definitions: [60Hz, 230Hz, 910Hz, 3.6kHz, 14kHz], bassLevel
  static const Map<String, List<double>> _presetBands = {
    'Normal': [0.0, 0.0, 0.0, 0.0, 0.0],
    'Bass+': [0.8, 0.5, 0.0, -0.1, 0.0],
    'Vocal': [-0.2, 0.0, 0.5, 0.6, 0.3],
    'Acoustic': [0.3, 0.1, 0.2, 0.3, 0.5],
    'Custom': [0.0, 0.0, 0.0, 0.0, 0.0],
  };
  static const Map<String, int> _presetBass = {
    'Normal': 0,
    'Bass+': 60,
    'Vocal': 10,
    'Acoustic': 20,
    'Custom': 0,
  };

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();

    // Load Theme Mode
    final themeString = _prefs.getString('themeMode');
    if (themeString == 'light') {
      themeModeNotifier.value = ThemeMode.light;
    } else if (themeString == 'dark') {
      themeModeNotifier.value = ThemeMode.dark;
    } else {
      themeModeNotifier.value = ThemeMode.system;
    }

    // Load feature settings
    useNativeWindowEffectNotifier.value = _prefs.getBool('useNativeWindowEffect') ?? false;
    windowOpacityNotifier.value = _prefs.getDouble('windowOpacity') ?? _kDefaultWindowOpacity;
    enableBlurNotifier.value = _prefs.getBool('enableBlur') ?? true;
    blurLevelNotifier.value = _prefs.getDouble('blurLevel') ?? _kDefaultBlurLevel;
    minimizeToTrayNotifier.value = _prefs.getBool('minimizeToTray') ?? true;
    visualizerEnabledNotifier.value =
        _prefs.getBool('visualizerEnabled') ?? true;
    useDynamicColorNotifier.value = _prefs.getBool('useDynamicColor') ?? true;
    sidebarCollapsedNotifier.value = _prefs.getBool('sidebarCollapsed') ?? false;
    desktopLyricsEnabledNotifier.value = _prefs.getBool('desktopLyricsEnabled') ?? false;
    desktopLyricsFontSizeNotifier.value = _prefs.getDouble('desktopLyricsFontSize') ?? 24.0;
    desktopLyricsOpacityNotifier.value = _prefs.getDouble('desktopLyricsOpacity') ?? 0.9;
    desktopLyricsClickThroughNotifier.value = _prefs.getBool('desktopLyricsClickThrough') ?? false;
    sensitivityNotifier.value = _prefs.getDouble('sensitivity') ?? 1.0;

    // C3 fix: Load saved window state that was previously forgotten
    final w = _prefs.getDouble('savedWindowWidth');
    final h = _prefs.getDouble('savedWindowHeight');
    if (w != null && h != null) {
      _savedWindowSize = Size(w, h);
    }
    final x = _prefs.getDouble('savedWindowX');
    final y = _prefs.getDouble('savedWindowY');
    if (x != null && y != null) {
      _savedWindowPosition = Offset(x, y);
    }
    _savedWindowMaximized = _prefs.getBool('savedWindowMaximized') ?? false;
    _savedWindowFullScreen = _prefs.getBool('savedWindowFullScreen') ?? false;

    isGridViewNotifier.value = _prefs.getBool('isGridView') ?? false;
    customBackgroundImageNotifier.value = _prefs.getString(
      'customBackgroundImage',
    );
    visualizerShapeNotifier.value = _prefs.getInt('visualizerShape') ?? 0;

    final colorInt = _prefs.getInt('customPrimaryColor');
    if (colorInt != null) {
      customPrimaryColorNotifier.value = Color(colorInt);
    }

    // Load EQ
    eqPresetNotifier.value = _prefs.getString('eqPreset') ?? 'Normal';
    eqBassNotifier.value = _prefs.getInt('eqBass') ?? 0;
    final savedBands = _prefs.getStringList('eqBands');
    if (savedBands != null && savedBands.length == 5) {
      eqBandsNotifier.value = savedBands
          .map((s) => double.tryParse(s) ?? 0.0)
          .toList();
    }

    // Load Audio Effects
    crossfadeDurationNotifier.value =
        _prefs.getDouble('crossfadeDuration') ?? 3.0;
    crossfadeCurveNotifier.value =
        _prefs.getInt('crossfadeCurve') ?? 0;
    normalizationLevelNotifier.value =
        _prefs.getDouble('normalizationLevel') ?? -12.0;
    normalizationEnabledNotifier.value =
        _prefs.getBool('normalizationEnabled') ?? false;
    pitchShiftNotifier.value = _prefs.getDouble('pitchShift') ?? 1.0;
    reverbMixNotifier.value = _prefs.getDouble('reverbMix') ?? 0.0;
    compressionRatioNotifier.value =
        _prefs.getDouble('compressionRatio') ?? 1.0;

    // Load Reverb advanced
    reverbRoomSizeNotifier.value = _prefs.getDouble('reverbRoomSize') ?? 0.5;
    reverbDampNotifier.value = _prefs.getDouble('reverbDamp') ?? 0.5;

    // Load Compressor advanced
    compThresholdNotifier.value = _prefs.getDouble('compThreshold') ?? -6.0;
    compAttackNotifier.value = _prefs.getDouble('compAttack') ?? 10.0;
    compReleaseNotifier.value = _prefs.getDouble('compRelease') ?? 100.0;
    compKneeWidthNotifier.value = _prefs.getDouble('compKneeWidth') ?? 2.0;
    compMakeupGainNotifier.value = _prefs.getDouble('compMakeupGain') ?? 0.0;

    // Load Sort Mode
    sortModeNotifier.value = _prefs.getInt('sortMode') ?? 0;
    sortAscendingNotifier.value = _prefs.getBool('sortAscending') ?? true;

    // Load Custom Hotkeys
    final hotkeysJson = _prefs.getString('customHotkeys');
    if (hotkeysJson != null) {
      try {
        final Map<String, dynamic> decoded = jsonDecode(hotkeysJson);
        final hotkeys = decoded.map((key, value) => MapEntry(key, value.toString()));
        customHotkeysNotifier.value = hotkeys;
      } catch (e, stack) {
        AppLogger.e(
          'settings.manager',
          'custom hotkeys JSON parse failed; trying legacy format',
          error: e,
          stack: stack,
        );
        // Fallback to old format
        try {
          final hotkeys = Map<String, String>.from(
            (hotkeysJson.split(';')).fold<Map<String, String>>({}, (map, pair) {
              final parts = pair.split(':');
              if (parts.length == 2) {
                map[parts[0]] = parts[1];
              }
              return map;
            }),
          );
          customHotkeysNotifier.value = hotkeys;
        } catch (e, stack) {
          AppLogger.e(
            'settings.manager',
            'legacy hotkeys parse failed',
            error: e,
            stack: stack,
          );
        }
      }
    }

    // Load Media Key
    mediaKeyEnabledNotifier.value = _prefs.getBool('mediaKeyEnabled') ?? true;

    // Áp dụng ngay cài đặt SoLoud (chỉ khi engine đã khởi tạo)
    // Lưu ý: SoLoud được khởi tạo trong main.dart sau khi SettingsManager.init() chạy
    // Nên ta không thể áp dụng ở đây. Việc áp dụng sẽ được thực hiện trong main.dart
    // sau khi SoLoud.instance.init() hoàn tất.
  }

  Future<void> setIsGridView(bool isGrid) async {
    isGridViewNotifier.value = isGrid;
    await _prefs.setBool('isGridView', isGrid);
  }

  Future<void> setSidebarCollapsed(bool collapsed) async {
    sidebarCollapsedNotifier.value = collapsed;
    await _prefs.setBool('sidebarCollapsed', collapsed);
  }

  Future<void> setDesktopLyricsEnabled(bool enabled) async {
    desktopLyricsEnabledNotifier.value = enabled;
    await _prefs.setBool('desktopLyricsEnabled', enabled);
  }

  Future<void> setDesktopLyricsFontSize(double size) async {
    desktopLyricsFontSizeNotifier.value = size;
    await _prefs.setDouble('desktopLyricsFontSize', size);
  }

  Future<void> setDesktopLyricsOpacity(double opacity) async {
    desktopLyricsOpacityNotifier.value = opacity;
    await _prefs.setDouble('desktopLyricsOpacity', opacity);
  }

  Future<void> setDesktopLyricsClickThrough(bool clickThrough) async {
    desktopLyricsClickThroughNotifier.value = clickThrough;
    await _prefs.setBool('desktopLyricsClickThrough', clickThrough);
  }

  Future<void> setCustomBackgroundImage(String? path) async {
    customBackgroundImageNotifier.value = path;
    if (path == null) {
      await _prefs.remove('customBackgroundImage');
    } else {
      await _prefs.setString('customBackgroundImage', path);
    }
  }

  Future<void> setVisualizerShape(int shape) async {
    visualizerShapeNotifier.value = shape;
    await _prefs.setInt('visualizerShape', shape);
  }

  void setIsMiniPlayer(bool isMini) {
    isMiniPlayerNotifier.value = isMini;
  }

  Future<void> setSavedWindowState(Size size, bool isMaximized, bool isFullScreen) async {
    _savedWindowSize = size;
    _savedWindowMaximized = isMaximized;
    _savedWindowFullScreen = isFullScreen;
    await _prefs.setDouble('savedWindowWidth', size.width);
    await _prefs.setDouble('savedWindowHeight', size.height);
    await _prefs.setBool('savedWindowMaximized', isMaximized);
    await _prefs.setBool('savedWindowFullScreen', isFullScreen);
  }

  Size? get savedWindowSize => _savedWindowSize;
  Offset? get savedWindowPosition => _savedWindowPosition;
  bool get savedWindowMaximized => _savedWindowMaximized;
  bool get savedWindowFullScreen => _savedWindowFullScreen;

  Future<void> setSavedWindowPosition(Offset position) async {
    _savedWindowPosition = position;
    await _prefs.setDouble('savedWindowX', position.dx);
    await _prefs.setDouble('savedWindowY', position.dy);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    themeModeNotifier.value = mode;
    String val = 'system';
    if (mode == ThemeMode.light) {
      val = 'light';
    } else if (mode == ThemeMode.dark) {
      val = 'dark';
    }
    await _prefs.setString('themeMode', val);
  }

  Future<void> setEnableBlur(bool enable) async {
    enableBlurNotifier.value = enable;
    await _prefs.setBool('enableBlur', enable);
  }

  Future<void> setBlurLevel(double level) async {
    blurLevelNotifier.value = level.clamp(0.0, 100.0);
    _debouncePersist('blurLevel', () => _prefs.setDouble('blurLevel', blurLevelNotifier.value));
  }

  Future<void> setUseNativeWindowEffect(bool enable) async {
    useNativeWindowEffectNotifier.value = enable;
    await _prefs.setBool('useNativeWindowEffect', enable);
  }

  Future<void> setWindowOpacity(double opacity) async {
    windowOpacityNotifier.value = opacity.clamp(0.1, 1.0);
    _debouncePersist('windowOpacity', () => _prefs.setDouble('windowOpacity', windowOpacityNotifier.value));
  }

  Future<void> setMinimizeToTray(bool minimize) async {
    minimizeToTrayNotifier.value = minimize;
    await _prefs.setBool('minimizeToTray', minimize);
  }

  Future<void> setVisualizerEnabled(bool enable) async {
    visualizerEnabledNotifier.value = enable;
    await _prefs.setBool('visualizerEnabled', enable);
    try {
      SoLoud.instance.setVisualizationEnabled(enable);
    } catch (e, stack) {
      AppLogger.e('settings.manager', 'operation failed', error: e, stack: stack);
    }
  }

  Future<void> setSensitivity(double value) async {
    sensitivityNotifier.value = value.clamp(0.3, 2.5);
    _debouncePersist('sensitivity', () => _prefs.setDouble('sensitivity', sensitivityNotifier.value));
  }

  Future<void> setUseDynamicColor(bool useDynamic) async {
    useDynamicColorNotifier.value = useDynamic;
    await _prefs.setBool('useDynamicColor', useDynamic);
  }

  Future<void> setCustomPrimaryColor(Color color) async {
    customPrimaryColorNotifier.value = color;
    await _prefs.setInt('customPrimaryColor', color.toARGB32());
  }

  // ─── Equalizer ──────────────────────────────────────────────────────────────

  Future<void> setEqBand(int index, double value) async {
    final bands = List<double>.from(eqBandsNotifier.value);
    bands[index] = value.clamp(-1.0, 1.0);
    eqBandsNotifier.value = bands;
    _debouncePersist('eqBands', () => _prefs.setStringList(
      'eqBands',
      bands.map((b) => b.toStringAsFixed(3)).toList(),
    ));
  }

  Future<void> setEqBass(int level) async {
    eqBassNotifier.value = level.clamp(0, 100);
    await _prefs.setInt('eqBass', level);
  }

  Future<void> applyEqPreset(String preset) async {
    eqPresetNotifier.value = preset;
    await _prefs.setString('eqPreset', preset);

    final bands = _presetBands[preset];
    if (bands != null && preset != 'Custom') {
      eqBandsNotifier.value = List<double>.from(bands);
      await _prefs.setStringList(
        'eqBands',
        bands.map((b) => b.toStringAsFixed(3)).toList(),
      );
    }

    final bass = _presetBass[preset];
    if (bass != null && preset != 'Custom') {
      eqBassNotifier.value = bass;
      await _prefs.setInt('eqBass', bass);
    }
  }

  // ─── Audio Effects Setters ─────────────────────────────────────────────────

  Future<void> setCrossfadeDuration(double duration) async {
    crossfadeDurationNotifier.value = duration.clamp(0.0, 10.0);
    _debouncePersist('crossfadeDuration', () => _prefs.setDouble(
      'crossfadeDuration',
      crossfadeDurationNotifier.value,
    ));
  }

  Future<void> setCrossfadeCurve(int curve) async {
    crossfadeCurveNotifier.value = curve.clamp(0, 2);
    await _prefs.setInt('crossfadeCurve', crossfadeCurveNotifier.value);
  }

  Future<void> setNormalizationLevel(double level) async {
    normalizationLevelNotifier.value = level.clamp(-24.0, 0.0);
    _debouncePersist('normalizationLevel', () => _prefs.setDouble(
      'normalizationLevel',
      normalizationLevelNotifier.value,
    ));
  }

  Future<void> setNormalizationEnabled(bool enabled) async {
    normalizationEnabledNotifier.value = enabled;
    await _prefs.setBool('normalizationEnabled', enabled);
  }

  Future<void> setPitchShift(double pitch) async {
    pitchShiftNotifier.value = pitch.clamp(0.5, 2.0);
    _debouncePersist('pitchShift', () => _prefs.setDouble('pitchShift', pitchShiftNotifier.value));
  }

  Future<void> setReverbMix(double mix) async {
    reverbMixNotifier.value = mix.clamp(0.0, 1.0);
    _debouncePersist('reverbMix', () => _prefs.setDouble('reverbMix', reverbMixNotifier.value));
  }

  Future<void> setCompressionRatio(double ratio) async {
    compressionRatioNotifier.value = ratio.clamp(1.0, 10.0);
    _debouncePersist('compressionRatio', () => _prefs.setDouble('compressionRatio', compressionRatioNotifier.value));
  }

  Future<void> setReverbRoomSize(double size) async {
    reverbRoomSizeNotifier.value = size.clamp(0.0, 1.0);
    _debouncePersist('reverbRoomSize', () => _prefs.setDouble('reverbRoomSize', reverbRoomSizeNotifier.value));
  }

  Future<void> setReverbDamp(double damp) async {
    reverbDampNotifier.value = damp.clamp(0.0, 1.0);
    _debouncePersist('reverbDamp', () => _prefs.setDouble('reverbDamp', reverbDampNotifier.value));
  }

  Future<void> setCompThreshold(double threshold) async {
    compThresholdNotifier.value = threshold.clamp(-80.0, 0.0);
    _debouncePersist('compThreshold', () => _prefs.setDouble('compThreshold', compThresholdNotifier.value));
  }

  Future<void> setCompAttack(double attack) async {
    compAttackNotifier.value = attack.clamp(0.0, 100.0);
    _debouncePersist('compAttack', () => _prefs.setDouble('compAttack', compAttackNotifier.value));
  }

  Future<void> setCompRelease(double release) async {
    compReleaseNotifier.value = release.clamp(0.0, 1000.0);
    _debouncePersist('compRelease', () => _prefs.setDouble('compRelease', compReleaseNotifier.value));
  }

  Future<void> setCompKneeWidth(double knee) async {
    compKneeWidthNotifier.value = knee.clamp(0.0, 40.0);
    _debouncePersist('compKneeWidth', () => _prefs.setDouble('compKneeWidth', compKneeWidthNotifier.value));
  }

  Future<void> setCompMakeupGain(double gain) async {
    compMakeupGainNotifier.value = gain.clamp(-40.0, 40.0);
    _debouncePersist('compMakeupGain', () => _prefs.setDouble('compMakeupGain', compMakeupGainNotifier.value));
  }

  // ─── Sort Mode Setters ────────────────────────────────────────────────────

  Future<void> setSortMode(int mode) async {
    sortModeNotifier.value = mode.clamp(0, _kSortModeCount - 1);
    await _prefs.setInt('sortMode', sortModeNotifier.value);
  }

  Future<void> setSortAscending(bool ascending) async {
    sortAscendingNotifier.value = ascending;
    await _prefs.setBool('sortAscending', ascending);
  }

  // ─── Custom Hotkeys Setters ───────────────────────────────────────────────

  Future<void> setCustomHotkey(String action, String keys) async {
    final hotkeys = Map<String, String>.from(customHotkeysNotifier.value);
    hotkeys[action] = keys;
    customHotkeysNotifier.value = hotkeys;
    await _prefs.setString('customHotkeys', jsonEncode(hotkeys));
  }

  Future<void> removeCustomHotkey(String action) async {
    final hotkeys = Map<String, String>.from(customHotkeysNotifier.value);
    hotkeys.remove(action);
    customHotkeysNotifier.value = hotkeys;
    await _prefs.setString('customHotkeys', jsonEncode(hotkeys));
  }

  // ─── Media Key Setters ───────────────────────────────────────────────────

  Future<void> setMediaKeyEnabled(bool enabled) async {
    mediaKeyEnabledNotifier.value = enabled;
    await _prefs.setBool('mediaKeyEnabled', enabled);
  }

  // #7: Dispose all ValueNotifiers to avoid listener leaks in tests / hot-reload
  // ── Dominant Color Cache ──────────────────────────────────────────

  /// Returns the cached dominant color for [fileName], or null if not yet computed.
  Color? getSongColor(String fileName) {
    // Check in-memory first
    if (_songColorCache.containsKey(fileName)) {
      return _songColorCache[fileName];
    }
    // Fall back to disk
    final colorInt = _prefs.getInt('songColor_$fileName');
    if (colorInt != null) {
      final color = Color(colorInt);
      _songColorCache[fileName] = color;
      return color;
    }
    return null;
  }

  /// Saves the dominant [color] for [fileName] to both memory and disk.
  Future<void> saveSongColor(String fileName, Color color) async {
    _songColorCache[fileName] = color;
    await _prefs.setInt('songColor_$fileName', color.toARGB32());
  }

  /// All [ValueNotifier]s exposed by this manager in a single list, so
  /// reactive wrappers (e.g. [SettingsNotifier]) can subscribe to changes
  /// across the whole manager without enumerating each notifier manually.
  ///
  /// Kept in sync with the field declarations above; additions here must
  /// match new fields added to the class.
  List<ValueNotifier<dynamic>> get allNotifiers => <ValueNotifier<dynamic>>[
    themeModeNotifier,
    enableBlurNotifier,
    blurLevelNotifier,
    isMiniPlayerNotifier,
    useNativeWindowEffectNotifier,
    windowOpacityNotifier,
    isGridViewNotifier,
    customBackgroundImageNotifier,
    visualizerShapeNotifier,
    minimizeToTrayNotifier,
    visualizerEnabledNotifier,
    useDynamicColorNotifier,
    sidebarCollapsedNotifier,
    desktopLyricsEnabledNotifier,
    desktopLyricsFontSizeNotifier,
    desktopLyricsOpacityNotifier,
    desktopLyricsClickThroughNotifier,
    sensitivityNotifier,
    customPrimaryColorNotifier,
    dynamicPrimaryColorNotifier,
    currentTabIndexNotifier,
    eqBandsNotifier,
    eqBassNotifier,
    eqPresetNotifier,
    crossfadeDurationNotifier,
    crossfadeCurveNotifier,
    normalizationLevelNotifier,
    normalizationEnabledNotifier,
    pitchShiftNotifier,
    reverbMixNotifier,
    compressionRatioNotifier,
    reverbRoomSizeNotifier,
    reverbDampNotifier,
    compThresholdNotifier,
    compAttackNotifier,
    compReleaseNotifier,
    compKneeWidthNotifier,
    compMakeupGainNotifier,
    sortModeNotifier,
    sortAscendingNotifier,
    customHotkeysNotifier,
    mediaKeyEnabledNotifier,
    sleepTimerDurationNotifier,
  ];

  void dispose() {
    flushPendingWrites();
    useNativeWindowEffectNotifier.dispose();
    windowOpacityNotifier.dispose();
    themeModeNotifier.dispose();
    enableBlurNotifier.dispose();
    blurLevelNotifier.dispose();
    isMiniPlayerNotifier.dispose();
    isGridViewNotifier.dispose();
    customBackgroundImageNotifier.dispose();
    visualizerShapeNotifier.dispose();
    minimizeToTrayNotifier.dispose();
    visualizerEnabledNotifier.dispose();
    useDynamicColorNotifier.dispose();
    sensitivityNotifier.dispose();
    customPrimaryColorNotifier.dispose();
    dynamicPrimaryColorNotifier.dispose();
    eqBandsNotifier.dispose();
    eqBassNotifier.dispose();
    eqPresetNotifier.dispose();
    crossfadeDurationNotifier.dispose();
    normalizationLevelNotifier.dispose();
    normalizationEnabledNotifier.dispose();
    pitchShiftNotifier.dispose();
    reverbMixNotifier.dispose();
    compressionRatioNotifier.dispose();
    reverbRoomSizeNotifier.dispose();
    reverbDampNotifier.dispose();
    compThresholdNotifier.dispose();
    compAttackNotifier.dispose();
    compReleaseNotifier.dispose();
    compKneeWidthNotifier.dispose();
    compMakeupGainNotifier.dispose();
    sortModeNotifier.dispose();
    sortAscendingNotifier.dispose();
    customHotkeysNotifier.dispose();
    mediaKeyEnabledNotifier.dispose();
    sleepTimerDurationNotifier.dispose();
  }
}

/// Pairs a debounce [Timer] with its original [write] callback so that
/// [SettingsManager.flushPendingWrites] can execute pending writes immediately.
class _DebouncedWrite {
  const _DebouncedWrite({required this.timer, required this.write});
  final Timer timer;
  final Future<void> Function() write;
}
