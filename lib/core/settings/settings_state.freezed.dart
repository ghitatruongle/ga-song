// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'settings_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$SettingsState {
  // ─── Theme ──────────────────────────────────────────────────────
  ThemeMode get themeMode => throw _privateConstructorUsedError;
  bool get enableBlur => throw _privateConstructorUsedError;
  double get blurLevel => throw _privateConstructorUsedError;
  bool get useNativeWindowEffect => throw _privateConstructorUsedError;
  double get windowOpacity => throw _privateConstructorUsedError;
  bool get useDynamicColor => throw _privateConstructorUsedError;
  Color get customPrimaryColor => throw _privateConstructorUsedError;
  Color? get dynamicPrimaryColor =>
      throw _privateConstructorUsedError; // ─── Window & Layout ────────────────────────────────────────────
  bool get isMiniPlayer => throw _privateConstructorUsedError;
  bool get isGridView => throw _privateConstructorUsedError;
  bool get sidebarCollapsed => throw _privateConstructorUsedError;
  int get currentTabIndex =>
      throw _privateConstructorUsedError; // ─── Equalizer ──────────────────────────────────────────────────
  List<double> get eqBands => throw _privateConstructorUsedError;
  int get eqBassLevel => throw _privateConstructorUsedError;
  String get eqPreset =>
      throw _privateConstructorUsedError; // ─── Audio Effects ──────────────────────────────────────────────
  double get crossfadeDuration => throw _privateConstructorUsedError;
  int get crossfadeCurve =>
      throw _privateConstructorUsedError; // 0=linear, 1=exponential, 2=sCurve
  double get normalizationLevel => throw _privateConstructorUsedError;
  bool get normalizationEnabled => throw _privateConstructorUsedError;
  double get pitchShift => throw _privateConstructorUsedError;
  double get reverbMix => throw _privateConstructorUsedError;
  double get reverbRoomSize => throw _privateConstructorUsedError;
  double get reverbDamp => throw _privateConstructorUsedError;
  double get compressionRatio => throw _privateConstructorUsedError;
  double get compThreshold => throw _privateConstructorUsedError;
  double get compAttack => throw _privateConstructorUsedError;
  double get compRelease => throw _privateConstructorUsedError;
  double get compKneeWidth => throw _privateConstructorUsedError;
  double get compMakeupGain =>
      throw _privateConstructorUsedError; // ─── Sort & Filter ──────────────────────────────────────────────
  int get sortMode => throw _privateConstructorUsedError;
  bool get sortAscending =>
      throw _privateConstructorUsedError; // ─── Desktop Lyrics ─────────────────────────────────────────────
  bool get desktopLyricsEnabled => throw _privateConstructorUsedError;
  double get desktopLyricsFontSize => throw _privateConstructorUsedError;
  double get desktopLyricsOpacity => throw _privateConstructorUsedError;
  bool get desktopLyricsClickThrough =>
      throw _privateConstructorUsedError; // ─── In-app Lyric ──────────────────────────────────────────────
  double get lyricFontSize =>
      throw _privateConstructorUsedError; // ─── Visualizer ─────────────────────────────────────────────────
  bool get visualizerEnabled => throw _privateConstructorUsedError;
  int get visualizerShape =>
      throw _privateConstructorUsedError; // ─── Hotkeys & Media ────────────────────────────────────────────
  Map<String, String> get customHotkeys => throw _privateConstructorUsedError;
  bool get mediaKeyEnabled =>
      throw _privateConstructorUsedError; // ─── Feedback (Phase 4) ──────────────────────────────────────────
  bool get soundFeedbackEnabled =>
      throw _privateConstructorUsedError; // ─── Other ──────────────────────────────────────────────────────
  bool get minimizeToTray => throw _privateConstructorUsedError;
  double get sensitivity => throw _privateConstructorUsedError;
  String? get customBackgroundImage => throw _privateConstructorUsedError;

  /// Create a copy of SettingsState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SettingsStateCopyWith<SettingsState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SettingsStateCopyWith<$Res> {
  factory $SettingsStateCopyWith(
    SettingsState value,
    $Res Function(SettingsState) then,
  ) = _$SettingsStateCopyWithImpl<$Res, SettingsState>;
  @useResult
  $Res call({
    ThemeMode themeMode,
    bool enableBlur,
    double blurLevel,
    bool useNativeWindowEffect,
    double windowOpacity,
    bool useDynamicColor,
    Color customPrimaryColor,
    Color? dynamicPrimaryColor,
    bool isMiniPlayer,
    bool isGridView,
    bool sidebarCollapsed,
    int currentTabIndex,
    List<double> eqBands,
    int eqBassLevel,
    String eqPreset,
    double crossfadeDuration,
    int crossfadeCurve,
    double normalizationLevel,
    bool normalizationEnabled,
    double pitchShift,
    double reverbMix,
    double reverbRoomSize,
    double reverbDamp,
    double compressionRatio,
    double compThreshold,
    double compAttack,
    double compRelease,
    double compKneeWidth,
    double compMakeupGain,
    int sortMode,
    bool sortAscending,
    bool desktopLyricsEnabled,
    double desktopLyricsFontSize,
    double desktopLyricsOpacity,
    bool desktopLyricsClickThrough,
    double lyricFontSize,
    bool visualizerEnabled,
    int visualizerShape,
    Map<String, String> customHotkeys,
    bool mediaKeyEnabled,
    bool soundFeedbackEnabled,
    bool minimizeToTray,
    double sensitivity,
    String? customBackgroundImage,
  });
}

