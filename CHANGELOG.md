# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [0.5.0] — 2026-07-26

### 🚀 Major Update (The "Next-Gen" Architecture)

#### Core & Architecture
- **Drift ORM Migration**: Completely replaced raw `sqflite` with `Drift` for type-safe database queries and reactive streams.
- **Auto Data Migration**: Safely migrates user playlists and play history from v0.1.x without data loss via `MigrationService`.
- **Riverpod 3.0**: Upgraded state management to modern `NotifierProvider` and removed obsolete `StateNotifier`.

#### UI/UX & Material 3
- **Dynamic Color (Color Seed)**: The app's entire theme now automatically extracts and adapts to the dominant color of the currently playing song's cover art using `PaletteGenerator`.
- **Haptic Feedback**: Added `FeedbackService` to trigger highly satisfying subtle physical vibrations on user interactions (play, pause, next, sliders).

#### New Features
- **Smart Playlists**: Auto-generated dynamic playlists based on user listening history (Most Played, Recently Played, Favorites, Recently Added, Discovery).
- **Tag Editor**: View and modify internal ID3 audio tags (Title, Artist, Album, Year, Genre) of local files directly within the app using `audiotags`.

## [0.1.5] — 2026-07-25

### Android — Performance Boost
- **Native build optimization** — R8 full mode enabled for debug/profile builds;
  native lib compression (`useLegacyPackaging = false`); `arm64-v8a`-only release
  builds reduce APK size by ~30%; `noCompress` for `.so` files prevents double-compression.
- **Dart layer tuning** — Preload concurrency increased from 2→3 on Android mid-tier;
  max audio source cache entries increased from 20→32; visualizer frame budget
  reduced from 22ms→18ms (tận dụng màn hình 90Hz); added `androidFrameRateHz`
  detection for adaptive performance.
- **Native code** — Added `onTrimMemory()` override for memory pressure handling;
  optimized PiP mode with reduced texture size; added `onConfigurationChanged()`
  to prevent activity recreation on rotation.

### PC (Windows/Linux) — UX Enhancements
- **Window management** — Added Mica Alt Tab effect (`WindowEffectType.tabbed`)
  for Windows 11 23H2+; reduced resize debounce from 100ms→50ms; added DPI-aware
  window scaling for multi-monitor setups.
- **System tray** — Added album art + song info display; added progress bar
  (position/duration); reduced menu rebuild debounce from 1000ms→500ms.
- **Global hotkeys** — Added seek forward/backward (10s) via media keys;
  added double-tap space detection for play/pause; reduced debounce from 150ms→100ms.
- **Desktop lyrics overlay** — Added fade-in/fade-out animations (300ms ease-in-out);
  improved click-through toggle with visual feedback.

## [0.1.1] — 2026-07-22

### Fixed
- **Audio effect service** — `dispose()` now deactivates SoLoud filters
  (bass, EQ, pitch shift, reverb, compressor) and resets their `wet`
  values to `0.0` before teardown. Wrapped in try/catch with `AppLogger.w`
  to remain safe if the engine is already shut down.
- **Audio engine service** — Cancel prior `_songEndSub` before
  re-subscribing in `_play` and `_playNext`. Cancellation is also ensured
  in `dispose()`. Eliminates duplicate "song ended" callbacks when the
  same source is replayed.
- **Cover art repository** — `dispose()` now clears `_entryFutures`,
  `_entries`, `_providerCache`, and `_dominantColorFutures` to release
  cache memory on shutdown.

### Changed
- **Lyric provider** — `_databaseService` typed as `DatabaseService`
  instead of `dynamic`; redundant `as String?` casts removed on
  `cached['syncedLyrics']` / `cached['plainLyrics']` lookups.
- **Cover art repository** — Re-formatted tab-indented block to standard
  2-space indentation; parentDir/replaceFirst string concatenations
  wrapped in `${...}` for clarity.
- **Database service** — Removed unused `package:flutter/foundation.dart`
  import.
- **Web audio player** — Added `avoid_dynamic_calls` to `ignore_for_file`
  directive.

### Tests
- Removed unused `_wrap` helper in `test/core/theme_utils_test.dart`.
- Removed unused `lastValue` local in 2 debounced slider tests.

### Notes
- All 7 modified tests pass; no new analyzer issues introduced
  (13 pre-existing `info`-level lints remain, unchanged).
