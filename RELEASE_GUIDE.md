# G.A - Song Release Guide

## Overview
This document describes the release process for G.A - Song across all supported platforms.

## Version Strategy
- **Major**: Breaking changes, major UI overhauls
- **Minor**: New features, significant improvements
- **Patch**: Bug fixes, minor improvements
- **Format**: `MAJOR.MINOR.PATCH+BUILD_NUMBER`
- **Example**: `0.8.0+80001`

## Release Checklist

### Pre-Release
- [ ] All tests pass (`flutter test`)
- [ ] Golden tests pass (`flutter test --update-goldens`)
- [ ] Static analysis passes (`flutter analyze --fatal-infos`)
- [ ] Code formatting correct (`dart format --set-exit-if-changed .`)
- [ ] Version bumped in `pubspec.yaml`
- [ ] CHANGELOG.md updated
- [ ] Release notes drafted

### Windows (MSIX)
- [ ] Certificate valid (`certificate.pfx`)
- [ ] MSIX builds successfully (`flutter build windows --release`)
- [ ] MSIX installs correctly
- [ ] App launches from Start Menu
- [ ] Jump List integration works
- [ ] Protocol handler (`gasong://`) registered
- [ ] File associations work (`.m3u`, `.pls`, `.xspf`)
- [ ] System tray integration works
- [ ] Global hotkeys work
- [ ] Window effects (Mica/Acrylic) render correctly

### Android (APK/AAB)
- [ ] Keystore accessible (`keystore.jks`)
- [ ] Debug build works (`flutter build apk --debug`)
- [ ] Release APK builds (`flutter build apk --release`)
- [ ] Release AAB builds (`flutter build appbundle --release`)
- [ ] APK installs on device
- [ ] AAB uploads to Play Console
- [ ] All ABIs included (arm64-v8a, armeabi-v7a, x86_64)
- [ ] ProGuard/R8 optimization works
- [ ] APK size within budget (< 50MB base)
- [ ] All permissions declared correctly
- [ ] Deep links work (`gasong://`)
- [ ] MediaSession integration works
- [ ] Picture-in-Picture works
- [ ] Media notifications work
- [ ] Audio focus handling works
- [ ] Background playback works

### Linux (AppImage/Flatpak/Deb)
- [ ] AppImage builds
- [ ] Flatpak manifest valid
- [ ] Deb package builds
- [ ] Desktop entry works
- [ ] MIME type associations work
- [ ] Icon displays correctly

### macOS (if supported)
- [ ] App bundle builds
- [ ] Code signing works
- [ ] Notarization passes
- [ ] DMG creates successfully

## Build Commands

### Windows
```bash
# MSIX (Windows Store)
flutter build windows --release --target-platform=windows-x64
# Then use msix CLI or Visual Studio to package

# Standalone executable
flutter build windows --release --target-platform=windows-x64
```

### Android
```bash
# Debug APK
flutter build apk --debug

# Release APK (universal)
flutter build apk --release

# Release APK (split per ABI)
flutter build apk --release --split-per-abi

# Release AAB (Play Store)
flutter build appbundle --release

# Specific flavor
flutter build appbundle --release --flavor playstore
flutter build apk --release --flavor playstore
```

### Linux
```bash
# Desktop
flutter build linux --release

# AppImage (requires appimage-builder)
# Flatpak (requires flatpak-builder)
# Deb package
flutter build linux --release
cd build/linux/x64/release/bundle
# Use fpm or similar to create .deb
```

## Release Artifacts

### Naming Convention
```
GA_Song_v{VERSION}_Windows_MSIX.msix
GA_Song_v{VERSION}_Windows_Portable.zip
GA_Song_v{VERSION}_Android_APK_Universal.apk
GA_Song_v{VERSION}_Android_APK_arm64-v8a.apk
GA_Song_v{VERSION}_Android_APK_armeabi-v7a.apk
GA_Song_v{VERSION}_Android_AAB.aab
GA_Song_v{VERSION}_Linux_x64_AppImage.AppImage
GA_Song_v{VERSION}_Linux_x64.deb
GA_Song_v{VERSION}_macOS_Universal.dmg
GA_Song_v{VERSION}_Source_Code.tar.gz
```

### Checksums
Generate SHA256 for all artifacts:
```bash
sha256sum GA_Song_v0.8.0_*.msix GA_Song_v0.8.0_*.apk GA_Song_v0.8.0_*.aab > SHA256SUMS.txt
```

## GitHub Release

