# Balanced Evolution — G.A - Song Comprehensive Improvements

**Date:** 2026-06-30
**Author:** ZCode
**Status:** Approved
**Scope:** Cross-cutting improvements (architecture + performance + UI/UX + testing)
**Approach:** Evolution (backward-compatible, incremental)

---

## 1. Overview

This design covers a 6-phase evolution of G.A - Song addressing technical debt, performance, UI modernization, and test coverage. Each phase is independently shippable, preserves user data, and can be paused between phases.

**Goals:**
1. Reduce technical debt (mixed state management, dead code patterns, debug print noise)
2. Improve runtime performance (visualizer, list rendering, debouncing)
3. Modernize UI (Material 3, accessibility, responsive)
4. Increase confidence (test coverage, CI quality gates)

**Non-goals:**
- No breaking changes to existing user data (DB schema, SharedPreferences)
- No new platform support (macOS/iOS/Web stay at "partial")
- No feature additions (KTV is already extensive)

**Estimated total effort:** ~9–10 weeks (single developer, ~50% capacity)

---

## 2. Current State Analysis

### 2.1 Strengths
- Clear layered architecture (UI → Provider → ViewModel → Service → Model)
- 456 unit tests passing
- Drift ORM already defined (`app_database.dart`) with generated code
- `SettingsState` (Freezed) and `SettingsNotifier` (Riverpod) introduced in v2.0.0
- LRU cache for audio sources with platform-aware limits
- Cross-platform support: Android, Windows, Linux (primary); macOS/iOS/Web (partial)

### 2.2 Issues Identified

| Category | Specific Issues |
|----------|-----------------|
| **State Management** | 80 `ValueNotifier` + 2 `ChangeNotifier` + 722 Riverpod references coexist. `SettingsNotifier` is a manual snapshot, not a true reactive wrapper. `PlayerViewModel` extends `ChangeNotifier`. Multiple `addListener` calls in widgets instead of `ref.listen`. |
| **Error Handling** | 113 `debugPrint` calls scattered across `lib/` (mostly in audio engine and services). 3 patterns coexist: `debugPrint + return null`, `throw AppException`, silent catch. `Result<T>` and `AppException` defined but rarely used. |
| **Database** | Raw sqflite (`database_service.dart`) used in production. Drift schema (`app_database.dart`) defined but unused. Two parallel DB definitions. |
| **Performance** | Visualizer runs entirely on main thread (potential frame drops on low-end devices). `album_grid_widget.dart` uses `GridView.count` (not lazy). No debouncing on settings sliders. Position timer ticks even when window minimized. |
| **UI/UX** | `main.dart` uses manual `ThemeData.copyWith` (not Material 3). `ColorScheme` incomplete (3 of 30+ fields). Hard-coded colors in `main.dart`. Responsive layout exists but mobile UX not polished. Accessibility widgets defined but not consistently applied. |
| **Testing** | Test/source ratio ~37% (40 test files vs 109 source files). No tests for `audio_engine_service.dart`, `smtc_service.dart`, `hotkey_service.dart`, `window_manager_service.dart`, visualizer. Integration test minimal. |
| **CI/Quality** | CI builds Windows/Android/Linux. No `dart analyze` step. No coverage reporting. No performance budget. |

---

## 3. Phase Plan

| # | Phase | Duration | Primary Outcome |
|---|-------|----------|-----------------|
| 1 | Foundation & Error Handling | 1 week | AppLogger + `Result<T>` adopted codebase-wide |
| 2 | State Management Consolidation | 2 weeks | SettingsNotifier + PlayerNotifier; legacy ValueNotifier isolated |
| 3 | Performance | 2 weeks | Visualizer isolate, list virtualization, debouncing |
| 4 | UI/UX Modernization | 1.5 weeks | Material 3, accessibility audit, mobile polish |
| 5 | Test Coverage | 2 weeks | 70%+ coverage on `lib/core/`, integration tests expanded |
| 6 | Polish & CI | 1 week | Quality gates, performance budgets, docs |

---

## 4. Phase 1 — Foundation & Error Handling

### 4.1 Problem
- 113 `debugPrint` calls with no level filtering, no context, no integration with crash reporter
- 3 different error handling patterns coexist
- `Result<T>` (lib/core/utils/result.dart) and `AppException` (lib/core/exceptions/app_exception.dart) exist but underused

### 4.2 Solution

#### 4.2.1 AppLogger service
Create `lib/core/logging/app_logger.dart`:

