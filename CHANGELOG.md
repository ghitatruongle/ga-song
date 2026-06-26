# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [2.0.0] — 2026-06-26

### Added

#### Phase 1: Code Cleanup & Foundation
- Removed dead code (`service_locator.dart`)
- Added `SettingsState` with Freezed for immutable state management
- Added `SettingsNotifier` with Riverpod for clean state API
- Added `Result<T>` type for type-safe error handling
- Added `AppException` hierarchy (Database, AudioEngine, Network, File, Cache, Settings, Parse, Platform)
- Added `ErrorHandlerService` for centralized error handling
- Updated lint rules in `analysis_options.yaml`
- Added migration guide documentation

#### Phase 2: Database & Performance
- Added Drift ORM for type-safe database access
- Created database table definitions (Songs, Playlists, PlaylistSongs, CoverArtCache, LyricsCache)
- Added 7 database indexes for query performance
- Added database migration strategy (v1 → v2 → v3)
- Added `LRUCache<K, V>` for in-memory caching
- Added `PerformanceService` for operation timing and metrics
- Added `LazyList<T>` for paginated data loading

#### Phase 3: UI/UX Modernization
- Added `Breakpoints` constants for responsive design
- Added `ResponsiveLayout` widget for mobile/tablet/desktop layouts
- Added `ResponsiveGrid` widget for adaptive grid columns
- Added `ResponsiveBuilder` + `ScreenSize` for screen size information
- Added `AccessiblePlayButton` with semantics
- Added `AccessibleSongTile` with semantics
- Added `AccessibleVolumeSlider` with semantics
- Added `AppShortcuts` for keyboard navigation (Space, Ctrl+arrows, Ctrl+M)
- Added `AppAnimations` for smooth transitions

#### Phase 4: Platform Enhancement
- Added `MacOSIntegration` for native macOS features
- Added `MacOSMenuBar` with native menu bar items
- Added `IOSIntegration` for native iOS features (widgets, Siri, AirPlay)
- Added `WebIntegration` for web-specific features (PWA, notifications)
- Added `PlatformService` for unified cross-platform API

#### Phase 5: Testing & Quality
- Added 75 new unit tests
- Added tests for `LRUCache`, `LazyList`, `PerformanceService`, `Breakpoints`, `AppException`, `ErrorHandlerService`
- Total tests: 456 (all passing)

### Changed
- Updated version to 2.0.0
- Updated project description
- Applied 39 auto-fixes from `dart fix`
- Fixed lint warnings across codebase

### Dependencies
- Added `drift: ^2.14.0` for type-safe SQLite
- Added `sqlite3_flutter_libs: ^0.5.0` for SQLite native libs
- Added `sqlite3: ^2.4.0` for SQLite Dart bindings
- Added `drift_dev: ^2.14.0` for code generation

## [1.1.0] — 2026-06-23

### Changed
- **Eliminated DI inconsistency**: Removed unused `get_it`/`service_locator.dart` — `main.dart` now exclusively uses Riverpod `ProviderScope.overrides`.
- **Consolidated sort logic**: Extracted shared `SongSortUtils` class eliminating duplicate sort implementations between `home_screen.dart` and `playlist_service.dart`.
- **Named constants**: Replaced magic numbers across `audio_engine_service.dart`, `settings_manager.dart`, and `home_screen.dart` with descriptive constants.
- **Removed dead test code**: Deleted unused `test_helper.dart` (get_it test harness) — all tests now use `test_helpers.dart` factory utilities.

### Added
- **Sort utility tests**: 20+ unit tests covering all sort modes, edge cases (null/empty artist, null duration, null date).
- **Integration test scaffold**: First integration test for app startup and tab navigation flow.
- **GitHub Actions CI workflow**: Build, analyze, and test across Windows, Android, and Linux platforms.
- **Comprehensive CHANGELOG**: Structured changelog following Keep a Changelog format.

### Architecture
- `lib/core/utils/sort_utils.dart` — `SongSortUtils` class provides `sort()`, `sorted()`, and `sortModeFromInt()` with consistent edge-case handling.
- Constants in `settings_manager.dart` define default values and clamp bounds centrally (e.g. `_kDefaultBlurLevel`, `_kEqBandCount`, `_kCompRatioMax`).
- Constants in `audio_engine_service.dart` (`_kCrossfadeSteps`, `_kPositionEpsilonDesktop`, `_kEqRetryCount`).
- Constants in `home_screen.dart` (`_kSidebarWidth`, `_kBackgroundTransition`, `_kPreloadNextSongCount`).

## [1.0.0+1] - 2026-06-21

### Added
- Initial release
- Local audio playback with SoLoud engine
- 5-band parametric equalizer with presets (Normal, Bass+, Vocal, Acoustic)
- Audio effects: bass boost, pitch shift, reverb, compressor, normalization
- Crossfade between songs
- Real-time audio visualizer (particle/starfield)
- KTV mode with microphone input
- YouTube player integration
- LRC and SRT lyrics support with synced display
- Playlist management with shuffle, repeat, play-one-stop modes
- Cover art extraction and 3-tier caching (memory → disk → source)
- System tray integration (Windows/Linux)
- Global hotkey support
- Windows System Media Transport Controls (SMTC)
- Linux MPRIS media controls
- Android audio service notifications
- Android Picture-in-Picture mode
- Mini player mode
- Sleep timer
- Dark/Light theme with dynamic color support
- Mica/Acrylic window effects (Windows 11+)
- Multi-language support (Vietnamese, English)
- SQLite database for songs, playlists, cover art cache
- CI/CD pipeline with GitHub Actions (Windows, Android, Linux builds)
- 325+ unit and widget tests
