# Architecture

## Overview

G.A - Song follows a **layered architecture** with clear separation of concerns.

## Layers

```
┌─────────────────────────────────────────────┐
│                 UI Layer                     │
│  Screens, Widgets, Visualizer, Painters      │
├─────────────────────────────────────────────┤
│              Provider Layer                  │
│  Riverpod Providers (service bridges)        │
├─────────────────────────────────────────────┤
│            View Model Layer                  │
│  PlayerViewModel (ChangeNotifier)            │
├─────────────────────────────────────────────┤
│             Service Layer                    │
│  AudioEngine, Playlist, Effects, Database,   │
│  Settings, CoverArt, Hotkey, SMTC, etc.      │
├─────────────────────────────────────────────┤
│              Model Layer                     │
│  Song, Playlist, CoverArtCache               │
└─────────────────────────────────────────────┘
```

## Data Flow

### Audio Playback Flow

```
User taps song
    → HomeScreen calls PlaylistService.playSongAt(index)
    → PlaylistService calculates normalization gain
    → AudioEngineService.playAsset(assetPath, gain)
        → LRU cache lookup (ensureSource)
        → SoLoud.loadMem() if cache miss
        → SoLoud.play() → returns SoundHandle
    → Position timer starts (250ms desktop / 500ms Android)
    → Song completion stream → PlaylistService._onSongCompleted()
    → Next song based on PlayMode (sequential/repeat/shuffle)
```

### Settings Flow

```
User changes setting
    → Widget calls SettingsManager.setXxx(value)
    → ValueNotifier.value updated (triggers UI rebuild)
    → SharedPreferences.setXxx() (persists to disk)
    → AudioEffectService.setXxx() (if audio-related)
```

## Dependency Injection

The app uses a **dual DI system**:

1. **`get_it`** — Service locator for service-to-service wiring at startup
2. **`flutter_riverpod`** — Widget tree injection via `ProviderScope` overrides

```dart
// service_locator.dart — registers all services
setupServiceLocator();

// main.dart — bridges get_it to Riverpod
ProviderScope(
  overrides: [
    audioEngineServiceProvider.overrideWithValue(sl<AudioEngineService>()),
    // ...
  ],
  child: App(),
);
```

## Caching Strategy

### Audio Sources (AudioEngineService)
- **LRU cache** with platform-aware limits (50 desktop / 20 Android)
- Preloads next song for gapless playback
- Evicts least-recently-used when full

### Cover Art (CoverArtRepository)
- **3-tier cache**:
  1. In-memory LRU `ImageProvider` cache
  2. SQLite disk cache (persists across sessions)
  3. Source files (assets or local files)
- Memory pressure handler clears in-memory cache

### Settings (SettingsManager)
- `SharedPreferences` for persistence
- `ValueNotifier` for reactive UI updates
- 40+ individual notifiers grouped by category

## Platform Abstraction

`PlatformCapabilities` provides runtime platform detection:

```dart
PlatformCapabilities.instance.isDesktop    // Windows/Linux/macOS
PlatformCapabilities.instance.isAndroid
PlatformCapabilities.instance.isWindows
PlatformCapabilities.instance.supportsMica  // Windows 11+
PlatformCapabilities.instance.deviceTier    // high/mid/low
```

Each platform gets tuned values for:
- Timer intervals, cache sizes, particle counts
- Blur sigma, visualizer frame budget, preload concurrency