```dart
enum LogLevel { debug, info, warn, error, fatal }

class AppLogger {
  static LogLevel _minLevel = LogLevel.debug;
  static void Function(String line)? _sink;

  static void init({
    LogLevel minLevel = LogLevel.debug,
    void Function(String line)? sink,
    bool mirrorToCrashReporter = false,
  }) {
    _minLevel = minLevel;
    _sink = sink ?? (kDebugMode ? _debugPrintSink : _noopSink);
    _mirrorToCrashReporter = mirrorToCrashReporter;
  }

  static void d(String tag, String message, {Object? error, StackTrace? stack}) { ... }
  static void i(String tag, String message) { ... }
  static void w(String tag, String message, {Object? error, StackTrace? stack}) { ... }
  static void e(String tag, String message, {Object? error, StackTrace? stack}) { ... }
  static void f(String tag, String message, {Object? error, StackTrace? stack}) { ... }
}
```

- Initialize in `main.dart` before any service init
- `kDebugMode` → `debugPrint` sink; `!kDebugMode` → optional file sink (7-day rotation)
- Mirror `fatal` to `DebugCrashReporter.reportError`
- Tag convention: `'<module>.<class>'`, e.g., `'audio.engine_service'`

#### 4.2.2 Migrate debugPrint → AppLogger
Replace all 113 `debugPrint` calls with appropriate level:

| Original | Replacement |
|----------|-------------|
| `debugPrint('Error: $e')` in catch block | `AppLogger.e('module.tag', 'message', error: e, stack: stack)` |
| `debugPrint('Init failed: ...')` | `AppLogger.w('module.tag', 'message')` |
| `debugPrint('Cache size: N')` | `AppLogger.d('module.tag', 'message')` (debug only) |

**Files touched:** ~30 files including all of `lib/core/audio/`, `lib/core/services/`, `lib/core/cover_art_repository.dart`.

#### 4.2.3 Result<T> adoption (incremental)
- New public APIs that can fail should return `Result<T, AppException>`
- Existing APIs keep their signatures; refactor when called code already migrates
- Helper extension on `Future<T>`:

```dart
extension FutureResultX<T> on Future<T> {
  Future<Result<T, AppException>> toResult() async {
    try {
      return Success(await this);
    } on AppException catch (e, st) {
      AppLogger.e('future', 'Operation failed', error: e, stack: st);
      return Failure(e);
    } catch (e, st) {
      final ex = AppException.unknown(e.toString());
      AppLogger.e('future', 'Unexpected error', error: e, stack: st);
      return Failure(ex);
    }
  }
}
```

### 4.3 Acceptance Criteria
- [ ] All 113 `debugPrint` calls replaced with `AppLogger.*`
- [ ] `flutter analyze` reports 0 warnings
- [ ] Release build logs only `warn`/`error`/`fatal`
- [ ] `lib/core/services/database_service.dart` public methods return `Result` for top-level queries (getSongs, getPlaylists, addSong, deleteSong)
- [ ] No new exceptions introduced in existing test suite (456 tests still pass)

### 4.4 Backward Compatibility
- `AppLogger` is additive — no existing API changes
- `Result<T>` adoption is incremental; existing methods keep their signatures
- SharedPreferences keys unchanged

---

## 5. Phase 2 — State Management Consolidation

### 5.1 Problem
- `SettingsNotifier` (`lib/core/settings/settings_notifier.dart`) is a manual snapshot wrapper. `build()` reads 40+ `.value` calls once. Every setter manually calls `state = state.copyWith(...)`. This duplicates work and creates inconsistency window.
- `PlayerViewModel extends ChangeNotifier` — old pattern, easy to leak listeners
- 5+ widgets use manual `addListener` instead of `ref.listen`
- 80 `ValueNotifier` instances scattered across services

### 5.2 Solution

#### 5.2.1 SettingsNotifier — true reactive wrapper
Replace current snapshot approach with subscription-based pattern:

```dart
class SettingsNotifier extends Notifier<SettingsState> {
  late SettingsManager _manager;
  final List<VoidCallback> _disposers = [];

  @override
  SettingsState build() {
    _manager = ref.watch(settingsManagerProvider);
    _subscribeToManager();
    ref.onDispose(() {
      for (final d in _disposers) d();
    });
    return _stateFromManager(_manager);
  }

  void _subscribeToManager() {
    // Auto-refresh when ANY underlying ValueNotifier changes
    for (final notifier in _manager.allNotifiers) {
      _disposers.add(notifier.addListener(refresh));
    }
  }

  void refresh() {
    state = _stateFromManager(_manager);
  }

  // Setters become one-liners — state auto-syncs via subscription
  Future<void> setThemeMode(ThemeMode mode) => _manager.setThemeMode(mode);
  Future<void> setBlurLevel(double level) => _manager.setBlurLevel(level);
  // ... all other setters
}
```

