# Changelog

All notable changes to the **G.A - Song** project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.0.1-beta] — 2026-08-18

### Added
- **Chế độ Giảm Lag (Android)**: Thêm nút bật/tắt trong *Cài đặt → Hệ thống* giúp tối ưu hiệu năng tức thì trên các thiết bị cấu hình yếu (ép chạy low-tier, giảm image cache về 8MB, tự động tắt visualizer/blur mà không ghi đè cài đặt gốc của người dùng). Có thể tìm kiếm nhanh qua thanh tìm kiếm (Ctrl+K).
- **Nhận biết chế độ Tiết kiệm pin (Power Saver / Low Power Mode)**:
  - **Android**: Đồng bộ trạng thái từ `PowerManager` để hoãn các tác vụ quét ngầm và nạp ảnh bìa không cần thiết.
  - **Windows**: Nhận diện trạng thái Battery Saver qua API hệ thống để tự động hạ tần số quét Visualizer và giảm tải CPU.
  - **iOS**: Bắt sự kiện `NSProcessInfoPowerStateDidChange` để giảm tốc độ vẽ Visualizer xuống ~30fps khi bật chế độ nguồn điện thấp.
- **Xử lý cảnh báo đầy bộ nhớ (Memory Pressure / Warning)**:
  - **macOS**: Lắng nghe `DispatchSource` memory pressure và chủ động xả bộ đệm ảnh/âm thanh trước khi hệ thống can thiệp.
  - **iOS**: Xử lý `didReceiveMemoryWarning` để giải phóng cache bộ đệm âm thanh và hình ảnh ngay lập tức.
- **Thanh menu hệ thống macOS hoàn thiện**: Bổ sung đầy đủ hành động cho các mục *Preferences (Cài đặt), Import Songs (Nhập bài hát), Quit (Thoát ứng dụng qua NSApp.terminate), Close Window (Đóng cửa sổ về Tray), Minimize*. Hộp thoại Giới thiệu (About) hiển thị đúng phiên bản `1.0.1-beta`.
- **Tùy chọn đóng gói Apple**: Hỗ trợ xuất file universal binary (arm64/x64) trên macOS và đóng gói TestFlight IPA cho iOS qua script `build_apple.sh`.

### Improved & Optimized
- **Tối ưu RAM đa nền tảng**:
  - Tự động giải phóng toàn bộ audio buffers đã giải mã sau 5 phút không phát nhạc.
  - Hủy tiến trình giải mã bài cũ ngay khi người dùng nhấn Skip/Next liên tục.
  - Tạm dừng animation của Visualizer khi cửa sổ ứng dụng desktop bị ẩn hoặc thu nhỏ xuống Taskbar/System Tray.
  - Dọn dẹp bộ đệm ảnh bìa (Cover Art Cache) theo dung lượng byte thực tế thay vì chỉ đếm số lượng mục.
- **Tăng tốc khởi động lạnh (Cold Start)**: Hoãn quá trình đồng bộ thư viện nhạc sau frame render đầu tiên; màu nền cửa sổ khởi động trùng khớp với theme để không bị chớp sáng.
- **Tối ưu hóa bản build Linux**: Tự động strip symbol debug trên bản release; đặt màu nền `#121212` an toàn trên Wayland tránh hiện hộp đen; tích hợp font dự phòng Noto Sans tránh lỗi hiển thị tiếng Việt.
- **Tối ưu hóa bản build Windows & Android**: Bật tối ưu hóa toàn diện MSVC (/GL, /LTCG) trên Windows; chuyển cơ chế đồng bộ lời bài hát sang hướng sự kiện (event-driven); bật R8 Full Mode và strip debug symbols trên Android giúp giảm kích thước file APK.

### Fixed
- Sửa lỗi deep link scheme `gasong://` trên Android để đồng bộ nhất quán với macOS và iOS.
- Sửa lỗi tính toán particle/star budget của visualizer trên iOS bị nhận nhầm thành cấu hình desktop.

---

## [1.0.0] — 2026-08-04

### Added
- **Hỗ trợ toàn diện hệ sinh thái Apple (iOS & macOS)**:
  - Tích hợp CoreAudio và hỗ trợ màn hình ProMotion 120Hz mượt mà.
  - Phát nhạc nền trên iOS (`UIBackgroundModes: audio`, `AVAudioSessionCategoryPlayback`).
  - Tích hợp Apple Remote Command Center: điều khiển phát nhạc, hiển thị thông tin bài hát và ảnh bìa trên Lockscreen, Dynamic Island & Control Center.
  - Cửa sổ Mini Player thu nhỏ (320x320) ghim nổi trên màn hình (Always-on-Top) cho macOS cùng phím tắt `Cmd + Shift + M`.
- **Giao diện di động hiện đại**:
  - Thiết kế lại thanh điều hướng dưới cùng (`BottomNavigationBar` / `CupertinoTabBar`).
  - Thanh Mini Player dạng nổi với hiệu ứng kính mờ (glassmorphism) và thao tác vuốt để mở Fullscreen Player dạng đĩa than xoay tròn.

### Improved
- Tinh gọn lượng tiêu thụ pin và RAM khi phát nhạc chạy ngầm.

---

## [0.9.0] — 2026-08-01

### Added
- **Windows DPI Awareness**: Tự động lưu và khôi phục kích thước, vị trí cửa sổ chính xác theo tỷ lệ DPI của từng màn hình.
- **Tìm kiếm cài đặt không dấu**: Hỗ trợ tìm kiếm tiếng Việt không dấu trong menu Cài đặt (Ctrl+K).
- **Điều khiển timeline SMTC**: Hỗ trợ tua nhanh/lùi 10 giây trực tiếp từ thanh điều khiển Windows SMTC.
- **Chống nhấp đúp phím Media**: Bổ sung debounce 150ms cho các phím media cứng để tránh kích hoạt nhiều lần.

