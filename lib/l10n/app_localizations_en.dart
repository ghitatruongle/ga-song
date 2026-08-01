// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'G.A - Song';

  @override
  String get home => 'Home';

  @override
  String get library => 'Library';

  @override
  String get online => 'Online';

  @override
  String get ktv => 'KTV';

  @override
  String get personal => 'Personal';

  @override
  String get settings => 'Settings';

  @override
  String get play => 'Play';

  @override
  String get pause => 'Pause';

  @override
  String get next => 'Next';

  @override
  String get previous => 'Previous';

  @override
  String get shuffle => 'Shuffle';

  @override
  String get repeat => 'Repeat';

  @override
  String get repeatOne => 'Repeat One';

  @override
  String get playOneStop => 'Play One Stop';

  @override
  String get noSongSelected => 'No song selected';

  @override
  String get noLyrics => 'No lyrics available';

  @override
  String get search => 'Search';

  @override
  String get import => 'Import';

  @override
  String get addToPlaylist => 'Add to playlist';

  @override
  String get createPlaylist => 'Create playlist';

  @override
  String get deletePlaylist => 'Delete playlist';

  @override
  String get favorites => 'Favorites';

  @override
  String get speed => 'Playback speed';

  @override
  String get equalizer => 'Equalizer';

  @override
  String get sleepTimer => 'Sleep timer';

  @override
  String get volume => 'Volume';

  @override
  String get lyrics => 'Lyrics';

  @override
  String get miniPlayer => 'Mini player';

  @override
  String get pip => 'Picture in picture';

  @override
  String get errorInit => 'Audio Engine initialization error';

  @override
  String get errorRestart => 'Please restart the application';

  @override
  String get renderError => 'An error occurred while rendering the interface';

  @override
  String get permissionMic => 'Microphone permission is required for KTV!';

  @override
  String get permissionDenied => 'Microphone permission denied. Please grant it in Settings.';

  @override
  String get greetingMorning => 'Good morning,';

  @override
  String get greetingAfternoon => 'Good afternoon,';

  @override
  String get greetingEvening => 'Good evening,';

  @override
  String get musicRoom => 'MUSIC ROOM';

  @override
  String get synced => 'Synced';

  @override
  String get offsetReset => 'Reset offset';

  @override
  String get noPlaylist => 'No playlists yet';

  @override
  String get addAlbumField => 'Add \"album\" field to songs.json to create playlists';

  @override
  String get noSongPlaying => 'No song is currently playing';

  @override
  String get exitMusicRoom => 'Exit music room';

  @override
  String get closeMiniPlayer => 'Close mini player';

  @override
  String get restoreNormal => 'Restore normal view';

  @override
  String get find => 'Search';

  @override
  String get nowPlaying => 'Now playing';

  @override
  String get guide => 'Guide';

  @override
  String get guideContent => 'Help you listen to any song from YouTube.\n\nPaste a YouTube link in the search box and press Search.';

  @override
  String get playing => 'Playing';

  @override
  String get hideVideo => 'Hide Video (Audio only)';

  @override
  String get showVideo => 'Show Video';

  @override
  String get importError => 'Import error';

  @override
  String get unknown => 'Unknown';

  @override
  String get bassBoost => 'Bass Boost';

  @override
  String get reverb => 'Reverb';

  @override
  String get compressor => 'Compressor';

  @override
  String get normalization => 'Normalization';

  @override
  String get pitchShift => 'Pitch Shift';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String get confirm => 'Confirm';

  @override
  String get sortBy => 'Sort by';

  @override
  String get sortByName => 'By name';

  @override
  String get sortByArtist => 'By artist';

  @override
  String get sortByAlbum => 'By album';

  @override
  String get sortByDate => 'By date added';

  @override
  String get sortByDuration => 'By duration';

  @override
  String get appearance => 'Appearance';

  @override
  String get audio => 'Audio';

  @override
  String get shortcuts => 'Shortcuts';

  @override
  String get advanced => 'Advanced';

  @override
  String get noSongsYet => 'No songs yet';

  @override
  String get addSongsHint => 'Add music files to assets/song/\nand update songs.json';

  @override
  String get cannotLoadLibrary => 'Cannot load music library';

  @override
  String get retry => 'Retry';

  @override
  String get allSongs => 'All songs';

  @override
  String songCount(int count) {
    return '$count songs';
  }

  @override
  String get importSuccess => 'Import successful!';

  @override
  String importErrorWithMsg(String error) {
    return 'Import error: $error';
  }

  @override
  String get androidOnlyFeature => 'This feature is only available on Android devices.';

  @override
  String get cannotLoadLibraryDb => 'Cannot load song list from Database.';

  @override
  String get categoryAppearance => 'Appearance';

  @override
  String get categoryPlayback => 'Playback';

  @override
  String get categoryVisualizer => 'Visualizer';

  @override
  String get categoryLyrics => 'Lyrics';

  @override
  String get categoryWindowSystem => 'Window & System';

  @override
  String get categoryHotkeys => 'Hotkeys';

  @override
  String get categorySleepTimer => 'Sleep Timer';

  @override
  String get categoryAdvanced => 'Advanced';

  @override
  String get categoryFeedback => 'Feedback';

  @override
  String get themeMode => 'Theme Mode';

  @override
  String get useDynamicColor => 'Dynamic Color';

  @override
  String get customPrimaryColor => 'Custom Primary Color';

  @override
  String get enableBlur => 'Enable Blur';

  @override
  String get blurLevel => 'Blur Level';

  @override
  String get useNativeWindowEffect => 'Native Window Effect';

  @override
  String get windowOpacity => 'Window Opacity';

  @override
  String get isGridView => 'Grid View';

  @override
  String get customBackgroundImage => 'Custom Background Image';

  @override
  String get crossfadeDuration => 'Crossfade Duration';

  @override
  String get crossfadeCurve => 'Crossfade Curve';

  @override
  String get normalizationLevel => 'Normalization Level';

  @override
  String get eqBass => 'Bass';

  @override
  String get visualizerEnabled => 'Visualizer Enabled';

  @override
  String get visualizerShape => 'Visualizer Shape';

  @override
  String get sensitivity => 'Sensitivity';

  @override
  String get lyricsFontSize => 'Lyrics Font Size';

  @override
  String get showLyricsInMiniPlayer => 'Show Lyrics in Mini Player';

  @override
  String get autoFetchLyrics => 'Auto-Fetch Lyrics';

  @override
  String get minimizeToTray => 'Minimize to Tray';

  @override
  String get autoHidePlayerBar => 'Auto-Hide Player Bar';

  @override
  String get language => 'Language';

  @override
  String get customHotkeys => 'Custom Hotkeys';

  @override
  String get mediaKeyEnabled => 'Media Keys';

  @override
  String get sleepTimerDuration => 'Sleep Timer Duration';

  @override
  String get sleepTimerFadeOut => 'Sleep Timer Fade Out';

  @override
  String get stopAtEndOfSong => 'Stop at End of Song';

  @override
  String get reverbRoomSize => 'Reverb Room Size';

  @override
  String get compressorThreshold => 'Compressor Threshold';

  @override
  String get compressorAttack => 'Compressor Attack';

  @override
  String get compressorRelease => 'Compressor Release';

  @override
  String get compressorKneeWidth => 'Compressor Knee Width';

  @override
  String get compressorMakeupGain => 'Compressor Makeup Gain';

  @override
  String get reverbDamp => 'Reverb Damping';

  @override
  String get soundFeedbackEnabled => 'Sound Feedback';

  @override
  String get hapticFeedbackEnabled => 'Haptic Feedback';

  @override
  String get manageHotkeys => 'Manage hotkey bindings';

  @override
  String get searchSettings => 'Search settings...';

  @override
  String get noSettingsFound => 'No settings found';

  @override
  String get pressCtrlKToSearch => 'Press Ctrl+K to search settings';

  @override
  String get enabled => 'Enabled';

  @override
  String get disabled => 'Disabled';

  @override
  String get off => 'Off';

  @override
  String get minutes => 'minutes';

  @override
  String get seconds => 'seconds';

  @override
  String get endOfSong => 'End of song';

  @override
  String get set => 'Set';

  @override
  String get notSet => 'Not set';

  @override
  String get none => 'None';

  @override
  String get light => 'Light';

  @override
  String get dark => 'Dark';

  @override
  String get system => 'System';

  @override
  String get linear => 'Linear';

  @override
  String get exponential => 'Exponential';

  @override
  String get sCurve => 'S-Curve';

  @override
  String get visualizerShapeCircle => 'Circle';

  @override
  String get visualizerShapeBars => 'Bars';

  @override
  String get visualizerShapeWave => 'Wave';

  @override
  String get visualizerShapeTunnel => 'Tunnel';

  @override
  String get visualizerShapeStarfield => 'Starfield';

  @override
  String get visualizerShapeOscilloscope => 'Oscilloscope';

  @override
  String get visualizerShapeRadial => 'Radial Burst';

  @override
  String get emptyLibraryTitle => 'Your library is empty';

  @override
  String get emptyLibraryMessage => 'Import local music files, scan for music, or create a playlist to get started.';

  @override
  String get importMusic => 'Import Music';

  @override
  String get scanForMusic => 'Scan for Music';

  @override
  String get addSongs => 'Add Songs';

  @override
  String get importPlaylist => 'Import Playlist';

  @override
  String get emptyPlaylistTitle => 'This playlist is empty';

  @override
  String emptyPlaylistMessage(String playlistName) {
    return 'No songs in $playlistName yet. Add songs to get started.';
  }

  @override
  String get noResultsTitle => 'No results found';

  @override
  String noResultsMessage(String query) {
    return 'No matches found for \"$query\"';
  }

  @override
  String get clearSearch => 'Clear Search';

  @override
  String get errorLoadingTitle => 'Something went wrong';

  @override
  String get noInternetTitle => 'No Internet Connection';

  @override
  String get noInternetMessage => 'Check your connection and try again.';

  @override
  String get openNetworkSettings => 'Open Network Settings';

  @override
  String get featureComingSoon => 'This feature is coming soon';

  @override
  String get scanComplete => 'Scan complete';

  @override
  String get songsFound => 'songs found';

  @override
  String get languageVietnamese => 'Tiếng Việt';

  @override
  String get languageEnglish => 'English';
}
