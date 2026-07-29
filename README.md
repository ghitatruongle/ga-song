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
├── main.dart                    # App entry point (creates services, Riverpod overrides)
├── core/
│   ├── audio/                   # Audio engine, effects, playlist, lyrics
│   │   ├── audio_engine_service.dart    # SoLoud playback + LRU cache
│   │   ├── audio_effect_service.dart    # EQ, bass, reverb, compressor
│   │   ├── playlist_service.dart        # Playlist management, shuffle
│   │   └── lyric_parser.dart            # LRC/SRT parser
│   ├── database/                # Drift ORM (type-safe SQLite)
│   │   ├── app_database.dart            # Tables, DAOs, migrations
│   │   └── migration/                   # Legacy sqflite → Drift auto-migration
│   ├── services/                # Platform services
│   │   ├── db_service_wrapper.dart      # Drift-backed persistence API
│   │   ├── window_manager_service.dart  # Desktop window management
│   │   ├── system_tray_service.dart     # System tray
│   │   ├── hotkey_service.dart          # Global hotkeys
│   │   └── smtc_service.dart            # Windows media controls
│   ├── settings/                # SettingsState (Freezed) + SettingsNotifier
│   ├── theme/                   # Design tokens, typography, motion
│   ├── logging/                 # Structured AppLogger
│   ├── cover_art_repository.dart        # Cover art 3-tier cache
│   ├── settings_manager.dart            # App settings persistence
│   └── platform_capabilities.dart       # Platform detection
├── models/                      # Data models
│   ├── song.dart
│   ├── playlist.dart
│   └── cover_art_cache.dart
├── providers/                   # Riverpod providers
│   ├── song_provider.dart
│   ├── lyric_provider.dart
│   ├── state_providers.dart
│   └── service_providers.dart
├── ui/                          # User interface
│   ├── screens/                 # App screens
│   │   ├── home_screen.dart
│   │   ├── mini_player_screen.dart
│   │   └── ktv_screen.dart
│   ├── widgets/                 # Reusable widgets
│   │   ├── sidebar.dart
│   │   ├── main_content.dart
│   │   ├── player_bar/
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
│       Service Layer             │  Business Logic
├─────────────────────────────────┤
│        Model Layer              │  Data Classes
└─────────────────────────────────┘
```

- **Dependency Injection**: services created directly in `main()`, injected via Riverpod `ProviderScope.overrides` (no service locator)
- **State Management**: `flutter_riverpod` providers + `ValueNotifier`/`ChangeNotifier` within services
- **Persistence**: `SharedPreferences` (settings) + Drift ORM / SQLite (songs, playlists, cover art, lyrics)

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

The app supports Vietnamese (vi) and English (en). Localization is handled via `lib/l10n/app_localizations.dart`; the language can be switched at runtime in **Settings → Language** (persisted across sessions).

## 📦 Dependencies

| Package | Purpose |
|---------|---------|
| `flutter_soloud` | Native audio engine |
| `flutter_riverpod` | State management & DI |
| `drift` | Type-safe SQLite ORM |
| `audio_service` | Android/Linux media notifications |
| `smtc_windows` | Windows System Media Transport Controls |
| `window_manager` | Desktop window management |
| `hotkey_manager` | Global hotkeys |
| `palette_generator` | Dominant color extraction |

## 📄 License

This project is for personal use.

## 👤 Author

**ghitatruongle** — [ghitatruongle@gmail.com](mailto:ghitatruongle@gmail.com)