### Improved
- Tự động điều chỉnh frame rate của Visualizer theo cấu hình phần cứng thiết bị.
- Giảm thời gian trễ khi resize cửa sổ desktop từ 400ms xuống 300ms.

---

## [0.6.5] — 2026-07-30

### Added
- **Tự động ẩn thanh phát nhạc khi cuộn**: Thanh phát nhạc dưới đáy tự động trượt ẩn khi cuộn xuống và hiện lại khi cuộn lên.
- **Màu nền thích ứng theo bài hát**: Thanh phát nhạc tự động pha trộn màu chủ đạo trích xuất từ ảnh bìa bài hát đang phát.
- **Kéo thả sắp xếp danh sách phát**: Hỗ trợ kéo thả đổi thứ tự bài hát trong playlist và tự động đồng bộ ngay vào hàng đợi phát.
- **Tùy chỉnh cỡ chữ lời bài hát**: Thêm thanh trượt chỉnh kích thước chữ hiển thị lời (12–36px) trong Cài đặt.
- **Tùy chọn hẹn giờ dừng phát**: Bổ sung tùy chọn "Dừng phát khi hết bài hát hiện tại" trong hộp thoại hẹn giờ ngủ.

### Improved
- Nâng thời gian lưu bộ đệm ảnh bìa (TTL) lên 1 giờ để giảm tải CPU và ổ đĩa.

---

## [0.6.0] — 2026-07-28

### Added
- **Chuyển đổi ngôn ngữ trực tiếp**: Hỗ trợ chuyển đổi qua lại giữa tiếng Việt và tiếng Anh trong *Cài đặt → Ngôn ngữ*.
- **Tự động khôi phục bài hát mẫu**: Tự động nạp danh sách bài hát mặc định khi cài đặt ứng dụng lần đầu hoặc cơ sở dữ liệu mới.

### Fixed
- Sửa lỗi không nạp được danh sách bài hát mẫu trên các bản cài đặt mới.
- Loại bỏ các cảnh báo và tối ưu hóa câu lệnh truy vấn cơ sở dữ liệu Drift.

---

## [0.5.0] — 2026-07-26

### Added
- **Chuyển đổi sang Drift ORM**: Nâng cấp toàn bộ tầng lưu trữ dữ liệu từ `sqflite` sang `Drift` với kiểu dữ liệu an toàn và reactive streams.
- **Tự động di chuyển dữ liệu (Auto Migration)**: Tự động chuyển đổi danh sách phát và lịch sử nghe nhạc cũ sang cấu trúc mới an toàn.
- **Danh sách phát thông minh (Smart Playlists)**: Tự động tạo danh sách *Nghe nhiều nhất, Nghe gần đây, Yêu thích, Mới thêm*.
- **Trình chỉnh sửa thẻ nhạc (Tag Editor)**: Xem và sửa thông tin ID3 tags (Tiêu đề, Nghệ sĩ, Album, Năm, Thể loại) trực tiếp trong ứng dụng.
- **Phản hồi rung (Haptic Feedback)**: Thêm hiệu ứng rung nhẹ khi chạm các nút điều khiển trên điện thoại Android.

---

## [0.1.5] — 2026-07-25

### Added
- Hiệu ứng cửa sổ Mica Alt Tab trên Windows 11.
- Hiển thị tiến trình phát nhạc và thông tin bài hát trên menu khay hệ thống (System Tray).
- Phím tắt toàn cục tua nhạc 10 giây và nhấp đúp phím Space để phát/dừng.
- Hiệu ứng mờ dần (fade-in/fade-out) cho lời bài hát nổi trên màn hình desktop.

---

## [0.1.0] — 2026-07-21

### Added
- Tích hợp hệ thống ghi log có cấu trúc `AppLogger` thay thế toàn bộ `debugPrint`.
- Chuẩn hóa hệ thống thiết kế Tokens (màu sắc, khoảng cách, bo góc, độ nổi) trong `tokens.dart`.
- Chuẩn hóa hệ thống hiệu ứng chuyển động và thời lượng animation trong `app_motion.dart`.
- Tối ưu hóa debounce cho các thanh trượt Equalizer và hiệu ứng âm thanh.

---

## [1.0.0+1] — 2026-06-21

### Added
- Bản phát hành ban đầu của ứng dụng **G.A - Song**.
- Trình phát nhạc cục bộ với engine âm thanh SoLoud chất lượng cao.
- Bộ cân bằng âm thanh Parametric Equalizer 5 dải kèm các preset (Normal, Bass+, Vocal, Acoustic).
- Hiệu ứng âm thanh nâng cao: Bass boost, Pitch shift, Reverb, Compressor, Normalization.
- Hiệu ứng Visualizer sóng nhạc và trường sao phản hồi theo nhịp điệu âm thanh.
- Chế độ KTV Karaoke với đầu vào micro và tích hợp video YouTube.
- Đồng bộ hiển thị lời bài hát định dạng LRC và SRT.
- Quản lý danh sách phát với các chế độ phát: Shuffle, Repeat, Play One Stop.
- Tích hợp khay hệ thống, phím tắt toàn cục, Windows SMTC, Linux MPRIS, Android Notification.
- Giao diện Dark/Light mode với hiệu ứng kính mờ và màu sắc động (Dynamic Color).