Helper added to `SettingsManager`:
```dart
List<ValueNotifier<dynamic>> get allNotifiers => [
  themeModeNotifier, enableBlurNotifier, blurLevelNotifier,
  // ... 40+ notifiers
];
```

#### 5.2.2 PlayerViewModel → PlayerNotifier (AsyncNotifier)
Convert `lib/core/view_models/player_view_model.dart` from `ChangeNotifier` to Riverpod `AsyncNotifier`:

```dart
class PlayerNotifier extends AsyncNotifier<PlayerState> {
  @override
  Future<PlayerState> build() async {
    final engine = ref.watch(audioEngineServiceProvider);
    final playlist = ref.watch(playlistServiceProvider);

    // Subscribe to engine + playlist changes, emit new PlayerState
    final sub1 = engine.engineState.addListener(_onEngineChanged);
    final sub2 = engine.positionNotifier.addListener(_onPositionChanged);
    final sub3 = playlist.currentIndexNotifier.addListener(_onPlaylistChanged);

    ref.onDispose(() {
      sub1();
      sub2();
      sub3();
    });

    return PlayerState.initial();
  }

  void _onEngineChanged() {
    state = AsyncData(state.value!.copyWith(
      engineState: ref.read(audioEngineServiceProvider).engineState.value,
    ));
  }

  // ... other handlers
}

final playerNotifierProvider = AsyncNotifierProvider<PlayerNotifier, PlayerState>(PlayerNotifier.new);
```

#### 5.2.3 Widget-level: ref.listen migration
Find all widgets using `addListener` and migrate to `ref.listen`:

| File | Current | After |
|------|---------|-------|
| `lib/ui/widgets/main_content.dart` | `_playlistService.currentIndexNotifier.addListener(_onPlaybackChanged)` | `ref.listen(playlistServiceProvider, (_, next) { ... })` |
| `lib/ui/widgets/player_bar/*.dart` | Position/state listeners | `ref.listen(playerNotifierProvider, (_, next) { ... })` |
| `lib/ui/widgets/equalizer_widget.dart` | Settings listeners | `ref.listen(settingsNotifierProvider, (_, next) { ... })` |

#### 5.2.4 State providers for hot paths
Add granular providers for frequently-accessed state:

```dart
// lib/providers/audio_state_providers.dart
final engineStateProvider = Provider<AudioEngineState>((ref) {
  final engine = ref.watch(audioEngineServiceProvider);
  return engine.engineState.value;
});

final positionProvider = StateProvider<Duration>((ref) {
  final engine = ref.watch(audioEngineServiceProvider);
  return engine.positionNotifier.value;
});
```

(Use `StateNotifier` or simple subscription if `StateProvider` not enough.)

#### 5.2.5 Legacy ValueNotifier retention strategy
ValueNotifiers inside service classes (`AudioEngineService.engineState`, `PlaylistService.currentIndexNotifier`, etc.) stay because they:
- Are owned by long-lived services
- Are exposed for stream-like consumption
- Are not widget-rebuild-prone when wrapped in `ref.watch` providers

But: widgets MUST consume via Riverpod providers, not directly via `service.engineState` access.

### 5.3 Acceptance Criteria
- [ ] `SettingsNotifier.refresh()` is called automatically on any `ValueNotifier` change in `SettingsManager`
- [ ] `PlayerNotifier` is the primary consumer-facing player state API; `PlayerViewModel` retained as deprecated wrapper
- [ ] No widget uses `service.notifier.addListener` directly (only via `ref.listen` or providers)
- [ ] `playerViewModelProvider` marked `@Deprecated('Use playerNotifierProvider')` (target removal: v3.0.0)
- [ ] All 456 existing tests still pass; new tests cover `SettingsNotifier` subscription behavior

### 5.4 Backward Compatibility
- `SettingsManager` retained as persistence layer (no API removal)
- `playerViewModelProvider` still works, marked deprecated (target removal: v3.0.0)
- Service classes retain internal `ValueNotifier` (private implementation detail)
- SettingsManager becomes "internal" — only `settingsNotifierProvider` is the public API for UI

---

## 6. Phase 3 — Performance