- Backward compatibility: no public API changes.

## [Unreleased]

### Phase 4: UI Polish & Motion Language

**Changed:**

- **AppColors collision resolved** — Legacy `app_colors.dart` (97 lines, 38+ fields) folded into `tokens.dart`. Single `AppColors` class is now the canonical source. Deleted `app_colors.dart`. `surface(context, level)` helper renamed to `surfaceFor(...)` to avoid colliding with the `surface` Material 3 seed field; legacy semantic `error` color exposed as `danger`.
- **Token migration in 6 widget files** — Replaced 12 hardcoded `Color(0xFF...)` literals in `playlist_manager_widget.dart`, `settings_widget.dart`, `sleep_timer_dialog.dart`, `sort_filter_dialog.dart`, `tag_editor_dialog.dart`, `song_tiles.dart` with `AppColors.darkX`/`lightX` constants. `Color(0x` count in `lib/ui/` is now **0**.
- **Global page transition** — `pageTransitionsTheme` in `ThemeData` (both light and dark) routes every `MaterialPageRoute` through `MotionPageTransitionsBuilder` (fade-through + slide via `AppMotion.slideUpFade`, 300ms, decelerate). Honors `MediaQuery.disableAnimations`.
- **Theme switch cross-fade** — `MaterialApp` wrapped in `AnimatedTheme` (600ms, `AppCurves.emphasized`). Smooth transition between light/dark themes.
- **Haptic feedback (Android)** — New `safeHaptic(HapticType)` helper. Wired to:
  - `center_controls.dart` — play (medium), next/prev (light)
  - `mini_player_screen.dart` — desktop + mobile play (medium), next/prev (light)
  - `equalizer_widget.dart` — EQ band slider release (light)
- **Sound feedback opt-in** — New `soundFeedbackEnabled: bool` field on `SettingsState` (default false). `SettingsManager` persists to SharedPreferences. `SystemSound.click` plays on next/prev when enabled. Settings UI toggle added under "Phím tắt & Media Keys".
- **Card hover/press animation** — `AnimatedContainer` (`AppDurations.short`, `AppCurves.decelerate`, scale 1.0 → 1.02 on hover → 0.98 on press) on `_AlbumTile` (with `MouseRegion` + `GestureDetector` lifecycle). `_DuplicateGroup` gets a softer 1.0 → 1.01 hover with border + shadow. `SongGridTile` wrapped in `AnimatedContainer` for animation parity. Honors `MediaQuery.disableAnimations`.
- **EQ slider waveform pulse** — Per-band slider extracted to `_BandSliderWidget` (StatefulWidget). `AnimatedContainer` `boxShadow` glow tied to `_isDragging` state via `DebouncedSlider.onChangeStart`/`onChangeEnd`.
- **Lyric transition cross-fade** — Active lyric line `Text` wrapped in `AnimatedSwitcher` (300ms, `FadeTransition`). Keyed by `line.startTime.inMilliseconds` so Flutter triggers the transition on line change.

**Added:**

- `lib/core/theme/motion_page_transitions_builder.dart` — `MotionPageTransitionsBuilder extends PageTransitionsBuilder`.
- `lib/ui/utils/animation_utils.dart` — `animationsEnabled(BuildContext)` helper (gates on `MediaQuery.disableAnimations`).
- `lib/ui/utils/haptic_helper.dart` — `safeHaptic(HapticType.light | medium)` Android-gated.
- `lib/core/settings/settings_state.dart` — `soundFeedbackEnabled` field.
- `lib/core/settings_manager.dart` — `soundFeedbackEnabledNotifier` + `setSoundFeedbackEnabled` (persisted to SharedPreferences).
- `lib/ui/widgets/debounced_slider.dart` — `onChangeStart` / `onChangeEnd` parameters (forwarded to inner `Slider`).

**Tests:**

- 13 tests for merged `AppColors` fields and helpers (`test/core/theme/tokens_appcolors_merged_test.dart`).
- 3 tests for `MotionPageTransitionsBuilder` (`test/core/theme/motion_page_transitions_builder_test.dart`).
- 2 tests for `animationsEnabled` helper (`test/ui/utils/animation_utils_test.dart`).
- 2 tests for `safeHaptic` helper (`test/ui/utils/haptic_helper_test.dart`).
- 2 tests for `soundFeedbackEnabled` field (`test/core/settings/settings_state_sound_test.dart`).

