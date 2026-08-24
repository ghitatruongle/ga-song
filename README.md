# 🎵 G.A - Song

A modern, full-featured, cross-platform music player built with Flutter. Supports local audio playback, KTV (karaoke) mode, YouTube integration, 5-band parametric equalizer, audio effects, audio-reactive visualizer, synced lyrics, and native OS integrations.

---

## ✨ Features

- **Audio Playback** — Native audio playback powered by SoLoud engine with gapless playback and crossfade.
- **Parametric Equalizer** — 5-band parametric EQ with presets (Normal, Bass+, Vocal, Acoustic) and custom sliders.
- **Audio Effects** — Bass boost, pitch shift, reverb, compressor, volume normalization.
- **Audio Visualizer** — Real-time audio-reactive particle and starfield wave visualizer.
- **Synced Lyrics** — LRC and SRT format support with real-time synchronized line-by-line display.
- **KTV / Karaoke Mode** — Sing along with live microphone input and YouTube video accompaniment.
- **Smart Playlists** — User playlists and auto-generated smart playlists (Most Played, Recently Played, Favorites).
- **Cover Art Pipeline** — High-performance 3-tier caching (memory → disk → file) with dynamic dominant color adaptation.
- **System Integration** — Native System Tray, global hotkeys, Windows SMTC, Linux MPRIS, Android media notifications, macOS Menu Bar & Mini Player window, iOS Lockscreen & Control Center remote commands.
- **Battery & Performance Modes** — Low Power Mode / Battery Saver detection, and Android-specific **"Giảm Lag" (Reduce Lag)** mode for low-tier devices.
- **Multi-platform Support** — Windows, Android, macOS, iOS, Linux.

---

## 🚀 Getting Started

### Prerequisites

- [Flutter SDK](https://flutter.dev/docs/get-started/install) 3.44.0+ (stable channel)
- Dart SDK 3.12.0+

### Installation & Run

```bash
# Clone the repository
git clone https://github.com/ghitatruongle/ga-song.git
cd ga-song

# Install dependencies
flutter pub get

# Run on your current connected device / desktop
flutter run
```

### Build for Release

```bash
# Windows
flutter build windows --release

# Android (APK / App Bundle)
flutter build apk --release --target-platform android-arm64
flutter build appbundle --release

# macOS (DMG / App)
./build_apple.sh 1.0.1-beta macos

# iOS (IPA)
./build_apple.sh 1.0.1-beta ios

# Linux (.deb / bundle)
flutter build linux --release
```

---

## 📁 Project Structure

```
lib/
├── main.dart                    # App entry point, deferred initializations & service binding
├── core/                        # Core business logic & platform layer
│   ├── audio/                   # SoLoud audio engine, equalizer, effects, playlist service
│   ├── database/                # Drift ORM (type-safe SQLite tables & migrations)
│   ├── logging/                 # Structured AppLogger facade
│   ├── motion/                  # Motion tokens, durations, and curves
│   ├── platforms/               # Platform-specific integrations (iOS, macOS, etc.)
│   ├── services/                # Power state, window manager, system tray, hotkeys, SMTC
│   ├── theme/                   # Material 3 tokens, design extensions & color schemes
│   ├── audio_source_cache_policy.dart # Decoded audio caching & idle eviction
│   ├── cover_art_repository.dart      # Cover art caching & background thumbnailing
│   ├── platform_capabilities.dart     # Hardware tier detection & capability queries
│   └── settings_manager.dart          # Persistent user settings (SharedPreferences)
├── models/                      # Immutable data models
├── providers/                   # Riverpod state & service providers
├── ui/                          # UI layer
│   ├── screens/                 # Main screens (Home, Mini Player, KTV, Fullscreen Player)
│   ├── widgets/                 # Reusable UI components & dialogs
│   └── visualizer/              # GPU & CPU audio visualizer controllers
└── l10n/                        # Localization (Vietnamese, English)
```

---

## 🧪 Testing

```bash
# Run all unit and service tests
flutter test test/core test/ui test/providers test/mocks test/widget_test.dart

# Run static analysis
flutter analyze
```

---

## 📄 License

This project is for personal use.

## 👤 Author

**ghitatruongle** — [ghitatruongle@gmail.com](mailto:ghitatruongle@gmail.com)