### 6.1 Problem
- Visualizer (`lib/ui/widgets/visualizer_widget.dart`, `lib/ui/painters/visualizer_painters.dart`) does particle simulation on main thread — frame drops on low-end devices
- `album_grid_widget.dart` uses `GridView.count` (eager rendering)
- Settings sliders apply changes immediately — can fire 60 events/sec during drag
- Position timer ticks even when window minimized (wastes battery on mobile)
- Cover art decoded at full resolution

### 6.2 Solution

#### 6.2.1 Visualizer isolate
Extract particle simulation to `compute()`:

```dart
// lib/ui/visualizer/particle_simulator.dart
List<Particle> _tickParticles(List<Particle> particles, double dt, double audioLevel) {
  // Pure function — runs in isolate via compute()
}

class VisualizerWidget extends StatefulWidget {
  // ...
  void _tick() {
    setState(() {
      _particles = compute(_tickParticles, [_particles, _dt, _audioLevel]);
    });
  }
}
```

- Main thread: paint only (30fps cap)
- Isolate: simulation (60fps if device allows)
- Adaptive: drop particles if frame time > 16ms sustained

#### 6.2.2 List virtualization
Replace `GridView.count` in `album_grid_widget.dart`:

```dart
GridView.builder(
  gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
    maxCrossAxisExtent: 200,
    mainAxisSpacing: 8,
    crossAxisSpacing: 8,
    childAspectRatio: 1.0,
  ),
  itemCount: albums.length,
  itemBuilder: (context, index) => AlbumTile(albums[index]),
)
```

Apply to: album grid, song list (already lazy but verify), playlist grid.

#### 6.2.3 Debouncing
- **Search input** (already 300ms in main_content) — extend to all search entry points
- **Settings sliders** — 100ms debounce before applying to audio effect:

```dart
Timer? _debounce;

void _onSliderChanged(double value) {
  _debounce?.cancel();
  _debounce = Timer(const Duration(milliseconds: 100), () {
    ref.read(settingsNotifierProvider.notifier).setEqBand(_index, value);
  });
}
```

- **Color picker** — 50ms throttle for live preview

#### 6.2.4 Position timer pause
In `AudioEngineService._schedulePositionTick()`:

```dart
void _schedulePositionTick() {
  if (PlatformCapabilities.instance.isDesktop && _isWindowMinimized) return;
  if (PlatformCapabilities.instance.isMobile && _isAppBackgrounded) return;
  // ... existing logic
}
```

Hook into `AppLifecycleState` and `windowManager` events.

#### 6.2.5 Image cache tuning
- Memory cache: 50 entries (was unlimited)
- Disk cache: 200 entries (was 500)
- Decode size: `cacheWidth: 256, cacheHeight: 256` for grid views; full for hero/player

### 6.3 Acceptance Criteria
- [ ] Visualizer runs simulation off main thread; paint FPS measurable via `PerformanceProbe`
- [ ] `GridView.builder` used in all grid widgets
- [ ] All settings sliders debounced (≤100ms)
- [ ] Position timer paused when window minimized / app backgrounded
- [ ] Cover art memory cap at 50 entries
- [ ] Benchmark before/after stored in `perf_baselines/`

### 6.4 Backward Compatibility
- No API changes
- Performance improvements transparent to callers
- `PerformanceProbe` extended for new metrics

---

## 7. Phase 4 — UI/UX Modernization

### 7.1 Problem
- `main.dart` lines 290-309: `ThemeData.light().copyWith(...)` with only 3 `ColorScheme` fields
- Hard-coded colors: `Color(0xFFF5F5F5)`, `Color(0xFF121212)`, `Color(0xFF282828)`
- Accessible widgets (`lib/ui/widgets/accessible_widgets.dart`) defined but not consistently applied
- Mobile UX: sidebar hidden on small screens but no replacement navigation
- Animation/transition gaps (no page transitions, no micro-interactions)

### 7.2 Solution

#### 7.2.1 Material 3 migration
Replace `lib/core/theme/app_theme.dart`:

```dart
ThemeData light(Color seedColor) => ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(seedColor: seedColor, brightness: Brightness.light),
  // ... M3 typography, components
);

ThemeData dark(Color seedColor) => ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(seedColor: seedColor, brightness: Brightness.dark),
);
```

Components to update:
- `BottomNavigationBar` → `NavigationBar` (M3)
- `Card` → `Card.filled` (M3)
- `ElevatedButton` → `FilledButton` (M3)
- `AppBar` uses M3 surface tint