Test count delta: 559 baseline → **582 passing** (+23).

**Notes:**

- **Bottom player bar scroll show/hide** — DEFERRED. Complex scroll-listener wiring. Not in current spec scope.
- **Per-song accent color extraction** — DEFERRED to Phase 7+. Requires `palette_generator` integration with theme switching.
- **Backward compatibility** — `SettingsState.soundFeedbackEnabled` defaults to `false`. Users opt-in. No data migration needed.


## [0.1.0] — 2026-07-21

### Changed
- Replaced ~113 `debugPrint` calls with structured `AppLogger` (levels: debug/info/warn/error/fatal). Tags follow `module.class` convention (e.g., `audio.engine_service`, `database.service`).
- `AppLogger` initialized in `main.dart` with level filtering (`debug` in debug mode, `warn+` in release) and optional crash-reporter mirroring.
- Completed `debugPrint → AppLogger` migration in `lib/core/audio/audio_engine_service.dart` (16 calls) and `lib/core/audio/playlist_service.dart` (1 call). All 17 calls now use structured logging with tags, error, and stack trace.

### Added
- `lib/core/logging/app_logger.dart` — `AppLogger` static facade with pluggable sink and pending crash-report buffer.
- `DatabaseService.querySongs()` — Result-returning variant (`Result<List<Song>>`) wrapping typed `AppException` in `Failure.exception`. Legacy `getAllSongs()` retained for backward compatibility.
- `test/core/logging/app_logger_test.dart` — 7 unit tests covering level filtering, sink swapping, error/stack trace handling.
- `test/core/services/database_service_query_test.dart` — 2 unit tests for the new Result-returning method.
- `lib/core/theme/tokens.dart` — design tokens (colors, spacing, radius, elevation) as single source of truth.
- `lib/core/theme/theme_extensions.dart` — `AppSpacingExtension`, `AppRadiusExtension`, `AppElevationExtension` (ThemeExtension wrappers).
- `lib/core/motion/app_motion.dart` — `AppDurations`, `AppCurves`, `MotionPreferences`, `AppMotion` signature animations.

### Tests
- 5 tests for `tokens.dart`.
- 9 tests for `theme_extensions.dart`.
- 8 tests for `app_motion.dart`.
- 128 audio tests + 56 playlist tests + foundation tests all pass.

### Notes
- `lib/core/app_logger.dart` is now a re-export shim for the canonical `lib/core/logging/app_logger.dart`.
- AppException types imported with `as app_exc` alias in `database_service.dart` to avoid collision with sqflite's `DatabaseException`.
- Latent name collision between new `AppColors` class (in `tokens.dart`) and existing `AppColors` class (in `app_colors.dart`). Documented as TODO at top of `tokens.dart` for Phase 4 reconciliation. Both classes are dormant today (no file imports both).

### Phase 2: State Management Consolidation

**Added:**
- `lib/ui/screens/home_screen_uses_providers_test.dart` — smoke test verifying settingsNotifierProvider resolves under test container.
- `lib/ui/screens/mini_player_uses_providers_test.dart` — smoke test verifying service providers resolve.

**Changed:**
- `lib/ui/screens/home_screen.dart` — replaced imperative `_settingsManager.*Notifier.addListener(...)` (sortMode, sortAscending, currentTabIndex) with `ref.listen<...>(settingsNotifierProvider.select((s) => ...))` — single rebuild per state change instead of per-notifier.
- `lib/ui/widgets/visualizer_widget.dart` — replaced `_visualizerController.addListener(_syncRotationState)` + `removeListener` with a top-level `ListenableBuilder`. The imperative `_syncRotationState()` is called inside the builder so `AnimationController` advances correctly on every controller notify (Phase 2.2 critical fix).
- `lib/ui/screens/mini_player_screen.dart` — replaced 4 `ref.read(playerViewModelProvider)` reads + 22 `viewModel.xxx` calls with direct consumption of `positionProvider` / `trackDurationProvider` / `engineStateProvider` / `playlistServiceProvider` / `audioEngineServiceProvider`.
- `lib/main.dart` — dropped `PlayerViewModel` instantiation (line 127 was) and `playerViewModelProvider.overrideWithValue` (line 235 was).
- `lib/providers/service_providers.dart` — dropped `playerViewModelProvider` declaration.

