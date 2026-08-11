// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class AppLocalizationsVi extends AppLocalizations {
  AppLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get appTitle => 'G.A - Song';

  @override
  String get home => 'Trang chủ';

  @override
  String get library => 'Thư viện';

  @override
  String get online => 'Trực tuyến';

  @override
  String get ktv => 'KTV';

  @override
  String get personal => 'Cá nhân';

  @override
  String get settings => 'Cài đặt';

  @override
  String get play => 'Phát';

  @override
  String get pause => 'Tạm dừng';

  @override
  String get next => 'Bài tiếp theo';

  @override
  String get previous => 'Bài trước';

  @override
  String get shuffle => 'Trộn bài';

  @override
  String get repeat => 'Lặp lại';

  @override
  String get repeatOne => 'Lặp một bài';

  @override
  String get playOneStop => 'Phát một bài dừng';

  @override
  String get noSongSelected => 'Chưa chọn bài hát';

  @override
  String get noLyrics => 'Chưa có lời bài hát';

  @override
  String get search => 'Tìm kiếm';

  @override
  String get import => 'Nhập nhạc';

  @override
  String get addToPlaylist => 'Thêm vào playlist';

  @override
  String get createPlaylist => 'Tạo playlist';

  @override
  String get deletePlaylist => 'Xóa playlist';

  @override
  String get favorites => 'Yêu thích';

  @override
  String get speed => 'Tốc độ phát';

  @override
  String get equalizer => 'Bộ chỉnh âm';

  @override
  String get sleepTimer => 'Hẹn giờ ngủ';

  @override
  String get volume => 'Âm lượng';

  @override
  String get lyrics => 'Lời bài hát';

  @override
  String get miniPlayer => 'Trình phát nhỏ';

  @override
  String get pip => 'Hình trong hình';

  @override
  String get errorInit => 'Lỗi khởi tạo Audio Engine';

  @override
  String get errorRestart => 'Vui lòng khởi động lại ứng dụng';

  @override
  String get renderError => 'Đã xảy ra lỗi khi hiển thị giao diện';

  @override
  String get permissionMic =>
      'Ứng dụng cần quyền truy cập Microphone để hát KTV!';

  @override
  String get permissionDenied =>
      'Quyền Microphone đã bị từ chối. Vui lòng cấp lại trong Cài đặt.';

  @override
  String get greetingMorning => 'Chào buổi sáng,';

  @override
  String get greetingAfternoon => 'Chào buổi chiều,';

  @override
  String get greetingEvening => 'Chào buổi tối,';

  @override
  String get musicRoom => 'PHÒNG NGHE NHẠC';

  @override
  String get synced => 'Đồng bộ';

  @override
  String get offsetReset => 'Reset offset';

  @override
  String get noPlaylist => 'Chưa có playlist nào';

  @override
  String get addAlbumField =>
      'Thêm trường \"album\" vào songs.json để tạo playlist';

  @override
  String get noSongPlaying => 'Không có bài hát nào đang phát';

  @override
  String get exitMusicRoom => 'Thoát phòng nhạc';

  @override
  String get closeMiniPlayer => 'Đóng mini player';

  @override
  String get restoreNormal => 'Trở lại bình thường';

  @override
  String get find => 'Tìm';

  @override
  String get nowPlaying => 'Đang phát âm thanh';

  @override
  String get guide => 'Hướng dẫn';

  @override
  String get guideContent =>
      'Giúp bạn nghe bất kỳ bài hát nào từ kho tàng YouTube.\n\nDán link YouTube vào ô tìm kiếm và nhấn Tìm.';

  @override
  String get playing => 'Đang phát';

  @override
  String get hideVideo => 'Ẩn Video (Chỉ nghe nhạc)';

  @override
  String get showVideo => 'Hiện Video';

  @override
  String get importError => 'Lỗi import nhạc';

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
  String get cancel => 'Hủy';

  @override
  String get save => 'Lưu';

  @override
  String get delete => 'Xóa';

  @override
  String get confirm => 'Đồng ý';

  @override
  String get sortBy => 'Sắp xếp theo';

  @override
  String get sortByName => 'Theo tên';

  @override
  String get sortByArtist => 'Theo nghệ sĩ';

  @override
  String get sortByAlbum => 'Theo album';

  @override
  String get sortByDate => 'Theo ngày thêm';

  @override
  String get sortByDuration => 'Theo thời lượng';

  @override
  String get appearance => 'Giao diện';

  @override
  String get audio => 'Âm thanh';

  @override
  String get shortcuts => 'Phím tắt';

  @override
  String get advanced => 'Nâng cao';

  @override
  String get noSongsYet => 'Chưa có bài hát nào';

  @override
  String get addSongsHint =>
      'Thêm file nhạc vào thư mục assets/song/\nvà cập nhật file songs.json';

  @override
  String get cannotLoadLibrary => 'Không thể tải thư viện bài hát';

  @override
  String get retry => 'Thử tải lại';

  @override
  String get allSongs => 'Tất cả bài hát';

  @override
  String songCount(int count) {
    return '$count bài hát';
  }

  @override
  String get importSuccess => 'Đã import nhạc thành công!';

  @override
  String importErrorWithMsg(String error) {
    return 'Lỗi import nhạc: $error';
  }

  @override
  String get androidOnlyFeature =>
      'Tính năng này chỉ khả dụng trên thiết bị Android.';

  @override
  String get cannotLoadLibraryDb =>
      'Không thể nạp danh sách bài hát từ Database.';

  @override
  String get categoryAppearance => 'Giao diện';

  @override
  String get categoryPlayback => 'Phát nhạc';

  @override
  String get categoryVisualizer => 'Trực quan hóa';

  @override
  String get categoryLyrics => 'Lời bài hát';

  @override
  String get categoryWindowSystem => 'Cửa sổ & Hệ thống';

  @override
  String get categoryHotkeys => 'Phím tắt';

  @override
  String get categorySleepTimer => 'Hẹn giờ ngủ';

  @override
  String get categoryAdvanced => 'Nâng cao';

  @override
  String get categoryFeedback => 'Phản hồi';

  @override
  String get themeMode => 'Chế độ giao diện';

  @override
  String get useDynamicColor => 'Màu động';

  @override
  String get customPrimaryColor => 'Màu chủ đạo tùy chỉnh';

  @override
  String get enableBlur => 'Bật hiệu ứng mờ';

  @override
  String get blurLevel => 'Mức độ mờ';

  @override
  String get useNativeWindowEffect => 'Hiệu ứng cửa sổ gốc';

  @override
  String get windowOpacity => 'Độ trong suốt cửa sổ';

  @override
  String get isGridView => 'Chế độ lưới';

  @override
  String get customBackgroundImage => 'Ảnh nền tùy chỉnh';

  @override
  String get crossfadeDuration => 'Thời gian crossfade';

  @override
  String get crossfadeCurve => 'Đường cong crossfade';

  @override
  String get normalizationLevel => 'Mức normalization';

  @override
  String get eqBass => 'Bass';

  @override
  String get visualizerEnabled => 'Bật trực quan hóa';

  @override
  String get visualizerShape => 'Kiểu trực quan hóa';

  @override
  String get sensitivity => 'Độ nhạy';

  @override
  String get lyricsFontSize => 'Cỡ chữ lời bài hát';

  @override
  String get showLyricsInMiniPlayer => 'Hiện lời bài hát trong mini player';

  @override
  String get autoFetchLyrics => 'Tự động tải lời bài hát';

  @override
  String get minimizeToTray => 'Thu nhỏ vào khay hệ thống';

  @override
  String get autoHidePlayerBar => 'Tự động ẩn thanh phát nhạc';

  @override
  String get language => 'Ngôn ngữ';

  @override
  String get customHotkeys => 'Phím tắt tùy chỉnh';

  @override
  String get mediaKeyEnabled => 'Phím đa phương tiện';

  @override
  String get sleepTimerDuration => 'Thời lượng hẹn giờ';

  @override
  String get sleepTimerFadeOut => 'Giảm dần khi hết giờ';

  @override
  String get stopAtEndOfSong => 'Dừng ở cuối bài hát';

  @override
  String get reverbRoomSize => 'Kích thước phòng reverb';

  @override
  String get compressorThreshold => 'Ngưỡng compressor';

  @override
  String get compressorAttack => 'Attack compressor';

  @override
  String get compressorRelease => 'Release compressor';

  @override
  String get compressorKneeWidth => 'Độ rộng knee compressor';

  @override
  String get compressorMakeupGain => 'Makeup gain compressor';

  @override
  String get reverbDamp => 'Độ giảm âm reverb';

  @override
  String get soundFeedbackEnabled => 'Phản hồi âm thanh';

  @override
  String get hapticFeedbackEnabled => 'Phản hồi rung';

  @override
  String get manageHotkeys => 'Quản lý phím tắt';

  @override
  String get searchSettings => 'Tìm kiếm cài đặt...';

  @override
  String get noSettingsFound => 'Không tìm thấy cài đặt';

  @override
  String get pressCtrlKToSearch => 'Nhấn Ctrl+K để tìm kiếm cài đặt';

  @override
  String get enabled => 'Bật';

  @override
  String get disabled => 'Tắt';

  @override
  String get off => 'Tắt';

  @override
  String get minutes => 'phút';

  @override
  String get seconds => 'giây';

  @override
  String get endOfSong => 'Cuối bài hát';

  @override
  String get set => 'Đã đặt';

  @override
  String get notSet => 'Chưa đặt';

  @override
  String get none => 'Không có';

  @override
  String get light => 'Sáng';

  @override
  String get dark => 'Tối';

  @override
  String get system => 'Hệ thống';

  @override
  String get linear => 'Tuyến tính';

  @override
  String get exponential => 'Lũy thừa';

  @override
  String get sCurve => 'Chữ S';

  @override
  String get visualizerShapeCircle => 'Vòng tròn';

  @override
  String get visualizerShapeBars => 'Cột';

  @override
  String get visualizerShapeWave => 'Sóng';

  @override
  String get visualizerShapeTunnel => 'Đường hầm';

  @override
  String get visualizerShapeStarfield => 'Bầu trời sao';

  @override
  String get visualizerShapeOscilloscope => 'Máy hiện sóng';

  @override
  String get visualizerShapeRadial => 'Tia sáng';

  @override
  String get emptyLibraryTitle => 'Thư viện của bạn đang trống';

  @override
  String get emptyLibraryMessage =>
      'Nhập nhạc từ máy, quét nhạc hoặc tạo playlist để bắt đầu.';

  @override
  String get importMusic => 'Nhập nhạc';

  @override
  String get scanForMusic => 'Quét nhạc';

  @override
  String get addSongs => 'Thêm bài hát';

  @override
  String get importPlaylist => 'Nhập playlist';

  @override
  String get emptyPlaylistTitle => 'Playlist này đang trống';

  @override
  String emptyPlaylistMessage(String playlistName) {
    return 'Chưa có bài hát nào trong $playlistName. Thêm bài hát để bắt đầu.';
  }

  @override
  String get noResultsTitle => 'Không tìm thấy kết quả';

  @override
  String noResultsMessage(String query) {
    return 'Không tìm thấy kết quả cho \"$query\"';
  }

  @override
  String get clearSearch => 'Xóa tìm kiếm';

  @override
  String get errorLoadingTitle => 'Đã xảy ra lỗi';

  @override
  String get noInternetTitle => 'Mất kết nối Internet';

  @override
  String get noInternetMessage => 'Kiểm tra kết nối và thử lại.';

  @override
  String get openNetworkSettings => 'Mở cài đặt mạng';

  @override
  String get featureComingSoon => 'Tính năng này sắp ra mắt';

  @override
  String get scanComplete => 'Quét hoàn tất';

  @override
  String get songsFound => 'bài hát được tìm thấy';

  @override
  String get languageVietnamese => 'Tiếng Việt';

  @override
  String get languageEnglish => 'English';
}