#### 7.2.2 Accessibility audit
Scan all interactive widgets for:
- `Semantics(label: ...)` for icon-only buttons
- Touch target ≥ 48x48 (use `ConstrainedBox` or `IconButton.styleFrom`)
- Focus traversal order (use `FocusTraversalGroup` where needed)
- Dynamic text scaling support (verify with `MediaQuery.textScaler`)

Apply `AccessiblePlayButton`, `AccessibleSongTile`, `AccessibleVolumeSlider` everywhere.

#### 7.2.3 Mobile UX
- Breakpoint < 600px: hide sidebar, show `NavigationBar` at bottom (5 tabs)
- Playlist manager: bottom sheet on mobile, side panel on tablet+
- Mini player: tap to expand to full screen
- SafeArea handling for notched devices

#### 7.2.4 Animation polish
- `PageTransitionsTheme`: shared axis transitions
- Micro-interactions: `AnimatedScale` on button press
- Skeleton loader for song list during loading

### 7.3 Acceptance Criteria
- [ ] All themes use `ColorScheme.fromSeed` + M3 components
- [ ] Zero hard-coded colors in widget files (use theme)
- [ ] All interactive widgets have Semantics labels
- [ ] Mobile layout (≤600px) uses NavigationBar
- [ ] TalkBack/VoiceOver smoke test passes
- [ ] Manual visual review: dark/light/dynamic color all consistent

### 7.4 Backward Compatibility
- Theme can be reverted via setting: "Classic theme (M2)"
- Layout breakpoints configurable via setting (compact/comfortable)
- No data migration needed

---

## 8. Phase 5 — Test Coverage

### 8.1 Problem
- 40 test files vs 109 source files = ~37% ratio
- Critical paths untested: `audio_engine_service.dart`, `smtc_service.dart`, `hotkey_service.dart`, visualizer
- Integration test minimal (`integration_test/app_test.dart` is startup-only)
- No coverage reporting in CI

### 8.2 Solution

#### 8.2.1 Critical path tests

**`test/core/audio/audio_engine_service_test.dart` (new, ~400 lines):**
- State machine: idle → loading → playing → paused → stopped → error
- LRU eviction: insert N+5 sources, verify oldest evicted
- Crossfade math: linear/exponential/sCurve curves produce expected values
- Position timer: epsilon filtering works
- Concurrent play: overlapping calls handled gracefully

**`test/core/services/smtc_service_test.dart` (extend existing):**
- Metadata updates: title, artist, album art propagate
- Playback state sync: play/pause/seek
- Windows-only mocking strategy

**`test/core/services/hotkey_service_test.dart` (new):**
- Register/unregister actions
- Conflict detection
- JSON serialization round-trip

#### 8.2.2 UI widget tests
For each screen, add 1-2 widget tests:
- Empty state, loading state, error state
- Responsive layout (mobile/tablet/desktop frame)

Target: 50%+ line coverage on `lib/ui/widgets/`.

#### 8.2.3 Integration tests
Extend `integration_test/app_test.dart`:
- App startup → home screen with seeded songs
- Add song from file picker → appears in list
- Play → pause → resume state transitions
- Change EQ preset → audio engine state reflects
- Settings persist across app restart (sub-process)

#### 8.2.4 Coverage tooling
- Add coverage step to CI: `flutter test --coverage`
- Generate HTML report: `lcov --directory coverage/lcov.info --output-directory coverage/html`
- Upload to Codecov (optional)
- Diff coverage: PR comment shows uncovered lines

### 8.3 Acceptance Criteria
- [ ] Line coverage ≥70% on `lib/core/` (currently ~50%)
- [ ] Line coverage ≥50% on `lib/ui/`
- [ ] All new code (Phases 1-4) has tests
- [ ] CI fails if coverage drops > 2%
- [ ] Integration tests run on Android + Linux (Windows runner optional)

### 8.4 Backward Compatibility
- All new tests additive
- No changes to source code

---

## 9. Phase 6 — Polish & CI

### 9.1 Problem
- CI builds Windows/Android/Linux but no `dart analyze` step
- No coverage reporting
- No performance budget enforcement
- `CHANGELOG.md` manually maintained

### 9.2 Solution