**Removed:**
- `lib/core/view_models/player_view_model.dart` — deprecated `@Deprecated('Use state providers from lib/providers/state_providers.dart')` class deleted entirely. The class was already a transitional facade.

### Notes
- 4 widget files (`bottom_player_bar.dart`, `player_bar/center_controls.dart`, `play_mode_button.dart`, `progress_bar.dart`) preserve historical doc comments referencing the old PlayerViewModel API — these are migration provenance notes and harmless.
- `lib/ui/visualizer/visualizer_controller.dart` still uses 2 internal `addListener` for `AudioEngineService.engineState` and `SettingsManager.visualizerEnabledNotifier`. These subscribe to *upstream* services; the migration target was consumer-side widgets only. Out of scope for Phase 2.

### Phase 3: Performance & Responsiveness

**Changed:**

- **Slider debouncing** — Migrated remaining raw `Slider` widgets to `DebouncedSlider` (250ms for EQ + Bass Boost, 200ms for audio effects, 80ms for volume). Affected: `equalizer_widget.dart` (5 EQ bands + 1 Bass Boost), `audio_effects_dialog.dart` (4 named sliders + 9 sub-params), `accessible_widgets.dart` (volume). Per-slider tuning rationale: EQ is most expensive (calls `applyAllEqualizer` + `setBassLevel` per pixel), volume must feel responsive.
- **DebouncedSlider API extended** with `divisions` + `label` parameters. Previously lost in Task 1 migration; now restored to all 4 audio effect sliders (crossfade, normalization, pitch, sub-params) so they retain snap-to-grid behavior and live value readouts.
- **Visualizer isolate (minimal first-pass)** — `computeStarField` extracted to top-level function in `visualizer_controller.dart`. Per-frame heavy compute (HSV→RGB color palette + star position math) runs on a Dart isolate via `compute()`. Painter refactor (Task 2.5) deferred — current implementation captures `_frameSnapshot` but does not yet consume it. Painter still reads existing internal lists; no user-visible change.
- **Cover art TTL** — `CoverArtEntry` now carries `capturedAt` timestamp with `isFresh({ttl})` helper. 30-minute TTL applied on top of existing LRU; stale entries are evicted on access even if LRU hasn't pushed them out. Conservative setting per spec.
- **Position timer lifecycle** — `AudioEngineService` now implements `WidgetsBindingObserver`. Position timer pauses on `AppLifecycleState.paused/hidden/inactive/detached` and resumes on `resumed` only if `engineState == AudioEngineState.playing`. Reuses existing `_pausePositionTimer()` / `_startPositionTimer()` methods; no new state fields.
- **Startup deferred init** — Hotkey + system tray init (was on a 500ms timer) moved into `WidgetsBinding.instance.addPostFrameCallback` placed before `runApp(...)`. First frame now renders without waiting for desktop service init. Critical init (SoLoud, SettingsManager, DatabaseService, AudioEngineService, EQ) stays synchronous.

**Tests:**

- 1 smoke test for `DebouncedSlider` widget inflation
- 2 widget tests for `DebouncedSlider` divisions + label passthrough
- 3 unit tests for `StarFieldSnapshot` / `StarFieldComputeInput`
- 3 unit tests for `CoverArtEntry` timestamp + freshness
- 6 unit tests for `AudioEngineService` lifecycle wiring (mocks updated)
- 2 smoke tests for `addPostFrameCallback` mechanism

Expected test count: ≥539.

### Notes

- **Task 2.5 (visualizer painter refactor)** is deferred to a future phase. The current `_frameSnapshot` is captured but unused — the painter continues to read from the existing `_stars` / `_particles` lists. When wired up, Task 2.5 will need to choose between adding a new field to `VisualizerFrameSnapshot` or replacing its `stars` field with `StarFieldSnapshot`.
- **Position timer resume gating** is stricter than the plan called for: timer only resumes if `engineState == AudioEngineState.playing`, not just on `AppLifecycleState.resumed`. Prevents spinning up the timer when no song is active.
- **Backward compatibility**: `CoverArtEntry`'s `capturedAt` defaults to `DateTime.now()`, so existing call sites are unaffected. `DebouncedSlider`'s `divisions` and `label` parameters are optional — old call sites compile unchanged.

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
