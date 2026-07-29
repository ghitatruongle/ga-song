import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Simple localization support for GA Song.
/// Supports Vietnamese (vi) and English (en).
class AppLocalizations {
  final Locale locale;
  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        AppLocalizations(const Locale('vi'));
  }

  /// Locale-independent fallback for error paths that run outside the
  /// `Localizations` widget tree (e.g. `ErrorWidget.builder`).
  static AppLocalizations get fallback => AppLocalizations(const Locale('vi'));

  static const _vi = {
    'appTitle': 'G.A - Song',
    'home': 'Trang chủ',
    'library': 'Thư viện',
    'online': 'Trực tuyến',
    'ktv': 'KTV',
    'personal': 'Cá nhân',
    'settings': 'Cài đặt',
    'play': 'Phát',
    'pause': 'Tạm dừng',
    'next': 'Bài tiếp theo',
    'previous': 'Bài trước',
    'shuffle': 'Trộn bài',
    'repeat': 'Lặp lại',
    'repeatOne': 'Lặp một bài',
    'playOneStop': 'Phát một bài dừng',
    'noSongSelected': 'Chưa chọn bài hát',
    'noLyrics': 'Chưa có lời bài hát',
    'search': 'Tìm kiếm',
    'import': 'Nhập nhạc',
    'addToPlaylist': 'Thêm vào playlist',
    'createPlaylist': 'Tạo playlist',
    'deletePlaylist': 'Xóa playlist',
    'favorites': 'Yêu thích',
    'speed': 'Tốc độ phát',
    'equalizer': 'Bộ chỉnh âm',
    'sleepTimer': 'Hẹn giờ ngủ',
    'volume': 'Âm lượng',
    'lyrics': 'Lời bài hát',
    'miniPlayer': 'Trình phát nhỏ',
    'pip': 'Hình trong hình',
    'errorInit': 'Lỗi khởi tạo Audio Engine',
    'errorRestart': 'Vui lòng khởi động lại ứng dụng',
    'permissionMic': 'Ứng dụng cần quyền truy cập Microphone để hát KTV!',
    'permissionDenied':
        'Quyền Microphone đã bị từ chối. Vui lòng cấp lại trong Cài đặt.',
    'greetingMorning': 'Chào buổi sáng,',
    'greetingAfternoon': 'Chào buổi chiều,',
    'greetingEvening': 'Chào buổi tối,',
    'musicRoom': 'PHÒNG NGHE NHẠC',
    'synced': 'Đồng bộ',
    'offsetReset': 'Reset offset',
    'noPlaylist': 'Chưa có playlist nào',
    'addAlbumField': 'Thêm trường "album" vào songs.json để tạo playlist',
    'noSongPlaying': 'Không có bài hát nào đang phát',
    'exitMusicRoom': 'Thoát phòng nhạc',
    'closeMiniPlayer': 'Đóng mini player',
    'restoreNormal': 'Trở lại bình thường',
    'find': 'Tìm',
    'nowPlaying': 'Đang phát âm thanh',
    'guide': 'Hướng dẫn',
    'guideContent':
        'Giúp bạn nghe bất kỳ bài hát nào từ kho tàng YouTube.\n\nDán link YouTube vào ô tìm kiếm và nhấn Tìm.',
    'playing': 'Đang phát',
    'hideVideo': 'Ẩn Video (Chỉ nghe nhạc)',
    'showVideo': 'Hiện Video',
    'importError': 'Lỗi import nhạc',
    'unknown': 'Unknown',
    'bassBoost': 'Bass Boost',
    'reverb': 'Reverb',
    'compressor': 'Compressor',
    'normalization': 'Normalization',
    'pitchShift': 'Pitch Shift',
    'cancel': 'Hủy',
    'save': 'Lưu',
    'delete': 'Xóa',
    'confirm': 'Đồng ý',
    'sortBy': 'Sắp xếp theo',
    'sortByName': 'Theo tên',
    'sortByArtist': 'Theo nghệ sĩ',
    'sortByAlbum': 'Theo album',
    'sortByDate': 'Theo ngày thêm',
    'sortByDuration': 'Theo thời lượng',
    'appearance': 'Giao diện',
    'audio': 'Âm thanh',
    'shortcuts': 'Phím tắt',
    'advanced': 'Nâng cao',
    'noSongsYet': 'Chưa có bài hát nào',
    'addSongsHint':
        'Thêm file nhạc vào thư mục assets/song/\nvà cập nhật file songs.json',
    'cannotLoadLibrary': 'Không thể tải thư viện bài hát',
    'retry': 'Thử tải lại',
    'allSongs': 'Tất cả bài hát',
    'importSuccess': 'Đã import nhạc thành công!',
    'importErrorWithMsg': 'Lỗi import nhạc: {error}',
    'androidOnlyFeature': 'Tính năng này chỉ khả dụng trên thiết bị Android.',
    'songCount': '{count} bài hát',
    'cannotLoadLibraryDb': 'Không thể nạp danh sách bài hát từ Database.',
    'renderError': 'Đã xảy ra lỗi hiển thị',
    'language': 'Ngôn ngữ',
    'languageVietnamese': 'Tiếng Việt',
    'languageEnglish': 'English',
  };

  static const _en = {
    'appTitle': 'G.A - Song',
    'home': 'Home',
    'library': 'Library',
    'online': 'Online',
    'ktv': 'KTV',
    'personal': 'Personal',
    'settings': 'Settings',
    'play': 'Play',
    'pause': 'Pause',
    'next': 'Next',
    'previous': 'Previous',
    'shuffle': 'Shuffle',
    'repeat': 'Repeat',
    'repeatOne': 'Repeat One',
    'playOneStop': 'Play One Stop',
    'noSongSelected': 'No song selected',
    'noLyrics': 'No lyrics available',
    'search': 'Search',
    'import': 'Import',
    'addToPlaylist': 'Add to playlist',
    'createPlaylist': 'Create playlist',
    'deletePlaylist': 'Delete playlist',
    'favorites': 'Favorites',
    'speed': 'Playback speed',
    'equalizer': 'Equalizer',
    'sleepTimer': 'Sleep timer',
    'volume': 'Volume',
    'lyrics': 'Lyrics',
    'miniPlayer': 'Mini player',
    'pip': 'Picture in picture',
    'errorInit': 'Audio Engine initialization error',
    'errorRestart': 'Please restart the application',
    'permissionMic': 'Microphone permission is required for KTV!',
    'permissionDenied':
        'Microphone permission denied. Please grant it in Settings.',
    'greetingMorning': 'Good morning,',
    'greetingAfternoon': 'Good afternoon,',
    'greetingEvening': 'Good evening,',
    'musicRoom': 'MUSIC ROOM',
    'synced': 'Synced',
    'offsetReset': 'Reset offset',
    'noPlaylist': 'No playlists yet',
    'addAlbumField': 'Add "album" field to songs.json to create playlists',
    'noSongPlaying': 'No song is currently playing',
    'exitMusicRoom': 'Exit music room',
    'closeMiniPlayer': 'Close mini player',
    'restoreNormal': 'Restore normal view',
    'find': 'Search',
    'nowPlaying': 'Now playing',
    'guide': 'Guide',
    'guideContent':
        'Help you listen to any song from YouTube.\n\nPaste a YouTube link in the search box and press Search.',
    'playing': 'Playing',
    'hideVideo': 'Hide Video (Audio only)',
    'showVideo': 'Show Video',
    'importError': 'Import error',
    'unknown': 'Unknown',
    'bassBoost': 'Bass Boost',
    'reverb': 'Reverb',
    'compressor': 'Compressor',
    'normalization': 'Normalization',
    'pitchShift': 'Pitch Shift',
    'cancel': 'Cancel',
    'save': 'Save',
    'delete': 'Delete',
    'confirm': 'Confirm',
    'sortBy': 'Sort by',
    'sortByName': 'By name',
    'sortByArtist': 'By artist',
    'sortByAlbum': 'By album',
    'sortByDate': 'By date added',
    'sortByDuration': 'By duration',
    'appearance': 'Appearance',
    'audio': 'Audio',
    'shortcuts': 'Shortcuts',
    'advanced': 'Advanced',
    'noSongsYet': 'No songs yet',
    'addSongsHint': 'Add music files to assets/song/\nand update songs.json',
    'cannotLoadLibrary': 'Cannot load music library',
    'retry': 'Retry',
    'allSongs': 'All songs',
    'importSuccess': 'Import successful!',
    'importErrorWithMsg': 'Import error: {error}',
    'androidOnlyFeature': 'This feature is only available on Android devices.',
    'songCount': '{count} songs',
    'cannotLoadLibraryDb': 'Cannot load song list from Database.',
    'renderError': 'A display error occurred',
    'language': 'Language',
    'languageVietnamese': 'Tiếng Việt',
    'languageEnglish': 'English',
  };

  static final Map<String, Map<String, String>> _translations = {
    'vi': _vi,
    'en': _en,
  };

  String translate(String key) {
    final lang = locale.languageCode;
    return _translations[lang]?[key] ?? _translations['vi']?[key] ?? key;
  }

  // Convenience getters
  String get appTitle => translate('appTitle');
  String get home => translate('home');
  String get library => translate('library');
  String get online => translate('online');
  String get ktv => translate('ktv');
  String get personal => translate('personal');
  String get settings => translate('settings');
  String get play => translate('play');
  String get pause => translate('pause');
  String get next => translate('next');
  String get previous => translate('previous');
  String get shuffle => translate('shuffle');
  String get repeat => translate('repeat');
  String get repeatOne => translate('repeatOne');
  String get playOneStop => translate('playOneStop');
  String get noSongSelected => translate('noSongSelected');
  String get noLyrics => translate('noLyrics');
  String get search => translate('search');
  String get import => translate('import');
  String get addToPlaylist => translate('addToPlaylist');
  String get createPlaylist => translate('createPlaylist');
  String get deletePlaylist => translate('deletePlaylist');
  String get favorites => translate('favorites');
  String get speed => translate('speed');
  String get equalizer => translate('equalizer');
  String get sleepTimer => translate('sleepTimer');
  String get volume => translate('volume');
  String get lyrics => translate('lyrics');
  String get miniPlayer => translate('miniPlayer');
  String get pip => translate('pip');
  String get errorInit => translate('errorInit');
  String get errorRestart => translate('errorRestart');
  String get permissionMic => translate('permissionMic');
  String get permissionDenied => translate('permissionDenied');
  String get greetingMorning => translate('greetingMorning');
  String get greetingAfternoon => translate('greetingAfternoon');
  String get greetingEvening => translate('greetingEvening');
  String get musicRoom => translate('musicRoom');
  String get synced => translate('synced');
  String get offsetReset => translate('offsetReset');
  String get noPlaylist => translate('noPlaylist');
  String get addAlbumField => translate('addAlbumField');
  String get noSongPlaying => translate('noSongPlaying');
  String get exitMusicRoom => translate('exitMusicRoom');
  String get closeMiniPlayer => translate('closeMiniPlayer');
  String get restoreNormal => translate('restoreNormal');
  String get find => translate('find');
  String get nowPlaying => translate('nowPlaying');
  String get guide => translate('guide');
  String get guideContent => translate('guideContent');
  String get playing => translate('playing');
  String get hideVideo => translate('hideVideo');
  String get showVideo => translate('showVideo');
  String get importError => translate('importError');
  String get unknown => translate('unknown');
  String get bassBoost => translate('bassBoost');
  String get reverb => translate('reverb');
  String get compressor => translate('compressor');
  String get normalization => translate('normalization');
  String get pitchShift => translate('pitchShift');
  String get cancel => translate('cancel');
  String get save => translate('save');
  String get delete => translate('delete');
  String get confirm => translate('confirm');
  String get sortBy => translate('sortBy');
  String get sortByName => translate('sortByName');
  String get sortByArtist => translate('sortByArtist');
  String get sortByAlbum => translate('sortByAlbum');
  String get sortByDate => translate('sortByDate');
  String get sortByDuration => translate('sortByDuration');
  String get appearance => translate('appearance');
  String get audio => translate('audio');
  String get shortcuts => translate('shortcuts');
  String get advanced => translate('advanced');
  String get noSongsYet => translate('noSongsYet');
  String get addSongsHint => translate('addSongsHint');
  String get cannotLoadLibrary => translate('cannotLoadLibrary');
  String get retry => translate('retry');
  String get allSongs => translate('allSongs');
  String get importSuccess => translate('importSuccess');
  String get importErrorWithMsg => translate('importErrorWithMsg');
  String get androidOnlyFeature => translate('androidOnlyFeature');
  String get songCount => translate('songCount');
  String get cannotLoadLibraryDb => translate('cannotLoadLibraryDb');
  String get renderError => translate('renderError');
  String get language => translate('language');
  String get languageVietnamese => translate('languageVietnamese');
  String get languageEnglish => translate('languageEnglish');

  /// Hỗ trợ translate với tham số - thay thế {key} bằng giá trị.
  String translateWith(String key, Map<String, String> params) {
    String result = translate(key);
    for (final entry in params.entries) {
      result = result.replaceAll('{${entry.key}}', entry.value);
    }
    return result;
  }
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['vi', 'en'].contains(locale.languageCode);

  // SynchronousFuture so the very first frame (and locale switches) render
  // without a blank flash while the localization "loads".
  @override
  Future<AppLocalizations> load(Locale locale) =>
      SynchronousFuture<AppLocalizations>(AppLocalizations(locale));

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}
