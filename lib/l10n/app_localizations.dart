import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_vi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('vi')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'G.A - Song'**
  String get appTitle;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @library.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get library;

  /// No description provided for @online.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get online;

  /// No description provided for @ktv.
  ///
  /// In en, this message translates to:
  /// **'KTV'**
  String get ktv;

  /// No description provided for @personal.
  ///
  /// In en, this message translates to:
  /// **'Personal'**
  String get personal;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @play.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get play;

  /// No description provided for @pause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pause;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @previous.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get previous;

  /// No description provided for @shuffle.
  ///
  /// In en, this message translates to:
  /// **'Shuffle'**
  String get shuffle;

  /// No description provided for @repeat.
  ///
  /// In en, this message translates to:
  /// **'Repeat'**
  String get repeat;

  /// No description provided for @repeatOne.
  ///
  /// In en, this message translates to:
  /// **'Repeat One'**
  String get repeatOne;

  /// No description provided for @playOneStop.
  ///
  /// In en, this message translates to:
  /// **'Play One Stop'**
  String get playOneStop;

  /// No description provided for @noSongSelected.
  ///
  /// In en, this message translates to:
  /// **'No song selected'**
  String get noSongSelected;

  /// No description provided for @noLyrics.
  ///
  /// In en, this message translates to:
  /// **'No lyrics available'**
  String get noLyrics;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @import.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get import;

  /// No description provided for @addToPlaylist.
  ///
  /// In en, this message translates to:
  /// **'Add to playlist'**
  String get addToPlaylist;

  /// No description provided for @createPlaylist.
  ///
  /// In en, this message translates to:
  /// **'Create playlist'**
  String get createPlaylist;

  /// No description provided for @deletePlaylist.
  ///
  /// In en, this message translates to:
  /// **'Delete playlist'**
  String get deletePlaylist;

  /// No description provided for @favorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get favorites;

  /// No description provided for @speed.
  ///
  /// In en, this message translates to:
  /// **'Playback speed'**
  String get speed;

  /// No description provided for @equalizer.
  ///
  /// In en, this message translates to:
  /// **'Equalizer'**
  String get equalizer;

  /// No description provided for @sleepTimer.
  ///
  /// In en, this message translates to:
  /// **'Sleep timer'**
  String get sleepTimer;

  /// No description provided for @volume.
  ///
  /// In en, this message translates to:
  /// **'Volume'**
  String get volume;

  /// No description provided for @lyrics.
  ///
  /// In en, this message translates to:
  /// **'Lyrics'**
  String get lyrics;

  /// No description provided for @miniPlayer.
  ///
  /// In en, this message translates to:
  /// **'Mini player'**
  String get miniPlayer;

  /// No description provided for @pip.
  ///
  /// In en, this message translates to:
  /// **'Picture in picture'**
  String get pip;

  /// No description provided for @errorInit.
  ///
  /// In en, this message translates to:
  /// **'Audio Engine initialization error'**
  String get errorInit;

  /// No description provided for @errorRestart.
  ///
  /// In en, this message translates to:
  /// **'Please restart the application'**
  String get errorRestart;

  /// No description provided for @renderError.
  ///
  /// In en, this message translates to:
  /// **'An error occurred while rendering the interface'**
  String get renderError;

  /// No description provided for @permissionMic.
  ///
  /// In en, this message translates to:
  /// **'Microphone permission is required for KTV!'**
  String get permissionMic;

  /// No description provided for @permissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Microphone permission denied. Please grant it in Settings.'**
  String get permissionDenied;

  /// No description provided for @greetingMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning,'**
  String get greetingMorning;

  /// No description provided for @greetingAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon,'**
  String get greetingAfternoon;

  /// No description provided for @greetingEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening,'**
  String get greetingEvening;

  /// No description provided for @musicRoom.
  ///
  /// In en, this message translates to:
  /// **'MUSIC ROOM'**
  String get musicRoom;

  /// No description provided for @synced.
  ///
  /// In en, this message translates to:
  /// **'Synced'**
  String get synced;

  /// No description provided for @offsetReset.
  ///
  /// In en, this message translates to:
  /// **'Reset offset'**
  String get offsetReset;

  /// No description provided for @noPlaylist.
  ///
  /// In en, this message translates to:
  /// **'No playlists yet'**
  String get noPlaylist;

  /// No description provided for @addAlbumField.
  ///
  /// In en, this message translates to:
  /// **'Add \"album\" field to songs.json to create playlists'**
  String get addAlbumField;

  /// No description provided for @noSongPlaying.
  ///
  /// In en, this message translates to:
  /// **'No song is currently playing'**
  String get noSongPlaying;

  /// No description provided for @exitMusicRoom.
  ///
  /// In en, this message translates to:
  /// **'Exit music room'**
  String get exitMusicRoom;

  /// No description provided for @closeMiniPlayer.
  ///
  /// In en, this message translates to:
  /// **'Close mini player'**
  String get closeMiniPlayer;

  /// No description provided for @restoreNormal.
  ///
  /// In en, this message translates to:
  /// **'Restore normal view'**
  String get restoreNormal;

  /// No description provided for @find.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get find;

  /// No description provided for @nowPlaying.
  ///
  /// In en, this message translates to:
  /// **'Now playing'**
  String get nowPlaying;

  /// No description provided for @guide.
  ///
  /// In en, this message translates to:
  /// **'Guide'**
  String get guide;

  /// No description provided for @guideContent.
  ///
  /// In en, this message translates to:
  /// **'Help you listen to any song from YouTube.\n\nPaste a YouTube link in the search box and press Search.'**
  String get guideContent;

  /// No description provided for @playing.
  ///
  /// In en, this message translates to:
  /// **'Playing'**
  String get playing;

  /// No description provided for @hideVideo.
  ///
  /// In en, this message translates to:
  /// **'Hide Video (Audio only)'**
  String get hideVideo;

  /// No description provided for @showVideo.
  ///
  /// In en, this message translates to:
  /// **'Show Video'**
  String get showVideo;

  /// No description provided for @importError.
  ///
  /// In en, this message translates to:
  /// **'Import error'**
  String get importError;

  /// No description provided for @unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// No description provided for @bassBoost.
  ///
  /// In en, this message translates to:
  /// **'Bass Boost'**
  String get bassBoost;

  /// No description provided for @reverb.
  ///
  /// In en, this message translates to:
  /// **'Reverb'**
  String get reverb;

  /// No description provided for @compressor.
  ///
  /// In en, this message translates to:
  /// **'Compressor'**
  String get compressor;

  /// No description provided for @normalization.
  ///
  /// In en, this message translates to:
  /// **'Normalization'**
  String get normalization;

  /// No description provided for @pitchShift.
  ///
  /// In en, this message translates to:
  /// **'Pitch Shift'**
  String get pitchShift;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @sortBy.
  ///
  /// In en, this message translates to:
  /// **'Sort by'**
  String get sortBy;

  /// No description provided for @sortByName.
  ///
  /// In en, this message translates to:
  /// **'By name'**
  String get sortByName;

  /// No description provided for @sortByArtist.
  ///
  /// In en, this message translates to:
  /// **'By artist'**
  String get sortByArtist;

  /// No description provided for @sortByAlbum.
  ///
  /// In en, this message translates to:
  /// **'By album'**
  String get sortByAlbum;

  /// No description provided for @sortByDate.
  ///
  /// In en, this message translates to:
  /// **'By date added'**
  String get sortByDate;

  /// No description provided for @sortByDuration.
  ///
  /// In en, this message translates to:
  /// **'By duration'**
  String get sortByDuration;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @audio.
  ///
  /// In en, this message translates to:
  /// **'Audio'**
  String get audio;

  /// No description provided for @shortcuts.
  ///
  /// In en, this message translates to:
  /// **'Shortcuts'**
  String get shortcuts;

  /// No description provided for @advanced.
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get advanced;

  /// No description provided for @noSongsYet.
  ///
  /// In en, this message translates to:
  /// **'No songs yet'**
  String get noSongsYet;

  /// No description provided for @addSongsHint.
  ///
  /// In en, this message translates to:
  /// **'Add music files to assets/song/\nand update songs.json'**
  String get addSongsHint;

  /// No description provided for @cannotLoadLibrary.
  ///
  /// In en, this message translates to:
  /// **'Cannot load music library'**
  String get cannotLoadLibrary;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @allSongs.
  ///
  /// In en, this message translates to:
  /// **'All songs'**
  String get allSongs;

  /// No description provided for @songCount.
  ///
  /// In en, this message translates to:
  /// **'{count} songs'**
  String songCount(int count);

  /// No description provided for @importSuccess.
  ///
  /// In en, this message translates to:
  /// **'Import successful!'**
  String get importSuccess;

  /// No description provided for @importErrorWithMsg.
  ///
  /// In en, this message translates to:
  /// **'Import error: {error}'**
  String importErrorWithMsg(String error);

  /// No description provided for @androidOnlyFeature.
  ///
  /// In en, this message translates to:
  /// **'This feature is only available on Android devices.'**
  String get androidOnlyFeature;

  /// No description provided for @cannotLoadLibraryDb.
  ///
  /// In en, this message translates to:
  /// **'Cannot load song list from Database.'**
  String get cannotLoadLibraryDb;

  /// No description provided for @categoryAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get categoryAppearance;

  /// No description provided for @categoryPlayback.
  ///
  /// In en, this message translates to:
  /// **'Playback'**
  String get categoryPlayback;

  /// No description provided for @categoryVisualizer.
  ///
  /// In en, this message translates to:
  /// **'Visualizer'**
  String get categoryVisualizer;

  /// No description provided for @categoryLyrics.
  ///
  /// In en, this message translates to:
  /// **'Lyrics'**
  String get categoryLyrics;

  /// No description provided for @categoryWindowSystem.
  ///
  /// In en, this message translates to:
  /// **'Window & System'**
  String get categoryWindowSystem;

  /// No description provided for @categoryHotkeys.
  ///
  /// In en, this message translates to:
  /// **'Hotkeys'**
  String get categoryHotkeys;

  /// No description provided for @categorySleepTimer.
  ///
  /// In en, this message translates to:
  /// **'Sleep Timer'**
  String get categorySleepTimer;

  /// No description provided for @categoryAdvanced.
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get categoryAdvanced;

  /// No description provided for @categoryFeedback.
  ///
  /// In en, this message translates to:
  /// **'Feedback'**
  String get categoryFeedback;

  /// No description provided for @themeMode.
  ///
  /// In en, this message translates to:
  /// **'Theme Mode'**
  String get themeMode;

  /// No description provided for @useDynamicColor.
  ///
  /// In en, this message translates to:
  /// **'Dynamic Color'**
  String get useDynamicColor;

  /// No description provided for @customPrimaryColor.
  ///
  /// In en, this message translates to:
  /// **'Custom Primary Color'**
  String get customPrimaryColor;

  /// No description provided for @enableBlur.
  ///
  /// In en, this message translates to:
  /// **'Enable Blur'**
  String get enableBlur;

  /// No description provided for @blurLevel.
  ///
  /// In en, this message translates to:
  /// **'Blur Level'**
  String get blurLevel;

  /// No description provided for @useNativeWindowEffect.
  ///
  /// In en, this message translates to:
  /// **'Native Window Effect'**
  String get useNativeWindowEffect;

  /// No description provided for @windowOpacity.
  ///
  /// In en, this message translates to:
  /// **'Window Opacity'**
  String get windowOpacity;

  /// No description provided for @isGridView.
  ///
  /// In en, this message translates to:
  /// **'Grid View'**
  String get isGridView;

  /// No description provided for @customBackgroundImage.
  ///
  /// In en, this message translates to:
  /// **'Custom Background Image'**
  String get customBackgroundImage;

  /// No description provided for @crossfadeDuration.
  ///
  /// In en, this message translates to:
  /// **'Crossfade Duration'**
  String get crossfadeDuration;

  /// No description provided for @crossfadeCurve.
  ///
  /// In en, this message translates to:
  /// **'Crossfade Curve'**
  String get crossfadeCurve;

  /// No description provided for @normalizationLevel.
  ///
  /// In en, this message translates to:
  /// **'Normalization Level'**
  String get normalizationLevel;

  /// No description provided for @eqBass.
  ///
  /// In en, this message translates to:
  /// **'Bass'**
  String get eqBass;

  /// No description provided for @visualizerEnabled.
  ///
  /// In en, this message translates to:
  /// **'Visualizer Enabled'**
  String get visualizerEnabled;

  /// No description provided for @visualizerShape.
  ///
  /// In en, this message translates to:
  /// **'Visualizer Shape'**
  String get visualizerShape;

  /// No description provided for @sensitivity.
  ///
  /// In en, this message translates to:
  /// **'Sensitivity'**
  String get sensitivity;

  /// No description provided for @lyricsFontSize.
  ///
  /// In en, this message translates to:
  /// **'Lyrics Font Size'**
  String get lyricsFontSize;

  /// No description provided for @showLyricsInMiniPlayer.
  ///
  /// In en, this message translates to:
  /// **'Show Lyrics in Mini Player'**
  String get showLyricsInMiniPlayer;

  /// No description provided for @autoFetchLyrics.
  ///
  /// In en, this message translates to:
  /// **'Auto-Fetch Lyrics'**
  String get autoFetchLyrics;

  /// No description provided for @minimizeToTray.
  ///
  /// In en, this message translates to:
  /// **'Minimize to Tray'**
  String get minimizeToTray;

  /// No description provided for @autoHidePlayerBar.
  ///
  /// In en, this message translates to:
  /// **'Auto-Hide Player Bar'**
  String get autoHidePlayerBar;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @customHotkeys.
  ///
  /// In en, this message translates to:
  /// **'Custom Hotkeys'**
  String get customHotkeys;

  /// No description provided for @mediaKeyEnabled.
  ///
  /// In en, this message translates to:
  /// **'Media Keys'**
  String get mediaKeyEnabled;

  /// No description provided for @sleepTimerDuration.
  ///
  /// In en, this message translates to:
  /// **'Sleep Timer Duration'**
  String get sleepTimerDuration;

  /// No description provided for @sleepTimerFadeOut.
  ///
  /// In en, this message translates to:
  /// **'Sleep Timer Fade Out'**
  String get sleepTimerFadeOut;

  /// No description provided for @stopAtEndOfSong.
  ///
  /// In en, this message translates to:
  /// **'Stop at End of Song'**
  String get stopAtEndOfSong;

  /// No description provided for @reverbRoomSize.
  ///
  /// In en, this message translates to:
  /// **'Reverb Room Size'**
  String get reverbRoomSize;

  /// No description provided for @compressorThreshold.
  ///
  /// In en, this message translates to:
  /// **'Compressor Threshold'**
  String get compressorThreshold;

  /// No description provided for @compressorAttack.
  ///
  /// In en, this message translates to:
  /// **'Compressor Attack'**
  String get compressorAttack;

  /// No description provided for @compressorRelease.
  ///
  /// In en, this message translates to:
  /// **'Compressor Release'**
  String get compressorRelease;

  /// No description provided for @compressorKneeWidth.
  ///
  /// In en, this message translates to:
  /// **'Compressor Knee Width'**
  String get compressorKneeWidth;

  /// No description provided for @compressorMakeupGain.
  ///
  /// In en, this message translates to:
  /// **'Compressor Makeup Gain'**
  String get compressorMakeupGain;

  /// No description provided for @reverbDamp.
  ///
  /// In en, this message translates to:
  /// **'Reverb Damping'**
  String get reverbDamp;

  /// No description provided for @soundFeedbackEnabled.
  ///
  /// In en, this message translates to:
  /// **'Sound Feedback'**
  String get soundFeedbackEnabled;

  /// No description provided for @hapticFeedbackEnabled.
  ///
  /// In en, this message translates to:
  /// **'Haptic Feedback'**
  String get hapticFeedbackEnabled;

  /// No description provided for @manageHotkeys.
  ///
  /// In en, this message translates to:
  /// **'Manage hotkey bindings'**
  String get manageHotkeys;

  /// No description provided for @searchSettings.
  ///
  /// In en, this message translates to:
  /// **'Search settings...'**
  String get searchSettings;

  /// No description provided for @noSettingsFound.
  ///
  /// In en, this message translates to:
  /// **'No settings found'**
  String get noSettingsFound;

  /// No description provided for @pressCtrlKToSearch.
  ///
  /// In en, this message translates to:
  /// **'Press Ctrl+K to search settings'**
  String get pressCtrlKToSearch;

  /// No description provided for @enabled.
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get enabled;

  /// No description provided for @disabled.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get disabled;

  /// No description provided for @off.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get off;

  /// No description provided for @minutes.
  ///
  /// In en, this message translates to:
  /// **'minutes'**
  String get minutes;

  /// No description provided for @seconds.
  ///
  /// In en, this message translates to:
  /// **'seconds'**
  String get seconds;

  /// No description provided for @endOfSong.
  ///
  /// In en, this message translates to:
  /// **'End of song'**
  String get endOfSong;

  /// No description provided for @set.
  ///
  /// In en, this message translates to:
  /// **'Set'**
  String get set;

  /// No description provided for @notSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get notSet;

  /// No description provided for @none.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get none;

  /// No description provided for @light.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get light;

  /// No description provided for @dark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get dark;

  /// No description provided for @system.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get system;

  /// No description provided for @linear.
  ///
  /// In en, this message translates to:
  /// **'Linear'**
  String get linear;

  /// No description provided for @exponential.
  ///
  /// In en, this message translates to:
  /// **'Exponential'**
  String get exponential;

  /// No description provided for @sCurve.
  ///
  /// In en, this message translates to:
  /// **'S-Curve'**
  String get sCurve;

  /// No description provided for @visualizerShapeCircle.
  ///
  /// In en, this message translates to:
  /// **'Circle'**
  String get visualizerShapeCircle;

  /// No description provided for @visualizerShapeBars.
  ///
  /// In en, this message translates to:
  /// **'Bars'**
  String get visualizerShapeBars;

  /// No description provided for @visualizerShapeWave.
  ///
  /// In en, this message translates to:
  /// **'Wave'**
  String get visualizerShapeWave;

  /// No description provided for @visualizerShapeTunnel.
  ///
  /// In en, this message translates to:
  /// **'Tunnel'**
  String get visualizerShapeTunnel;

  /// No description provided for @visualizerShapeStarfield.
  ///
  /// In en, this message translates to:
  /// **'Starfield'**
  String get visualizerShapeStarfield;

  /// No description provided for @visualizerShapeOscilloscope.
  ///
  /// In en, this message translates to:
  /// **'Oscilloscope'**
  String get visualizerShapeOscilloscope;

  /// No description provided for @visualizerShapeRadial.
  ///
  /// In en, this message translates to:
  /// **'Radial Burst'**
  String get visualizerShapeRadial;

  /// No description provided for @emptyLibraryTitle.
  ///
  /// In en, this message translates to:
  /// **'Your library is empty'**
  String get emptyLibraryTitle;

  /// No description provided for @emptyLibraryMessage.
  ///
  /// In en, this message translates to:
  /// **'Import local music files, scan for music, or create a playlist to get started.'**
  String get emptyLibraryMessage;

  /// No description provided for @importMusic.
  ///
  /// In en, this message translates to:
  /// **'Import Music'**
  String get importMusic;

  /// No description provided for @scanForMusic.
  ///
  /// In en, this message translates to:
  /// **'Scan for Music'**
  String get scanForMusic;

  /// No description provided for @addSongs.
  ///
  /// In en, this message translates to:
  /// **'Add Songs'**
  String get addSongs;

  /// No description provided for @importPlaylist.
  ///
  /// In en, this message translates to:
  /// **'Import Playlist'**
  String get importPlaylist;

  /// No description provided for @emptyPlaylistTitle.
  ///
  /// In en, this message translates to:
  /// **'This playlist is empty'**
  String get emptyPlaylistTitle;

  /// No description provided for @emptyPlaylistMessage.
  ///
  /// In en, this message translates to:
  /// **'No songs in {playlistName} yet. Add songs to get started.'**
  String emptyPlaylistMessage(String playlistName);

  /// No description provided for @noResultsTitle.
  ///
  /// In en, this message translates to:
  /// **'No results found'**
  String get noResultsTitle;

  /// No description provided for @noResultsMessage.
  ///
  /// In en, this message translates to:
  /// **'No matches found for \"{query}\"'**
  String noResultsMessage(String query);

  /// No description provided for @clearSearch.
  ///
  /// In en, this message translates to:
  /// **'Clear Search'**
  String get clearSearch;

  /// No description provided for @errorLoadingTitle.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get errorLoadingTitle;

  /// No description provided for @noInternetTitle.
  ///
  /// In en, this message translates to:
  /// **'No Internet Connection'**
  String get noInternetTitle;

  /// No description provided for @noInternetMessage.
  ///
  /// In en, this message translates to:
  /// **'Check your connection and try again.'**
  String get noInternetMessage;

  /// No description provided for @openNetworkSettings.
  ///
  /// In en, this message translates to:
  /// **'Open Network Settings'**
  String get openNetworkSettings;

  /// No description provided for @featureComingSoon.
  ///
  /// In en, this message translates to:
  /// **'This feature is coming soon'**
  String get featureComingSoon;

  /// No description provided for @scanComplete.
  ///
  /// In en, this message translates to:
  /// **'Scan complete'**
  String get scanComplete;

  /// No description provided for @songsFound.
  ///
  /// In en, this message translates to:
  /// **'songs found'**
  String get songsFound;

  /// No description provided for @languageVietnamese.
  ///
  /// In en, this message translates to:
  /// **'Tiếng Việt'**
  String get languageVietnamese;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'vi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'vi': return AppLocalizationsVi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
