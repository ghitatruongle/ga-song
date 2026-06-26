# 🎵 G.A - Song

A full-featured, cross-platform music player built with Flutter. Supports local audio playback, KTV (karaoke), online YouTube, equalizer, audio effects, visualizer, lyrics display, and system integration.

## ✨ Features

- **Audio Playback** — Local file playback with SoLoud engine, crossfade, gapless
- **Equalizer** — 5-band parametric EQ with presets (Normal, Bass+, Vocal, Acoustic)
- **Audio Effects** — Bass boost, pitch shift, reverb, compressor, normalization
- **Visualizer** — Real-time audio-reactive particle/starfield visualizer
- **KTV Mode** — Karaoke with microphone input and YouTube integration
- **Lyrics** — LRC and SRT format support with synced display
- **Playlist Management** — Create, edit, shuffle, repeat modes
- **Cover Art** — Automatic cover art extraction and caching
- **System Integration** — System tray, global hotkeys, media keys
- **Multi-platform** — Windows, Android, Linux (macOS/iOS/Web partial)

## 🚀 Getting Started

### Prerequisites

- [Flutter SDK](https://flutter.dev/docs/get-started/install) 3.32.0+
- Dart SDK 3.11.4+

### Installation

```bash
# Clone the repository
git clone https://github.com/ghitatruongle/ga-song.git
cd ga-song

# Install dependencies
flutter pub get

# Run the app
flutter run
```

### Build for Release

```bash
# Windows (MSIX)
flutter build windows --release

# Android (APK)
flutter build apk --release

# Linux
flutter build linux --release
```

## 📁 Project Structure

```
lib/
├── main.dart                    # App entry point
├── core/
│   ├── audio/                   # Audio engine, effects, playlist, lyrics
│   │   ├── audio_engine_service.dart    # SoLoud playback + LRU cache
│   │   ├── audio_effect_service.dart    # EQ, bass, reverb, compressor
│   │   ├── playlist_service.dart        # Playlist management, shuffle
│   │   └── lyric_parser.dart            # LRC/SRT parser
│   ├── services/                # Platform services
│   │   ├── database_service.dart        # SQLite persistence
│   │   ├── window_manager_service.dart  # Desktop window management
│   │   ├── system_tray_service.dart     # System tray
│   │   ├── hotkey_service.dart          # Global hotkeys
│   │   └── smtc_service.dart            # Windows media controls
│   ├── view_models/             # View models (ChangeNotifier)
│   ├── cover_art_repository.dart        # Cover art 3-tier cache
│   ├── settings_manager.dart            # App settings persistence
│   ├── platform_capabilities.dart       # Platform detection
│   └── service_locator.dart             # Dependency injection (get_it)
├── models/                      # Data models
│   ├── song.dart
│   ├── playlist.dart
│   └── cover_art_cache.dart
├── providers/                   # Riverpod providers
│   ├── song_provider.dart
│   ├── lyric_provider.dart
│   └── service_providers.dart
├── ui/                          # User interface
│   ├── screens/                 # App screens
│   │   ├── home_screen.dart
│   │   ├── mini_player_screen.dart
│   │   └── ktv_screen.dart
│   ├── widgets/                 # Reusable widgets
│   │   ├── sidebar.dart
│   │   ├── main_content.dart
│   │   ├── bottom_player_bar/
│   │   └── ...
│   ├── visualizer/              # Audio visualizer
│   └── painters/                # Custom painters
└── l10n/                        # Localization (vi, en)
```

## 🏗️ Architecture

The app follows a layered architecture:

```
┌─────────────────────────────────┐
│           UI Layer              │  Widgets, Screens
├─────────────────────────────────┤
│        Provider Layer           │  Riverpod Providers
├─────────────────────────────────┤
│      View Model Layer           │  ChangeNotifier
├─────────────────────────────────┤
│       Service Layer             │  Business Logic
├─────────────────────────────────┤
│        Model Layer              │  Data Classes
└─────────────────────────────────┘
```

- **Dependency Injection**: `get_it` (service locator) + `flutter_riverpod` (widget tree)
- **State Management**: `ValueNotifier` / `ChangeNotifier` with `ValueListenableBuilder`
- **Persistence**: `SharedPreferences` (settings) + `sqflite` (songs, playlists, cover art)

## 🧪 Testing

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# Run specific test file
flutter test test/core/audio/playlist_service_test.dart
```

## 🌍 Localization

The app supports Vietnamese (vi) and English (en). Localization is handled via `lib/l10n/app_localizations.dart`.

## 📦 Dependencies

| Package | Purpose |
|---------|---------|
| `flutter_soloud` | Native audio engine |
| `flutter_riverpod` | State management |
| `get_it` | Service locator |
| `sqflite` | SQLite database |
| `audio_service` | Android/Linux media notifications |
| `smtc_windows` | Windows System Media Transport Controls |
| `window_manager` | Desktop window management |
| `hotkey_manager` | Global hotkeys |
| `palette_generator` | Dominant color extraction |

## 📄 License

This project is for personal use.

## 👤 Author

**ghitatruongle** — [ghitatruongle@gmail.com](mailto:ghitatruongle@gmail.com)
