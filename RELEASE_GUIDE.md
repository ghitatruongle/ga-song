# 📦 Hướng dẫn Đóng gói & Phát hành — G.A - Song

Tài liệu hướng dẫn quy trình kiểm tra và đóng gói bản phát hành cho 5 nền tảng: **Windows, Android, Linux, macOS, iOS**.

---

## 1. Quy ước Đánh số Phiên bản (Semantic Versioning)

- **Định dạng**: `MAJOR.MINOR.PATCH+BUILD_NUMBER`
- **Ví dụ**: `1.0.1-beta+80002`
- **Các file cần cập nhật khi bump version**:
  1. `pubspec.yaml`: `version: x.y.z+build`
  2. `android_build_config.yaml`: `name: "x.y.z"`, `code: build`
  3. `lib/core/platforms/macos/macos_menu_bar.dart`: `applicationVersion: 'x.y.z'`
  4. `CHANGELOG.md`: Thêm mục phát hành mới tương ứng.

---

## 2. Danh mục Kiểm tra trước khi Phát hành (Pre-Release Checklist)

- [ ] Phân tích mã nguồn không có lỗi/cảnh báo: `flutter analyze`
- [ ] Chạy thành công toàn bộ test nghiệp vụ & dịch vụ: `flutter test test/core test/ui test/providers`
- [ ] Định dạng mã nguồn chuẩn: `dart format .`
- [ ] Đã cập nhật version và nội dung trong `CHANGELOG.md`

---

## 3. Hướng dẫn Đóng gói từng Nền tảng

### 🪟 3.1. Windows
```bash
# Build file thực thi Release (MSVC Optimized)
flutter build windows --release

# Tạo gói MSIX (nếu cài đặt msix package)
dart run msix:create
```
*Đầu ra*: `build/windows/x64/runner/Release/ga_song.exe`

### 🤖 3.2. Android
```bash
# Build file APK Release (tối ưu theo từng kiến trúc CPU)
flutter build apk --release --split-per-abi

# Build file APK arm64 đơn lẻ
flutter build apk --release --target-platform android-arm64

# Build file App Bundle (AAB) tải lên Google Play
flutter build appbundle --release
```
*Đầu ra*: `build/app/outputs/flutter-apk/app-arm64-v8a-release.apk` hoặc `build/app/outputs/bundle/release/app-release.aab`

### 🍎 3.3. macOS
```bash
# Build file ứng dụng .app / .dmg (hỗ trợ Universal Binary cho cả arm64 và Intel)
UNIVERSAL=1 ./build_apple.sh 1.0.1-beta macos
```
*Đầu ra*: `build/macos/Build/Products/Release/ga_song.app`

### 📱 3.4. iOS
```bash
# Build gói thử nghiệm TestFlight IPA
IOS_TESTFLIGHT=1 ./build_apple.sh 1.0.1-beta ios
```
*Đầu ra*: `build/ios/ipa/ga_song.ipa`

### 🐧 3.5. Linux
```bash
# Build bundle Linux Release
flutter build linux --release

# Đóng gói file .deb qua script
./build_linux.sh
```
*Đầu ra*: `build/linux/x64/release/bundle/`