/// @nodoc
class _$SettingsStateCopyWithImpl<$Res, $Val extends SettingsState>
    implements $SettingsStateCopyWith<$Res> {
  _$SettingsStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SettingsState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? themeMode = null,
    Object? enableBlur = null,
    Object? blurLevel = null,
    Object? useNativeWindowEffect = null,
    Object? windowOpacity = null,
    Object? useDynamicColor = null,
    Object? customPrimaryColor = null,
    Object? dynamicPrimaryColor = freezed,
    Object? isMiniPlayer = null,
    Object? isGridView = null,
    Object? sidebarCollapsed = null,
    Object? currentTabIndex = null,
    Object? eqBands = null,
    Object? eqBassLevel = null,
    Object? eqPreset = null,
    Object? crossfadeDuration = null,
    Object? crossfadeCurve = null,
    Object? normalizationLevel = null,
    Object? normalizationEnabled = null,
    Object? pitchShift = null,
    Object? reverbMix = null,
    Object? reverbRoomSize = null,
    Object? reverbDamp = null,
    Object? compressionRatio = null,
    Object? compThreshold = null,
    Object? compAttack = null,
    Object? compRelease = null,
    Object? compKneeWidth = null,
    Object? compMakeupGain = null,
    Object? sortMode = null,
    Object? sortAscending = null,
    Object? desktopLyricsEnabled = null,
    Object? desktopLyricsFontSize = null,
    Object? desktopLyricsOpacity = null,
    Object? desktopLyricsClickThrough = null,
    Object? lyricFontSize = null,
    Object? visualizerEnabled = null,
    Object? visualizerShape = null,
    Object? customHotkeys = null,
    Object? mediaKeyEnabled = null,
    Object? soundFeedbackEnabled = null,
    Object? minimizeToTray = null,
    Object? sensitivity = null,
    Object? customBackgroundImage = freezed,
  }) {
    return _then(
      _value.copyWith(
            themeMode: null == themeMode
                ? _value.themeMode
                : themeMode // ignore: cast_nullable_to_non_nullable
                      as ThemeMode,
            enableBlur: null == enableBlur
                ? _value.enableBlur
                : enableBlur // ignore: cast_nullable_to_non_nullable
                      as bool,
            blurLevel: null == blurLevel
                ? _value.blurLevel
                : blurLevel // ignore: cast_nullable_to_non_nullable
                      as double,
            useNativeWindowEffect: null == useNativeWindowEffect
                ? _value.useNativeWindowEffect
                : useNativeWindowEffect // ignore: cast_nullable_to_non_nullable
                      as bool,
            windowOpacity: null == windowOpacity
                ? _value.windowOpacity
                : windowOpacity // ignore: cast_nullable_to_non_nullable
                      as double,
            useDynamicColor: null == useDynamicColor
                ? _value.useDynamicColor
                : useDynamicColor // ignore: cast_nullable_to_non_nullable
                      as bool,
            customPrimaryColor: null == customPrimaryColor
                ? _value.customPrimaryColor
                : customPrimaryColor // ignore: cast_nullable_to_non_nullable
                      as Color,
            dynamicPrimaryColor: freezed == dynamicPrimaryColor
                ? _value.dynamicPrimaryColor
                : dynamicPrimaryColor // ignore: cast_nullable_to_non_nullable
                      as Color?,
            isMiniPlayer: null == isMiniPlayer
                ? _value.isMiniPlayer
                : isMiniPlayer // ignore: cast_nullable_to_non_nullable
                      as bool,
            isGridView: null == isGridView
                ? _value.isGridView
                : isGridView // ignore: cast_nullable_to_non_nullable
                      as bool,
            sidebarCollapsed: null == sidebarCollapsed
                ? _value.sidebarCollapsed
                : sidebarCollapsed // ignore: cast_nullable_to_non_nullable
                      as bool,
            currentTabIndex: null == currentTabIndex
                ? _value.currentTabIndex
                : currentTabIndex // ignore: cast_nullable_to_non_nullable
                      as int,
            eqBands: null == eqBands
                ? _value.eqBands
                : eqBands // ignore: cast_nullable_to_non_nullable
                      as List<double>,
            eqBassLevel: null == eqBassLevel
                ? _value.eqBassLevel
                : eqBassLevel // ignore: cast_nullable_to_non_nullable
                      as int,
            eqPreset: null == eqPreset
                ? _value.eqPreset
                : eqPreset // ignore: cast_nullable_to_non_nullable
                      as String,
            crossfadeDuration: null == crossfadeDuration
                ? _value.crossfadeDuration
                : crossfadeDuration // ignore: cast_nullable_to_non_nullable
                      as double,
            crossfadeCurve: null == crossfadeCurve
                ? _value.crossfadeCurve
                : crossfadeCurve // ignore: cast_nullable_to_non_nullable
                      as int,
            normalizationLevel: null == normalizationLevel
                ? _value.normalizationLevel
                : normalizationLevel // ignore: cast_nullable_to_non_nullable
                      as double,
            normalizationEnabled: null == normalizationEnabled
                ? _value.normalizationEnabled
                : normalizationEnabled // ignore: cast_nullable_to_non_nullable
                      as bool,
            pitchShift: null == pitchShift
                ? _value.pitchShift
                : pitchShift // ignore: cast_nullable_to_non_nullable
                      as double,
            reverbMix: null == reverbMix
                ? _value.reverbMix
                : reverbMix // ignore: cast_nullable_to_non_nullable
                      as double,
            reverbRoomSize: null == reverbRoomSize
                ? _value.reverbRoomSize
                : reverbRoomSize // ignore: cast_nullable_to_non_nullable
                      as double,
            reverbDamp: null == reverbDamp
                ? _value.reverbDamp
                : reverbDamp // ignore: cast_nullable_to_non_nullable
                      as double,
            compressionRatio: null == compressionRatio
                ? _value.compressionRatio
                : compressionRatio // ignore: cast_nullable_to_non_nullable
                      as double,
            compThreshold: null == compThreshold
                ? _value.compThreshold
                : compThreshold // ignore: cast_nullable_to_non_nullable
                      as double,
            compAttack: null == compAttack
                ? _value.compAttack
                : compAttack // ignore: cast_nullable_to_non_nullable
                      as double,
            compRelease: null == compRelease
                ? _value.compRelease
                : compRelease // ignore: cast_nullable_to_non_nullable
                      as double,
            compKneeWidth: null == compKneeWidth
                ? _value.compKneeWidth
                : compKneeWidth // ignore: cast_nullable_to_non_nullable
                      as double,
            compMakeupGain: null == compMakeupGain
                ? _value.compMakeupGain
                : compMakeupGain // ignore: cast_nullable_to_non_nullable
                      as double,
            sortMode: null == sortMode
                ? _value.sortMode
                : sortMode // ignore: cast_nullable_to_non_nullable
                      as int,
            sortAscending: null == sortAscending
                ? _value.sortAscending
                : sortAscending // ignore: cast_nullable_to_non_nullable
                      as bool,
            desktopLyricsEnabled: null == desktopLyricsEnabled
                ? _value.desktopLyricsEnabled
                : desktopLyricsEnabled // ignore: cast_nullable_to_non_nullable
                      as bool,
            desktopLyricsFontSize: null == desktopLyricsFontSize
                ? _value.desktopLyricsFontSize
                : desktopLyricsFontSize // ignore: cast_nullable_to_non_nullable
                      as double,
            desktopLyricsOpacity: null == desktopLyricsOpacity
                ? _value.desktopLyricsOpacity
                : desktopLyricsOpacity // ignore: cast_nullable_to_non_nullable
                      as double,
            desktopLyricsClickThrough: null == desktopLyricsClickThrough
                ? _value.desktopLyricsClickThrough
                : desktopLyricsClickThrough // ignore: cast_nullable_to_non_nullable
                      as bool,
            lyricFontSize: null == lyricFontSize
                ? _value.lyricFontSize
                : lyricFontSize // ignore: cast_nullable_to_non_nullable
                      as double,
            visualizerEnabled: null == visualizerEnabled
                ? _value.visualizerEnabled
                : visualizerEnabled // ignore: cast_nullable_to_non_nullable
                      as bool,
            visualizerShape: null == visualizerShape
                ? _value.visualizerShape
                : visualizerShape // ignore: cast_nullable_to_non_nullable
                      as int,
            customHotkeys: null == customHotkeys
                ? _value.customHotkeys
                : customHotkeys // ignore: cast_nullable_to_non_nullable
                      as Map<String, String>,
            mediaKeyEnabled: null == mediaKeyEnabled
                ? _value.mediaKeyEnabled
                : mediaKeyEnabled // ignore: cast_nullable_to_non_nullable
                      as bool,
            soundFeedbackEnabled: null == soundFeedbackEnabled
                ? _value.soundFeedbackEnabled
                : soundFeedbackEnabled // ignore: cast_nullable_to_non_nullable
                      as bool,
            minimizeToTray: null == minimizeToTray
                ? _value.minimizeToTray
                : minimizeToTray // ignore: cast_nullable_to_non_nullable
                      as bool,
            sensitivity: null == sensitivity
                ? _value.sensitivity
                : sensitivity // ignore: cast_nullable_to_non_nullable
                      as double,
            customBackgroundImage: freezed == customBackgroundImage
                ? _value.customBackgroundImage
                : customBackgroundImage // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$SettingsStateImplCopyWith<$Res>
    implements $SettingsStateCopyWith<$Res> {
  factory _$$SettingsStateImplCopyWith(
    _$SettingsStateImpl value,
    $Res Function(_$SettingsStateImpl) then,
  ) = __$$SettingsStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    ThemeMode themeMode,
    bool enableBlur,
    double blurLevel,
    bool useNativeWindowEffect,
    double windowOpacity,
    bool useDynamicColor,
    Color customPrimaryColor,
    Color? dynamicPrimaryColor,
    bool isMiniPlayer,
    bool isGridView,
    bool sidebarCollapsed,
    int currentTabIndex,
    List<double> eqBands,
    int eqBassLevel,
    String eqPreset,
    double crossfadeDuration,
    int crossfadeCurve,
    double normalizationLevel,
    bool normalizationEnabled,
    double pitchShift,
    double reverbMix,
    double reverbRoomSize,
    double reverbDamp,
    double compressionRatio,
    double compThreshold,
    double compAttack,
    double compRelease,
    double compKneeWidth,
    double compMakeupGain,
    int sortMode,
    bool sortAscending,
    bool desktopLyricsEnabled,
    double desktopLyricsFontSize,
    double desktopLyricsOpacity,
    bool desktopLyricsClickThrough,
    double lyricFontSize,
    bool visualizerEnabled,
    int visualizerShape,
    Map<String, String> customHotkeys,
    bool mediaKeyEnabled,
    bool soundFeedbackEnabled,
    bool minimizeToTray,
    double sensitivity,
    String? customBackgroundImage,
  });
}

/// @nodoc
class __$$SettingsStateImplCopyWithImpl<$Res>
    extends _$SettingsStateCopyWithImpl<$Res, _$SettingsStateImpl>
    implements _$$SettingsStateImplCopyWith<$Res> {
  __$$SettingsStateImplCopyWithImpl(
    _$SettingsStateImpl _value,
    $Res Function(_$SettingsStateImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SettingsState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? themeMode = null,
    Object? enableBlur = null,
    Object? blurLevel = null,
    Object? useNativeWindowEffect = null,
    Object? windowOpacity = null,
    Object? useDynamicColor = null,
    Object? customPrimaryColor = null,
    Object? dynamicPrimaryColor = freezed,
    Object? isMiniPlayer = null,
    Object? isGridView = null,
    Object? sidebarCollapsed = null,
    Object? currentTabIndex = null,
    Object? eqBands = null,
    Object? eqBassLevel = null,
    Object? eqPreset = null,
    Object? crossfadeDuration = null,
    Object? crossfadeCurve = null,
    Object? normalizationLevel = null,
    Object? normalizationEnabled = null,
    Object? pitchShift = null,
    Object? reverbMix = null,
    Object? reverbRoomSize = null,
    Object? reverbDamp = null,
    Object? compressionRatio = null,
    Object? compThreshold = null,
    Object? compAttack = null,
    Object? compRelease = null,
    Object? compKneeWidth = null,
    Object? compMakeupGain = null,
    Object? sortMode = null,
    Object? sortAscending = null,
    Object? desktopLyricsEnabled = null,
    Object? desktopLyricsFontSize = null,
    Object? desktopLyricsOpacity = null,
    Object? desktopLyricsClickThrough = null,
    Object? lyricFontSize = null,
    Object? visualizerEnabled = null,
    Object? visualizerShape = null,
    Object? customHotkeys = null,
    Object? mediaKeyEnabled = null,
    Object? soundFeedbackEnabled = null,
    Object? minimizeToTray = null,
    Object? sensitivity = null,
    Object? customBackgroundImage = freezed,
  }) {
    return _then(
      _$SettingsStateImpl(
        themeMode: null == themeMode
            ? _value.themeMode
            : themeMode // ignore: cast_nullable_to_non_nullable
                  as ThemeMode,
        enableBlur: null == enableBlur
            ? _value.enableBlur
            : enableBlur // ignore: cast_nullable_to_non_nullable
                  as bool,
        blurLevel: null == blurLevel
            ? _value.blurLevel
            : blurLevel // ignore: cast_nullable_to_non_nullable
                  as double,
        useNativeWindowEffect: null == useNativeWindowEffect
            ? _value.useNativeWindowEffect
            : useNativeWindowEffect // ignore: cast_nullable_to_non_nullable
                  as bool,
        windowOpacity: null == windowOpacity
            ? _value.windowOpacity
            : windowOpacity // ignore: cast_nullable_to_non_nullable
                  as double,
        useDynamicColor: null == useDynamicColor
            ? _value.useDynamicColor
            : useDynamicColor // ignore: cast_nullable_to_non_nullable
                  as bool,
        customPrimaryColor: null == customPrimaryColor
            ? _value.customPrimaryColor
            : customPrimaryColor // ignore: cast_nullable_to_non_nullable
                  as Color,
        dynamicPrimaryColor: freezed == dynamicPrimaryColor
            ? _value.dynamicPrimaryColor
            : dynamicPrimaryColor // ignore: cast_nullable_to_non_nullable
                  as Color?,
        isMiniPlayer: null == isMiniPlayer
            ? _value.isMiniPlayer
            : isMiniPlayer // ignore: cast_nullable_to_non_nullable
                  as bool,
        isGridView: null == isGridView
            ? _value.isGridView
            : isGridView // ignore: cast_nullable_to_non_nullable
                  as bool,
        sidebarCollapsed: null == sidebarCollapsed
            ? _value.sidebarCollapsed
            : sidebarCollapsed // ignore: cast_nullable_to_non_nullable
                  as bool,
        currentTabIndex: null == currentTabIndex
            ? _value.currentTabIndex
            : currentTabIndex // ignore: cast_nullable_to_non_nullable
                  as int,
        eqBands: null == eqBands
            ? _value._eqBands
            : eqBands // ignore: cast_nullable_to_non_nullable
                  as List<double>,
        eqBassLevel: null == eqBassLevel
            ? _value.eqBassLevel
            : eqBassLevel // ignore: cast_nullable_to_non_nullable
                  as int,
        eqPreset: null == eqPreset
            ? _value.eqPreset
            : eqPreset // ignore: cast_nullable_to_non_nullable
                  as String,
        crossfadeDuration: null == crossfadeDuration
            ? _value.crossfadeDuration
            : crossfadeDuration // ignore: cast_nullable_to_non_nullable
                  as double,
        crossfadeCurve: null == crossfadeCurve
            ? _value.crossfadeCurve
            : crossfadeCurve // ignore: cast_nullable_to_non_nullable
                  as int,
        normalizationLevel: null == normalizationLevel
            ? _value.normalizationLevel
            : normalizationLevel // ignore: cast_nullable_to_non_nullable
                  as double,
        normalizationEnabled: null == normalizationEnabled
            ? _value.normalizationEnabled
            : normalizationEnabled // ignore: cast_nullable_to_non_nullable
                  as bool,
        pitchShift: null == pitchShift
            ? _value.pitchShift
            : pitchShift // ignore: cast_nullable_to_non_nullable
                  as double,
        reverbMix: null == reverbMix
            ? _value.reverbMix
            : reverbMix // ignore: cast_nullable_to_non_nullable
                  as double,
        reverbRoomSize: null == reverbRoomSize
            ? _value.reverbRoomSize
            : reverbRoomSize // ignore: cast_nullable_to_non_nullable
                  as double,
        reverbDamp: null == reverbDamp
            ? _value.reverbDamp
            : reverbDamp // ignore: cast_nullable_to_non_nullable
                  as double,
        compressionRatio: null == compressionRatio
            ? _value.compressionRatio
            : compressionRatio // ignore: cast_nullable_to_non_nullable
                  as double,
        compThreshold: null == compThreshold
            ? _value.compThreshold
            : compThreshold // ignore: cast_nullable_to_non_nullable
                  as double,
        compAttack: null == compAttack
            ? _value.compAttack
            : compAttack // ignore: cast_nullable_to_non_nullable
                  as double,
        compRelease: null == compRelease
            ? _value.compRelease
            : compRelease // ignore: cast_nullable_to_non_nullable
                  as double,
        compKneeWidth: null == compKneeWidth
            ? _value.compKneeWidth
            : compKneeWidth // ignore: cast_nullable_to_non_nullable
                  as double,
        compMakeupGain: null == compMakeupGain
            ? _value.compMakeupGain
            : compMakeupGain // ignore: cast_nullable_to_non_nullable
                  as double,
        sortMode: null == sortMode
            ? _value.sortMode
            : sortMode // ignore: cast_nullable_to_non_nullable
                  as int,
        sortAscending: null == sortAscending
            ? _value.sortAscending
            : sortAscending // ignore: cast_nullable_to_non_nullable
                  as bool,
        desktopLyricsEnabled: null == desktopLyricsEnabled
            ? _value.desktopLyricsEnabled
            : desktopLyricsEnabled // ignore: cast_nullable_to_non_nullable
                  as bool,
        desktopLyricsFontSize: null == desktopLyricsFontSize
            ? _value.desktopLyricsFontSize
            : desktopLyricsFontSize // ignore: cast_nullable_to_non_nullable
                  as double,
        desktopLyricsOpacity: null == desktopLyricsOpacity
            ? _value.desktopLyricsOpacity
            : desktopLyricsOpacity // ignore: cast_nullable_to_non_nullable
                  as double,
        desktopLyricsClickThrough: null == desktopLyricsClickThrough
            ? _value.desktopLyricsClickThrough
            : desktopLyricsClickThrough // ignore: cast_nullable_to_non_nullable
                  as bool,
        lyricFontSize: null == lyricFontSize
            ? _value.lyricFontSize
            : lyricFontSize // ignore: cast_nullable_to_non_nullable
                  as double,
        visualizerEnabled: null == visualizerEnabled
            ? _value.visualizerEnabled
            : visualizerEnabled // ignore: cast_nullable_to_non_nullable
                  as bool,
        visualizerShape: null == visualizerShape
            ? _value.visualizerShape
            : visualizerShape // ignore: cast_nullable_to_non_nullable
                  as int,
        customHotkeys: null == customHotkeys
            ? _value._customHotkeys
            : customHotkeys // ignore: cast_nullable_to_non_nullable
                  as Map<String, String>,
        mediaKeyEnabled: null == mediaKeyEnabled
            ? _value.mediaKeyEnabled
            : mediaKeyEnabled // ignore: cast_nullable_to_non_nullable
                  as bool,
        soundFeedbackEnabled: null == soundFeedbackEnabled
            ? _value.soundFeedbackEnabled
            : soundFeedbackEnabled // ignore: cast_nullable_to_non_nullable
                  as bool,
        minimizeToTray: null == minimizeToTray
            ? _value.minimizeToTray
            : minimizeToTray // ignore: cast_nullable_to_non_nullable
                  as bool,
        sensitivity: null == sensitivity
            ? _value.sensitivity
            : sensitivity // ignore: cast_nullable_to_non_nullable
                  as double,
        customBackgroundImage: freezed == customBackgroundImage
            ? _value.customBackgroundImage
            : customBackgroundImage // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc

class _$SettingsStateImpl implements _SettingsState {
  const _$SettingsStateImpl({
    this.themeMode = ThemeMode.system,
    this.enableBlur = true,
    this.blurLevel = 30.0,
    this.useNativeWindowEffect = false,
    this.windowOpacity = 0.7,
    this.useDynamicColor = true,
    this.customPrimaryColor = const Color(0xFF1DB954),
    this.dynamicPrimaryColor,
    this.isMiniPlayer = false,
    this.isGridView = false,
    this.sidebarCollapsed = false,
    this.currentTabIndex = 0,
    final List<double> eqBands = const [0.0, 0.0, 0.0, 0.0, 0.0],
    this.eqBassLevel = 0,
    this.eqPreset = 'Normal',
    this.crossfadeDuration = 3.0,
    this.crossfadeCurve = 0,
    this.normalizationLevel = -12.0,
    this.normalizationEnabled = false,
    this.pitchShift = 1.0,
    this.reverbMix = 0.0,
    this.reverbRoomSize = 0.5,
    this.reverbDamp = 0.5,
    this.compressionRatio = 1.0,
    this.compThreshold = -6.0,
    this.compAttack = 10.0,
    this.compRelease = 100.0,
    this.compKneeWidth = 2.0,
    this.compMakeupGain = 0.0,
    this.sortMode = 0,
    this.sortAscending = true,
    this.desktopLyricsEnabled = false,
    this.desktopLyricsFontSize = 24.0,
    this.desktopLyricsOpacity = 0.9,
    this.desktopLyricsClickThrough = false,
    this.lyricFontSize = 1.0,
    this.visualizerEnabled = true,
    this.visualizerShape = 0,
    final Map<String, String> customHotkeys = const {},
    this.mediaKeyEnabled = true,
    this.soundFeedbackEnabled = false,
    this.minimizeToTray = true,
    this.sensitivity = 1.0,
    this.customBackgroundImage,
  }) : _eqBands = eqBands,
       _customHotkeys = customHotkeys;

  // ─── Theme ──────────────────────────────────────────────────────
  @override
  @JsonKey()
  final ThemeMode themeMode;
  @override
  @JsonKey()
  final bool enableBlur;
  @override
  @JsonKey()
  final double blurLevel;
  @override
  @JsonKey()
  final bool useNativeWindowEffect;
  @override
  @JsonKey()
  final double windowOpacity;
  @override
  @JsonKey()
  final bool useDynamicColor;
  @override
  @JsonKey()
  final Color customPrimaryColor;
  @override
  final Color? dynamicPrimaryColor;
  // ─── Window & Layout ────────────────────────────────────────────
  @override
  @JsonKey()
  final bool isMiniPlayer;
  @override
  @JsonKey()
  final bool isGridView;
  @override
  @JsonKey()
  final bool sidebarCollapsed;
  @override
  @JsonKey()
  final int currentTabIndex;
  // ─── Equalizer ──────────────────────────────────────────────────
  final List<double> _eqBands;
  // ─── Equalizer ──────────────────────────────────────────────────
  @override
  @JsonKey()
  List<double> get eqBands {
    if (_eqBands is EqualUnmodifiableListView) return _eqBands;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_eqBands);
  }

  @override
  @JsonKey()
  final int eqBassLevel;
  @override
  @JsonKey()
  final String eqPreset;
  // ─── Audio Effects ──────────────────────────────────────────────
  @override
  @JsonKey()
  final double crossfadeDuration;
  @override
  @JsonKey()
  final int crossfadeCurve;
  // 0=linear, 1=exponential, 2=sCurve
  @override
  @JsonKey()
  final double normalizationLevel;
  @override
  @JsonKey()
  final bool normalizationEnabled;
  @override
  @JsonKey()
  final double pitchShift;
  @override
  @JsonKey()
  final double reverbMix;
  @override
  @JsonKey()
  final double reverbRoomSize;
  @override
  @JsonKey()
  final double reverbDamp;
  @override
  @JsonKey()
  final double compressionRatio;
  @override
  @JsonKey()
  final double compThreshold;
  @override
  @JsonKey()
  final double compAttack;
  @override
  @JsonKey()
  final double compRelease;
  @override
  @JsonKey()
  final double compKneeWidth;
  @override
  @JsonKey()
  final double compMakeupGain;
  // ─── Sort & Filter ──────────────────────────────────────────────
  @override
  @JsonKey()
  final int sortMode;
  @override
  @JsonKey()
  final bool sortAscending;
  // ─── Desktop Lyrics ─────────────────────────────────────────────
  @override
  @JsonKey()
  final bool desktopLyricsEnabled;
  @override
  @JsonKey()
  final double desktopLyricsFontSize;
  @override
  @JsonKey()
  final double desktopLyricsOpacity;
  @override
  @JsonKey()
  final bool desktopLyricsClickThrough;
  // ─── In-app Lyric ──────────────────────────────────────────────
  @override
  @JsonKey()
  final double lyricFontSize;
  // ─── Visualizer ─────────────────────────────────────────────────
  @override
  @JsonKey()
  final bool visualizerEnabled;
  @override
  @JsonKey()
  final int visualizerShape;
  // ─── Hotkeys & Media ────────────────────────────────────────────
  final Map<String, String> _customHotkeys;
  // ─── Hotkeys & Media ────────────────────────────────────────────
  @override
  @JsonKey()
  Map<String, String> get customHotkeys {
    if (_customHotkeys is EqualUnmodifiableMapView) return _customHotkeys;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_customHotkeys);
  }

  @override
  @JsonKey()
  final bool mediaKeyEnabled;
  // ─── Feedback (Phase 4) ──────────────────────────────────────────
  @override
  @JsonKey()
  final bool soundFeedbackEnabled;
  // ─── Other ──────────────────────────────────────────────────────
  @override
  @JsonKey()
  final bool minimizeToTray;
  @override
  @JsonKey()
  final double sensitivity;
  @override
  final String? customBackgroundImage;

  @override
  String toString() {
    return 'SettingsState(themeMode: $themeMode, enableBlur: $enableBlur, blurLevel: $blurLevel, useNativeWindowEffect: $useNativeWindowEffect, windowOpacity: $windowOpacity, useDynamicColor: $useDynamicColor, customPrimaryColor: $customPrimaryColor, dynamicPrimaryColor: $dynamicPrimaryColor, isMiniPlayer: $isMiniPlayer, isGridView: $isGridView, sidebarCollapsed: $sidebarCollapsed, currentTabIndex: $currentTabIndex, eqBands: $eqBands, eqBassLevel: $eqBassLevel, eqPreset: $eqPreset, crossfadeDuration: $crossfadeDuration, crossfadeCurve: $crossfadeCurve, normalizationLevel: $normalizationLevel, normalizationEnabled: $normalizationEnabled, pitchShift: $pitchShift, reverbMix: $reverbMix, reverbRoomSize: $reverbRoomSize, reverbDamp: $reverbDamp, compressionRatio: $compressionRatio, compThreshold: $compThreshold, compAttack: $compAttack, compRelease: $compRelease, compKneeWidth: $compKneeWidth, compMakeupGain: $compMakeupGain, sortMode: $sortMode, sortAscending: $sortAscending, desktopLyricsEnabled: $desktopLyricsEnabled, desktopLyricsFontSize: $desktopLyricsFontSize, desktopLyricsOpacity: $desktopLyricsOpacity, desktopLyricsClickThrough: $desktopLyricsClickThrough, lyricFontSize: $lyricFontSize, visualizerEnabled: $visualizerEnabled, visualizerShape: $visualizerShape, customHotkeys: $customHotkeys, mediaKeyEnabled: $mediaKeyEnabled, soundFeedbackEnabled: $soundFeedbackEnabled, minimizeToTray: $minimizeToTray, sensitivity: $sensitivity, customBackgroundImage: $customBackgroundImage)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SettingsStateImpl &&
            (identical(other.themeMode, themeMode) ||
                other.themeMode == themeMode) &&
            (identical(other.enableBlur, enableBlur) ||
                other.enableBlur == enableBlur) &&
            (identical(other.blurLevel, blurLevel) ||
                other.blurLevel == blurLevel) &&
            (identical(other.useNativeWindowEffect, useNativeWindowEffect) ||
                other.useNativeWindowEffect == useNativeWindowEffect) &&
            (identical(other.windowOpacity, windowOpacity) ||
                other.windowOpacity == windowOpacity) &&
            (identical(other.useDynamicColor, useDynamicColor) ||
                other.useDynamicColor == useDynamicColor) &&
            (identical(other.customPrimaryColor, customPrimaryColor) ||
                other.customPrimaryColor == customPrimaryColor) &&
            (identical(other.dynamicPrimaryColor, dynamicPrimaryColor) ||
                other.dynamicPrimaryColor == dynamicPrimaryColor) &&
            (identical(other.isMiniPlayer, isMiniPlayer) ||
                other.isMiniPlayer == isMiniPlayer) &&
            (identical(other.isGridView, isGridView) ||
                other.isGridView == isGridView) &&
            (identical(other.sidebarCollapsed, sidebarCollapsed) ||
                other.sidebarCollapsed == sidebarCollapsed) &&
            (identical(other.currentTabIndex, currentTabIndex) ||
                other.currentTabIndex == currentTabIndex) &&
            const DeepCollectionEquality().equals(other._eqBands, _eqBands) &&
            (identical(other.eqBassLevel, eqBassLevel) ||
                other.eqBassLevel == eqBassLevel) &&
            (identical(other.eqPreset, eqPreset) ||
                other.eqPreset == eqPreset) &&
            (identical(other.crossfadeDuration, crossfadeDuration) ||
                other.crossfadeDuration == crossfadeDuration) &&
            (identical(other.crossfadeCurve, crossfadeCurve) ||
                other.crossfadeCurve == crossfadeCurve) &&
            (identical(other.normalizationLevel, normalizationLevel) ||
                other.normalizationLevel == normalizationLevel) &&
            (identical(other.normalizationEnabled, normalizationEnabled) ||
                other.normalizationEnabled == normalizationEnabled) &&
            (identical(other.pitchShift, pitchShift) ||
                other.pitchShift == pitchShift) &&
            (identical(other.reverbMix, reverbMix) ||
                other.reverbMix == reverbMix) &&
            (identical(other.reverbRoomSize, reverbRoomSize) ||
                other.reverbRoomSize == reverbRoomSize) &&
            (identical(other.reverbDamp, reverbDamp) ||
                other.reverbDamp == reverbDamp) &&
            (identical(other.compressionRatio, compressionRatio) ||
                other.compressionRatio == compressionRatio) &&
            (identical(other.compThreshold, compThreshold) ||
                other.compThreshold == compThreshold) &&
            (identical(other.compAttack, compAttack) ||
                other.compAttack == compAttack) &&
            (identical(other.compRelease, compRelease) ||
                other.compRelease == compRelease) &&
            (identical(other.compKneeWidth, compKneeWidth) ||
                other.compKneeWidth == compKneeWidth) &&
            (identical(other.compMakeupGain, compMakeupGain) ||
                other.compMakeupGain == compMakeupGain) &&
            (identical(other.sortMode, sortMode) ||
                other.sortMode == sortMode) &&
            (identical(other.sortAscending, sortAscending) ||
                other.sortAscending == sortAscending) &&
            (identical(other.desktopLyricsEnabled, desktopLyricsEnabled) ||
                other.desktopLyricsEnabled == desktopLyricsEnabled) &&
            (identical(other.desktopLyricsFontSize, desktopLyricsFontSize) ||
                other.desktopLyricsFontSize == desktopLyricsFontSize) &&
            (identical(other.desktopLyricsOpacity, desktopLyricsOpacity) ||
                other.desktopLyricsOpacity == desktopLyricsOpacity) &&
            (identical(
                  other.desktopLyricsClickThrough,
                  desktopLyricsClickThrough,
                ) ||
                other.desktopLyricsClickThrough == desktopLyricsClickThrough) &&
            (identical(other.lyricFontSize, lyricFontSize) ||
                other.lyricFontSize == lyricFontSize) &&
            (identical(other.visualizerEnabled, visualizerEnabled) ||
                other.visualizerEnabled == visualizerEnabled) &&
            (identical(other.visualizerShape, visualizerShape) ||
                other.visualizerShape == visualizerShape) &&
            const DeepCollectionEquality().equals(
              other._customHotkeys,
              _customHotkeys,
            ) &&
            (identical(other.mediaKeyEnabled, mediaKeyEnabled) ||
                other.mediaKeyEnabled == mediaKeyEnabled) &&
            (identical(other.soundFeedbackEnabled, soundFeedbackEnabled) ||
                other.soundFeedbackEnabled == soundFeedbackEnabled) &&
            (identical(other.minimizeToTray, minimizeToTray) ||
                other.minimizeToTray == minimizeToTray) &&
            (identical(other.sensitivity, sensitivity) ||
                other.sensitivity == sensitivity) &&
            (identical(other.customBackgroundImage, customBackgroundImage) ||
                other.customBackgroundImage == customBackgroundImage));
  }

  @override
  int get hashCode => Object.hashAll([
    runtimeType,
    themeMode,
    enableBlur,
    blurLevel,
    useNativeWindowEffect,
    windowOpacity,
    useDynamicColor,
    customPrimaryColor,
    dynamicPrimaryColor,
    isMiniPlayer,
    isGridView,
    sidebarCollapsed,
    currentTabIndex,
    const DeepCollectionEquality().hash(_eqBands),
    eqBassLevel,
    eqPreset,
    crossfadeDuration,
    crossfadeCurve,
    normalizationLevel,
    normalizationEnabled,
    pitchShift,
    reverbMix,
    reverbRoomSize,
    reverbDamp,
    compressionRatio,
    compThreshold,
    compAttack,
    compRelease,
    compKneeWidth,
    compMakeupGain,
    sortMode,
    sortAscending,
    desktopLyricsEnabled,
    desktopLyricsFontSize,
    desktopLyricsOpacity,
    desktopLyricsClickThrough,
    lyricFontSize,
    visualizerEnabled,
    visualizerShape,
    const DeepCollectionEquality().hash(_customHotkeys),
    mediaKeyEnabled,
    soundFeedbackEnabled,
    minimizeToTray,
    sensitivity,
    customBackgroundImage,
  ]);

  /// Create a copy of SettingsState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SettingsStateImplCopyWith<_$SettingsStateImpl> get copyWith =>
      __$$SettingsStateImplCopyWithImpl<_$SettingsStateImpl>(this, _$identity);
}

abstract class _SettingsState implements SettingsState {
  const factory _SettingsState({
    final ThemeMode themeMode,
    final bool enableBlur,
    final double blurLevel,
    final bool useNativeWindowEffect,
    final double windowOpacity,
    final bool useDynamicColor,
    final Color customPrimaryColor,
    final Color? dynamicPrimaryColor,
    final bool isMiniPlayer,
    final bool isGridView,
    final bool sidebarCollapsed,
    final int currentTabIndex,
    final List<double> eqBands,
    final int eqBassLevel,
    final String eqPreset,
    final double crossfadeDuration,
    final int crossfadeCurve,
    final double normalizationLevel,
    final bool normalizationEnabled,
    final double pitchShift,
    final double reverbMix,
    final double reverbRoomSize,
    final double reverbDamp,
    final double compressionRatio,
    final double compThreshold,
    final double compAttack,
    final double compRelease,
    final double compKneeWidth,
    final double compMakeupGain,
    final int sortMode,
    final bool sortAscending,
    final bool desktopLyricsEnabled,
    final double desktopLyricsFontSize,
    final double desktopLyricsOpacity,
    final bool desktopLyricsClickThrough,
    final double lyricFontSize,
    final bool visualizerEnabled,
    final int visualizerShape,
    final Map<String, String> customHotkeys,
    final bool mediaKeyEnabled,
    final bool soundFeedbackEnabled,
    final bool minimizeToTray,
    final double sensitivity,
    final String? customBackgroundImage,
  }) = _$SettingsStateImpl;

  // ─── Theme ──────────────────────────────────────────────────────
  @override
  ThemeMode get themeMode;
  @override
  bool get enableBlur;
  @override
  double get blurLevel;
  @override
  bool get useNativeWindowEffect;
  @override
  double get windowOpacity;
  @override
  bool get useDynamicColor;
  @override
  Color get customPrimaryColor;
  @override
  Color? get dynamicPrimaryColor; // ─── Window & Layout ────────────────────────────────────────────
  @override
  bool get isMiniPlayer;
  @override
  bool get isGridView;
  @override
  bool get sidebarCollapsed;
  @override
  int get currentTabIndex; // ─── Equalizer ──────────────────────────────────────────────────
  @override
  List<double> get eqBands;
  @override
  int get eqBassLevel;
  @override
  String get eqPreset; // ─── Audio Effects ──────────────────────────────────────────────
  @override
  double get crossfadeDuration;
  @override
  int get crossfadeCurve; // 0=linear, 1=exponential, 2=sCurve
  @override
  double get normalizationLevel;
  @override
  bool get normalizationEnabled;
  @override
  double get pitchShift;
  @override
  double get reverbMix;
  @override
  double get reverbRoomSize;
  @override
  double get reverbDamp;
  @override
  double get compressionRatio;
  @override
  double get compThreshold;
  @override
  double get compAttack;
  @override
  double get compRelease;
  @override
  double get compKneeWidth;
  @override
  double get compMakeupGain; // ─── Sort & Filter ──────────────────────────────────────────────
  @override
  int get sortMode;
  @override
  bool get sortAscending; // ─── Desktop Lyrics ─────────────────────────────────────────────
  @override
  bool get desktopLyricsEnabled;
  @override
  double get desktopLyricsFontSize;
  @override
  double get desktopLyricsOpacity;
  @override
  bool get desktopLyricsClickThrough; // ─── In-app Lyric ──────────────────────────────────────────────
  @override
  double get lyricFontSize; // ─── Visualizer ─────────────────────────────────────────────────
  @override
  bool get visualizerEnabled;
  @override
  int get visualizerShape; // ─── Hotkeys & Media ────────────────────────────────────────────
  @override
  Map<String, String> get customHotkeys;
  @override
  bool get mediaKeyEnabled; // ─── Feedback (Phase 4) ──────────────────────────────────────────
  @override
  bool get soundFeedbackEnabled; // ─── Other ──────────────────────────────────────────────────────
  @override
  bool get minimizeToTray;
  @override
  double get sensitivity;
  @override
  String? get customBackgroundImage;

  /// Create a copy of SettingsState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SettingsStateImplCopyWith<_$SettingsStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