#### 9.2.1 CI cải tiến
```yaml
# .github/workflows/ci.yml
name: CI
on: [push, pull_request]

jobs:
  analyze:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
      - run: flutter pub get
      - run: dart analyze --fatal-infos --fatal-warnings

  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
      - run: flutter test --coverage
      - run: |
          if [ -d "coverage" ]; then
            lcov --directory coverage/lcov.info --output-directory coverage/html
          fi
      - uses: codecov/codecov-action@v3
        with:
          file: coverage/lcov.info

  build-matrix:
    strategy:
      matrix:
        os: [windows-latest, ubuntu-latest, macos-latest]
    runs-on: ${{ matrix.os }}
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
      - run: flutter build apk --release  # Android
      - run: flutter build windows --release  # Windows
      - run: flutter build linux --release  # Linux
```

#### 9.2.2 Performance budget
Define `perf_budgets.yaml`:

```yaml
budgets:
  startup_time_ms: 2000
  apk_size_mb: 30
  frame_p99_ms: 16
  idle_memory_mb: 200
```

Add script `scripts/check_perf_budget.sh`:
- Run app, measure startup
- Parse APK size from build output
- Fail CI if any budget exceeded

#### 9.2.3 Conventional commits + auto-changelog
- `commitlint` config in repo
- GitHub Action generates CHANGELOG.md from commits on release

#### 9.2.4 Documentation
- Update `docs/architecture.md` with new state management pattern
- Per-module README in `lib/core/audio/`, `lib/core/services/`, `lib/providers/`
- Update `README.md` with new dependencies (Drift, riverpod_generator)

### 9.3 Acceptance Criteria
- [ ] CI runs analyze + test + coverage + build matrix
- [ ] PR fails on warnings
- [ ] Coverage report visible in PR comment
- [ ] Performance budget script run on release builds
- [ ] Architecture docs reflect final design

---

## 10. Risks & Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|-----------|
| Drift migration loses user data | Low | High | Backup DB to `ga_song.db.bak` before migration; restore on failure. (Phase 2, optional Drift consolidation.) |
| Riverpod refactor causes audio glitches | Medium | High | Feature flag: `useRiverpodPlayerProvider`. A/B test before fully switching. |
| Visualizer isolate adds latency | Medium | Medium | Cap simulation steps per frame; adaptive particle count. |
| Material 3 changes familiar UI | Low | Medium | Theme preset: "Classic (M2)" available in settings. |
| Test coverage work uncovers latent bugs | High | Low | Buffer time in Phase 5 for bug fixes (allow +20%). |
| Performance regression unnoticed | Medium | Medium | Baseline benchmarks before/after each phase; store in `perf_baselines/`. |

---

## 11. Out of Scope (Explicitly)

- macOS/iOS/Web full feature parity (post-evolution)
- Cloud sync, accounts
- Plugin system
- Lyric editor (separate spec)
- Scrobbling (Last.fm etc.)
- New audio formats (FLAC, Opus) — already supported if SoLoud supports them

---

## 12. Success Metrics

| Metric | Baseline (v2.0.0) | Target (post-evolution) |
|--------|-------------------|-------------------------|
| `debugPrint` count | 113 | 0 |
| `ValueNotifier` exposed in widget layer | 80 | <10 (only via providers) |
| Line coverage `lib/core/` | ~50% | ≥70% |
| `dart analyze` warnings | unknown | 0 |
| Visualizer frame drop % (mid-tier Android) | unknown | <1% |
| APK size | unknown | ≤30MB |
| Material 3 components | 0% | 100% of new UI |
| Test count | 456 | 600+ |

---

## 13. References

- `docs/architecture.md` — current architecture
- `docs/upgrade_plan.md` — Phase 1-3 plan (already shipped)
- `docs/superpowers/specs/2026-06-24-phase1-ui-desktop-lyrics-design.md` — precedent for this spec format
- Flutter Material 3 docs: https://m3.material.io/
- Riverpod v3 docs: https://riverpod.dev/
- Drift docs: https://drift.simonbinder.eu/

---

## 14. Approval

- [x] Approach: Balanced Evolution
- [x] Scope: Comprehensive (architecture + performance + UI/UX + test)
- [x] Strategy: Evolution (backward-compatible)
- [x] Phase order: 1 → 2 → 3 → 4 → 5 → 6

---

## 15. Implementation Sequencing

This spec covers **6 phases** spanning ~9–10 weeks. The implementation plan (separate document) will cover **Phase 1 only** first. Subsequent phases each get their own implementation plan after Phase 1 ships.

Rationale:
- Phase 1 (Foundation) unblocks all other phases — AppLogger + Result<T> are used everywhere
- Each phase is independently shippable
- Each phase preserves backward compatibility
- If priorities shift, mid-stream pause is safe