### Release Notes Template
```markdown
## GA Song v{VERSION}

### 🎉 What's New
- Feature 1
- Feature 2
- Bug fix 1

### 🐛 Bug Fixes
- Fixed issue #123
- Fixed crash when...

### 🔧 Improvements
- Performance improvement in...
- Better UX for...

### 📦 Downloads
| Platform | File | SHA256 |
|----------|------|--------|
| Windows MSIX | `GA_Song_v0.8.0_Windows_MSIX.msix` | `sha256...` |
| Windows Portable | `GA_Song_v0.8.0_Windows_Portable.zip` | `sha256...` |
| Android APK (Universal) | `GA_Song_v0.8.0_Android_APK_Universal.apk` | `sha256...` |
| Android AAB | `GA_Song_v0.8.0_Android_AAB.aab` | `sha256...` |
| Linux AppImage | `GA_Song_v0.8.0_Linux_AppImage.AppImage` | `sha256...` |

### 📋 Full Changelog
See [CHANGELOG.md](CHANGELOG.md)

### 📥 Installation
**Windows**: Download MSIX and double-click, or use Portable ZIP
**Android**: Install APK or get from Play Store
**Linux**: Use AppImage, Flatpak, or .deb package

### ⚠️ Known Issues
- Issue 1: ...
- Issue 2: ...

---

**Full Changelog**: [CHANGELOG.md](CHANGELOG.md)
```

## GitHub Actions Workflow

### `.github/workflows/release.yml`
```yaml
name: Release

on:
  push:
    tags:
      - 'v*'

jobs:
  build-windows:
    runs-on: windows-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.32.0'
      - run: flutter pub get
      - run: flutter build windows --release
      - uses: actions/upload-artifact@v4
        with:
          name: windows-release
          path: build/windows/x64/runner/Release/

  build-android:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.32.0'
      - uses: actions/setup-java@v4
        with:
          distribution: 'zulu'
          java-version: '17'
      - run: flutter pub get
      - run: flutter build appbundle --release
      - run: flutter build apk --release --split-per-abi
      - uses: actions/upload-artifact@v4
        with:
          name: android-release
          path: |
            build/app/outputs/bundle/release/*.aab
            build/app/outputs/apk/release/*.apk

  build-linux:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.32.0'
      - run: sudo apt-get update && sudo apt-get install -y clang cmake ninja-build pkg-config libgtk-3-dev liblzma-dev
      - run: flutter pub get
      - run: flutter build linux --release
      - uses: actions/upload-artifact@v4
        with:
          name: linux-release
          path: build/linux/x64/release/bundle/

  release:
    needs: [build-windows, build-android, build-linux]
    runs-on: ubuntu-latest
    if: startsWith(github.ref, 'refs/tags/v')
    steps:
      - uses: actions/download-artifact@v4
        with:
          name: windows-release
          path: artifacts/windows
      - uses: actions/download-artifact@v4
        with:
          name: android-release
          path: artifacts/android
      - uses: actions/download-artifact@v4
        with:
          name: linux-release
          path: artifacts/linux
      - run: |
          cd artifacts
          sha256sum * > SHA256SUMS.txt
      - uses: softprops/action-gh-release@v1
        with:
          files: |
            artifacts/windows/*
            artifacts/android/*
            artifacts/linux/*
            artifacts/SHA256SUMS.txt
          generate_release_notes: true
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

## Pre-Release Testing

### Device Matrix
| Platform | Device | OS Version | Test Status |
|----------|--------|------------|-------------|
| Windows 10 | Desktop | 22H2 | ✅ |
| Windows 11 | Desktop | 23H2 | ✅ |
| Windows 11 | Tablet | 23H2 | ✅ |
| Android | Pixel 7 | 14 | ✅ |
| Android | Pixel 6a | 13 | ✅ |
| Android | Samsung S23 | 14 | ✅ |
| Android | Tablet | 13 | ✅ |
| Linux | Ubuntu 22.04 | Desktop | ✅ |
| Linux | Fedora 39 | Desktop | ✅ |

## Signing Certificates

### Windows
- **Type**: EV Code Signing Certificate
- **Format**: PFX
- **Storage**: Azure Key Vault / GitHub Secrets
- **Password**: `MSIX_CERT_PASSWORD` (GitHub Secret)

### Android
- **Keystore**: `keystore.jks`
- **Alias**: `gasong`
- **Store Password**: `ANDROID_KEYSTORE_PASSWORD` (GitHub Secret)
- **Key Password**: `ANDROID_KEY_PASSWORD` (GitHub Secret)

### Linux
- **GPG Key**: For signing AppImage/Flatpak/Deb
- **Key ID**: Stored in GitHub Secrets

## Rollback Procedure

If critical issue found post-release:
1. Revert Git tag: `git tag -d vX.Y.Z && git push origin :refs/tags/vX.Y.Z`
2. Draft new release with previous version
3. Notify users via GitHub Discussions/Discord
4. Hotfix branch: `git checkout -b hotfix/vX.Y.Z vX.Y.(Z-1)`

## Support Channels
- **GitHub Issues**: Bug reports
- **GitHub Discussions**: Feature requests
- **Discord**: Community support
- **Email**: security@gasong.app (security issues)