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
│  Riverpod Providers (service bridges +       │
│  state providers)                            │
├─────────────────────────────────────────────┤
│             Service Layer                    │
│  AudioEngine, Playlist, Effects, Database    │
│  (Drift), Settings, CoverArt, Hotkey, SMTC   │
├─────────────────────────────────────────────┤
│              Model Layer                     │
│  Song, Playlist, CoverArtCache               │
└─────────────────────────────────────────────┘
```

> Note: the former View Model layer (`PlayerViewModel`) was removed in Phase 2
> (state consolidation). Widgets now consume state providers directly.

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

Services are constructed **directly in `main()`** (no service locator) and
injected into the widget tree via **Riverpod `ProviderScope.overrides`**:

```dart
// main.dart — services created directly, then bridged to Riverpod
final engineService = AudioEngineService();
final playlistService = PlaylistService(engineService, effectService, dbService);

runApp(
  ProviderScope(
    overrides: [
      audioEngineServiceProvider.overrideWithValue(engineService),
      playlistServiceProvider.overrideWithValue(playlistService),
      // ...
    ],
    child: GASongApp(home: initialScreen),
  ),
);
```

> Note: the earlier `get_it` service locator was removed in v1.1.0 —
> Riverpod overrides are the single DI mechanism.

## Caching Strategy

### Audio Sources (AudioEngineService)
- **LRU cache** with platform-aware limits (50 desktop / 20 Android)
- Preloads next song for gapless playback
- Evicts least-recently-used when full

### Cover Art (CoverArtRepository)
- **3-tier cache**:
  1. In-memory LRU `ImageProvider` cache
  2. Drift/SQLite disk cache (persists across sessions)
  3. Source files (assets or local files)
- Memory pressure handler clears in-memory cache

### Settings (SettingsManager)
- `SharedPreferences` for persistence
- `ValueNotifier` for reactive UI updates
- 40+ individual notifiers grouped by category

## Persistence

- **Drift ORM** (`lib/core/database/app_database.dart`) — type-safe SQLite
  access for songs, playlists, cover art cache, and lyrics cache.
  `DatabaseServiceWrapper` exposes the service-facing API.
- **`MigrationService`** — one-time auto-migration of legacy raw-sqflite data
  (v0.1.x) into Drift; the old DB file is renamed, not deleted.
- **`SharedPreferences`** — app settings via `SettingsManager`.

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
