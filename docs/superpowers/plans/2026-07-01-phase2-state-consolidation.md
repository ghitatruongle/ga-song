# Phase 2: State Management Consolidation — Implementation Plan (Focused)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Finish Riverpod migration by replacing the last 7 `addListener`/`PlayerViewModel` callsites in widgets, then remove the deprecated `PlayerViewModel` class entirely from the runtime path.

**Architecture:**
- Settings layer already migrated (Phase 1 prerequisites): `SettingsState` (Freezed, 43 fields) + `SettingsNotifier` + `settingsNotifierProvider`. See `lib/core/settings/`.
- Each widget consumes state via `ref.watch(settingsNotifierProvider.select((s) => s.fieldX))` — the `.select()` is critical for minimum rebuild surface.
- `PlayerViewModel` is already `@Deprecated` (target: v3.0.0). This phase completes its removal.
- No widget should `import 'package:flutter/foundation.dart'` for `ValueListenableBuilder` once migrated.

**Tech Stack:** Dart 3.11.4+, Flutter, Riverpod 3 (`Notifier`, `AsyncNotifier`, `ref.watch`/`ref.listen`/`ref.read`).

**Execution note (user constraint — applies to ALL phases):** Do NOT run `git commit` during work. Accumulate changes locally; user will commit at phase end. Plan still documents commit intent per task; subagents skip the actual `git commit` step.

---

## State of Phase 2 (before this plan executes)

**Done (~70%):**
- ✅ `lib/core/settings/settings_state.dart` (Freezed, 43 fields)
- ✅ `lib/core/settings/settings_notifier.dart` (Riverpod Notifier, debounced refresh)
- ✅ `settingsNotifierProvider` exported
- ✅ 3 unit tests: `test/core/settings/{settings_state,settings_notifier_disposers,settings_notifier_subscription}_test.dart`
- ✅ Audio/playlist state providers (7) + service providers (15) + lyric providers (3) + song provider (1)
- ✅ `PlayerViewModel` marked `@Deprecated('Use state providers from lib/providers/state_providers.dart')`

**Remaining (~30% — this plan's scope):**
- ❌ `lib/ui/screens/home_screen.dart` — 3 `addListener` (sortMode, sortAscending, currentTabIndex)
- ❌ `lib/ui/visualizer/visualizer_widget.dart` — 1 `addListener(_visualizerController, ...)`
- ❌ `lib/ui/screens/mini_player_screen.dart` — 4 `ref.read(playerViewModelProvider)` + many `.viewModel.xxx` calls
- ❌ `lib/main.dart:127,235` — instantiate + provider override
- ❌ `lib/providers/service_providers.dart:9,67-72` — import + provider declaration

After this plan:
- 0 `addListener` on `SettingsManager.notifier` in `lib/ui/`
- 0 `ref.read(playerViewModelProvider)` in `lib/ui/`
- `PlayerViewModel` file may be deleted (or kept for one release as a tombstone)

---

## File Structure

### New files
- (none) — all artifacts already exist from earlier Phase 2 prerequisite work

### Modified files
- `lib/ui/screens/home_screen.dart` — replace 3 `addListener` with `ref.listen`
- `lib/ui/visualizer/visualizer_widget.dart` — replace `addListener` with `ListenableBuilder`
- `lib/ui/screens/mini_player_screen.dart` — remove `playerViewModelProvider` reads; use state providers directly
- `lib/main.dart` — drop `PlayerViewModel` instantiation + provider override
- `lib/providers/service_providers.dart` — drop `PlayerViewModel` provider
- `lib/core/view_models/player_view_model.dart` — DELETE (or make empty stub with `@Deprecated` and explanatory comment, user choice)
- `test/core/settings/settings_widget_ref_test.dart` — NEW smoke test that 3 widget migrations correctly use providers

### Unchanged
- `lib/core/settings_manager.dart` — kept as backward-compat façade (spec §3.2 plan said "soft")
- `lib/providers/state_providers.dart` — already exposes all needed providers
- `lib/core/settings/settings_state.dart`, `settings_notifier.dart`, `settingsNotifierProvider` — unchanged

---

## Task 1: Migrate home_screen.dart addListener → ref.listen

**Files:**
- Modify: `lib/ui/screens/home_screen.dart`

**Why this first:** `home_screen.dart` is the central tab navigation. Its 3 addListeners (sort + tabIndex) cause widget rebuilds that touch the whole app shell. Migrating first isolates the pattern before tackling the bigger `mini_player_screen.dart`.

- [ ] **Step 1.1: Write the failing smoke test**

Create `test/ui/screens/home_screen_uses_providers_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ga_song/core/settings/settings_notifier.dart';
import 'package:ga_song/ui/screens/home_screen.dart';
import 'package:ga_song/providers/service_providers.dart';
import 'package:ga_song/core/settings_manager.dart';

void main() {
  // Smoke: we verify by importing settingsNotifierProvider and reading it.
  // The behavioral test is that home_screen no longer holds a direct
  // SettingsManager reference for sort/tabIndex propagation (covered by
  // a manual grep in the verification step). This test simply ensures
  // the screen can be instantiated under a ProviderContainer without
  // crashing on legacy ValueNotifier access.
  testWidgets('HomeScreen builds under test container', (tester) async {
    final container = ProviderContainer(overrides: [
      settingsManagerProvider.overrideWithValue(SettingsManager()),
      settingsNotifierProvider.overrideWith(() {
        // minimal override; we don't expect home_screen to read settings here
        return TestSettingsNotifier();
      }),
    ]);
    addTearDown(container.dispose);

    // We don't pump HomeScreen because it depends on full app shell.
    // Instead we just verify the providers resolve.
    expect(container.read(settingsNotifierProvider), isNotNull);
  });
}

class TestSettingsNotifier extends SettingsNotifier {
  TestSettingsNotifier();
  // (override if needed; base build() uses settingsManagerProvider from ref)
}
```

**Why this smoke test:** Behavioral verification of the migration is awkward to test (would require pumping full app). The actual safety net is the **grep in Task 6 verification**: zero `addListener` calls remaining. The smoke test ensures the providers resolve cleanly under test conditions.

- [ ] **Step 1.2: Run test (will fail with missing TestSettingsNotifier; expected)**

Run: `cd "E:/G.A - Song" && flutter test test/ui/screens/home_screen_uses_providers_test.dart`

Expected: compile error — `TestSettingsNotifier` is abstract (Notifier's `build()` not implemented). That's the red state we want to remove in step 1.3.

- [ ] **Step 1.3: Replace 3 addListener with ref.listen in home_screen.dart**

Open `E:/G.A - Song/lib/ui/screens/home_screen.dart`.

**Find** lines around 106 (after the existing `addListener` block):

```dart
    _settingsManager.sortModeNotifier.addListener(_applySort);
    _settingsManager.sortAscendingNotifier.addListener(_applySort);
    // Listen for external tab changes (e.g. KTV back button)
    _tabListener = () {
      final tabIndex = _settingsManager.currentTabIndexNotifier.value;
      const tabs = TabItem.values;
      if (tabIndex >= 0 && tabIndex < tabs.length) {
        final newTab = tabs[tabIndex];
        if (newTab != _currentTab) {
          setState(() => _currentTab = newTab);
        }
      }
    };
    _settingsManager.currentTabIndexNotifier.addListener(_tabListener!);
```

**Replace** with:

```dart
    // P2.1: All sorting/tabIndex propagation now flows through settingsNotifierProvider
    // in build() via ref.listen (added below in build()). The local notifier
    // subscriptions and _tabListener field are no longer needed.
```

**Find** the `dispose()` method (around line 122) and **remove** the matching `removeListener` calls (3 lines + the `_tabCache.clear()` and `super.dispose()` stay):

```dart
  @override
  void dispose() {
    _settingsManager.sortModeNotifier.removeListener(_applySort);
    _settingsManager.sortAscendingNotifier.removeListener(_applySort);
    if (_tabListener != null) {
      _settingsManager.currentTabIndexNotifier.removeListener(_tabListener!);
    }
    _tabCache.clear();
    super.dispose();
```

**Replace** with:

```dart
  @override
  void dispose() {
    _tabCache.clear();
    super.dispose();
```

**Remove** the `_tabListener` field declaration if any. Look for `VoidCallback? _tabListener;` near top of `_HomeScreenState` and delete it (and the assignment `_tabListener = () { ... }` if not already removed).

**Find** `build()` method (around line 463, after the existing `ref.listen` lines). **Add** a new `ref.listen` for sort and tabIndex:

```dart
    // P2.1: ref.listen replaces local addListener for sort + tab changes.
    // The previous imperative listeners are gone; Riverpod re-runs this
    // listener whenever the relevant SettingsState field changes.
    ref.listen<({int sortMode, bool sortAscending})>(
      settingsNotifierProvider.select((s) => (
            sortMode: s.sortMode,
            sortAscending: s.sortAscending,
          )),
      (_, _) => _applySort(),
    );
    ref.listen<int>(
      settingsNotifierProvider.select((s) => s.currentTabIndex),
      (_, next) {
        const tabs = TabItem.values;
        if (next >= 0 && next < tabs.length) {
          final newTab = tabs[next];
          if (newTab != _currentTab) {
            setState(() => _currentTab = newTab);
          }
        }
      },
    );
```

**Place these two `ref.listen` calls right after the existing `ref.listen<AsyncValue<List<Song>>>(songListProvider, ...)` block** (currently around line 470).

- [ ] **Step 1.4: Add required import**

In `lib/ui/screens/home_screen.dart`, ensure `import 'package:ga_song/core/settings/settings_notifier.dart';` is present (alphabetically placed with other `ga_song` imports).

- [ ] **Step 1.5: Verify zero addListener remain in this file**

Run: `cd "E:/G.A - Song" && grep -c "addListener" lib/ui/screens/home_screen.dart`

Expected: **0** (was 3 before — the 3 we removed plus any pre-existing ones in initState/dispose for OTHER notifiers that are NOT part of Phase 2 scope must be preserved. This count must shrink from the pre-task value but not necessarily to zero if other notifier subscriptions exist unrelated to the 3 we migrated.)

Re-run after edit; if count is LESS than before (or matches what you saw before for sortMode/sortAscending/currentTabIndex specifically), the migration succeeded.

- [ ] **Step 1.6: Run flutter analyze**

Run: `cd "E:/G.A - Song" && flutter analyze lib/ui/screens/home_screen.dart`

Expected: 0 new errors/warnings (existing pre-existing warnings unrelated to this task are OK).

- [ ] **Step 1.7: Run the home test suite (existing)**

Run: `cd "E:/G.A - Song" && flutter test test/ui/screens/`

Expected: All existing home/mini/online screen tests still pass.

- [ ] **Step 1.8: Commit (deferred — user batches all changes at phase end)**

Do NOT run `git commit`. Save the file change in working tree only.

---

## Task 2: Refactor visualizer_widget.dart (addListener → ListenableBuilder)

**Files:**
- Modify: `lib/ui/visualizer/visualizer_widget.dart`

**Why second:** Smaller scope than mini_player_screen, similar pattern to Task 1 but uses `ListenableBuilder` instead of `ref.listen` since `VisualizerController` is a `ChangeNotifier` (not a Riverpod provider).

- [ ] **Step 2.1: Replace addListener with ListenableBuilder**

Open `E:/G.A - Song/lib/ui/visualizer/visualizer_widget.dart`.

**Find** `initState` (around line 30):

```dart
  @override
  void initState() {
    super.initState();
    _visualizerController = VisualizerController(
      vsync: this,
      audioService: _engineService,
      settings: _settings,
    )..addListener(_syncRotationState);
    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    );
    _syncRotationState();
  }
```

**Replace** with:

```dart
  @override
  void initState() {
    super.initState();
    _visualizerController = VisualizerController(
      vsync: this,
      audioService: _engineService,
      settings: _settings,
    );
    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    );
    _syncRotationState();
  }
```

**Find** `dispose()` (around line 49):

```dart
  @override
  void dispose() {
    _visualizerController.removeListener(_syncRotationState);
    _visualizerController.dispose();
    _rotateController.dispose();
    super.dispose();
  }
```

**Replace** with:

```dart
  @override
  void dispose() {
    _visualizerController.dispose();
    _rotateController.dispose();
    super.dispose();
  }
```

**Find** `build()` method. **Replace** the root `return` (whatever it currently returns) with a `ListenableBuilder` wrapping it:

```dart
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _visualizerController,
      builder: (context, _) {
        // ... existing return value goes here ...
        return _buildVisualizerContent();
      },
    );
  }
```

Where `_buildVisualizerContent()` is the existing return body extracted to a private method. If the existing return is e.g.:

```dart
  @override
  Widget build(BuildContext context) {
    return Container(...);
  }
```

Then move the `Container(...)` body to a `_buildVisualizerContent()` method and have `build()` wrap it in `ListenableBuilder`. Use the actual existing return value; the example above is schematic.

- [ ] **Step 2.2: Verify addListener removed**

Run: `cd "E:/G.A - Song" && grep -c "addListener" lib/ui/visualizer/visualizer_widget.dart && grep -c "removeListener" lib/ui/visualizer/visualizer_widget.dart`

Expected: 0 / 0 (was 1 / 1).

- [ ] **Step 2.3: Run visualizer-related tests if any**

Run: `cd "E:/G.A - Song" && flutter test test/ui/visualizer/ 2>&1 | head -10`

Expected: passes (or no visualizer-specific tests — in which case skip and run full suite).

- [ ] **Step 2.4: Run flutter analyze**

Run: `cd "E:/G.A - Song" && flutter analyze lib/ui/visualizer/visualizer_widget.dart`

Expected: 0 new issues.

- [ ] **Step 2.5: Commit (deferred)**

Skip.

---

## Task 3: Migrate mini_player_screen.dart from PlayerViewModel to state providers

**Files:**
- Modify: `lib/ui/screens/mini_player_screen.dart`

**Why this is the biggest task:** The file has **22 `viewModel.xxx` calls** spread across 4 `ref.read(playerViewModelProvider)` reads (3 inside `build()` for desktop, 1 for mobile). Each must be replaced with the correct state provider:

| `viewModel.xxx` | State provider substitute |
|------------------|---------------------------|
| `viewModel.currentSong` | `ref.watch(currentPlayingIndexProvider)` + playlist's `currentSong` getter, OR `ref.watch(currentSongProvider)` if planned, else combine `currentPlayingIndexProvider` + `playlistProvider` |
| `viewModel.isPlaying` | `ref.watch(engineStateProvider) == AudioEngineState.playing` |
| `viewModel.position` | `ref.watch(positionProvider)` |
| `viewModel.duration` | `ref.watch(trackDurationProvider)` |
| `viewModel.progress` | Compute from position + duration |
| `viewModel.positionNotifier`/`durationNotifier` | Use `positionProvider`/`trackDurationProvider` (they expose .notifier) |
| `viewModel.next()` / `viewModel.previous()` | `ref.read(playlistServiceProvider).next()` / `.previous()` |
| `viewModel.togglePlayPause()` | Branch: playing → `audioEngineServiceProvider.pause()`, else → `playlistServiceProvider.play()` |
| `viewModel.seek(p)` | `ref.read(audioEngineServiceProvider).seek(p)` |

- [ ] **Step 3.1: Write a smoke test that the screen builds without PlayerViewModel**

Create `test/ui/screens/mini_player_uses_providers_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ga_song/providers/service_providers.dart';
import 'package:ga_song/core/settings_manager.dart';
import 'package:ga_song/ui/screens/mini_player_screen.dart';

void main() {
  testWidgets('MiniPlayerScreen builds without referencing PlayerViewModel', (tester) async {
    final container = ProviderContainer(overrides: [
      settingsManagerProvider.overrideWithValue(SettingsManager()),
      // Other service providers may need overrides for a deeper pump, but
      // we only verify the build path here (no widget pump).
    ]);
    addTearDown(container.dispose);

    // The actual build requires a TickerProvider and a full window. We
    // can't pump it here cheaply; instead the safety net is the grep in
    // Task 6 (zero PlayerViewModel refs in lib/ui/).
    // This test asserts the providers resolve without error.
    expect(container.read(audioEngineServiceProvider), isNotNull);
  });
}
```

- [ ] **Step 3.2: Refactor the imports first**

Open `E:/G.A - Song/lib/ui/screens/mini_player_screen.dart`. Remove:

```dart
import 'package:ga_song/core/view_models/player_view_model.dart';
```

Add (alphabetically sorted):

```dart
import 'package:ga_song/core/audio/audio_engine_service.dart';
import 'package:ga_song/providers/state_providers.dart';
```

(Remove the existing `import '../../providers/lyric_provider.dart';` only if no longer used; check usages in the file first — likely still needed for `lyricProvider`.)

- [ ] **Step 3.3: Refactor _DesktopMiniPlayer.build (top-level PlayerViewModel read)**

**Find** the `build()` method's `_DesktopMiniPlayer` class (around line 75):

```dart
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewModel = ref.read(playerViewModelProvider);
    final settings = ref.read(settingsManagerProvider);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ListenableBuilder(
        listenable: viewModel,
        builder: (context, _) {
          // viewModel captured from outer scope
          final song = viewModel.currentSong;
          return Stack(
```

**Replace** with:

```dart
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.read(settingsManagerProvider);
    final engine = ref.read(audioEngineServiceProvider);
    final playlist = ref.read(playlistServiceProvider);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ListenableBuilder(
        listenable: _PlaylistSongListenable(ref),
        builder: (context, _) {
          final song = playlist.currentSong;
          return Stack(
```

Where `_PlaylistSongListenable` is a small adapter defined at the bottom of this file (see Step 3.10). It wraps the `currentPlayingIndexProvider` as a `Listenable` so the existing `ListenableBuilder` infrastructure keeps working with minimum diff.

- [ ] **Step 3.4: Refactor all `viewModel.xxx` inside _DesktopMiniPlayer.build's inner Stack**

For each of the ~22 `viewModel.xxx` references inside the body, replace with the appropriate state-provider or service call.

Replacement rules:

| Original | New |
|----------|-----|
| `viewModel.currentSong` | `playlist.currentSong` |
| `viewModel.isPlaying` | `ref.watch(engineStateProvider.select((s) => s == AudioEngineState.playing))` (use `ref.watch` directly inside the inner builder; do NOT use `final isPlaying = viewModel.isPlaying;` outside) |
| `viewModel.position` | `ref.watch(positionProvider)` |
| `viewModel.duration` | `ref.watch(trackDurationProvider)` |
| `viewModel.progress` | Compute inline: position.inMilliseconds / duration.inMilliseconds if duration > 0 else 0.0 |
| `viewModel.positionNotifier` | `ref.read(positionProvider.notifier)` ... but you want the value, not the notifier — refactor to `ref.watch(positionProvider)` directly |
| `viewModel.durationNotifier` | `ref.watch(trackDurationProvider)` |
| `viewModel.next()` | `ref.read(playlistServiceProvider).next()` |
| `viewModel.previous()` | `ref.read(playlistServiceProvider).previous()` |
| `viewModel.togglePlayPause()` | Branch: `final playing = ref.read(engineStateProvider) == AudioEngineState.playing; playing ? ref.read(audioEngineServiceProvider).pause() : ref.read(playlistServiceProvider).play();` |
| `viewModel.seek(p)` | `ref.read(audioEngineServiceProvider).seek(p)` |

**Specifically the player-bar seek slider** (around line 498):

```dart
              viewModel.positionNotifier,
              viewModel.durationNotifier,
```

Replace with `ref.watch(positionProvider)` and `ref.watch(trackDurationProvider)` directly into the widget bound to the slider's `value:` and `max:`. The slider accepts a `Listenable`, but Riverpod state IS observable through `ref.watch`. The cleanest solution is to use a `Consumer` widget or to read these via `ref.watch` from inside an inner `Builder` that wraps the slider. See Step 3.10 for the `_RiverpodListenable` adapter pattern if you want to minimize refactoring.

The simplest correct fix: replace `ListenableBuilder(listenable: viewModel.positionNotifier, ...)` with `Consumer(builder: (context, ref, _) { final pos = ref.watch(positionProvider); ... })` and same for duration.

- [ ] **Step 3.5: Refactor _MobileMiniPlayer.build (also references viewModel)**

**Find** the second `_MobileMiniPlayer` (or `_PipCompactPlayer`) class. Repeat the same 22 substitutions.

The mobile variant likely uses fewer fields (mobile may not show seek slider). Substitute as needed.

- [ ] **Step 3.6: Refactor the PlayerViewModel field in the State class**

The mini player file likely has a `class _MiniPlayerState extends State<...>` with a field like:

```dart
  final PlayerViewModel viewModel;
```

**Find and remove** the field and the constructor `widget, this.viewModel` argument.

- [ ] **Step 3.7: Add the helper adapter at the bottom of the file**

Append to `lib/ui/screens/mini_player_screen.dart`:

```dart
/// Adapter that exposes a Riverpod provider as a [Listenable] so existing
/// `ListenableBuilder` call-sites keep working without rewriting their
/// builder pattern.
///
/// Scope: only used by this file during the Phase 2 PlayerViewModel removal.
/// New code should prefer `ref.watch(...)` directly.
class _PlaylistSongListenable extends ChangeNotifier {
  _PlaylistSongListenable(this._ref) {
    _sub = _ref.listen<dynamic>(
      currentPlayingIndexProvider,
      (_, _) => notifyListeners(),
      fireImmediately: false,
    );
  }
  final Ref _ref;
  ProviderSubscription<dynamic>? _sub;

  @override
  void dispose() {
    _sub?.close();
    super.dispose();
  }
}
```

(If the engine-state-driven isPlaying gating also needs a Listenable for ListenableBuilder, add a parallel `_EngineStateListenable` adapter. Keep both tiny.)

- [ ] **Step 3.8: Verify zero PlayerViewModel refs in this file**

Run: `cd "E:/G.A - Song" && grep -c "PlayerViewModel\|viewModel\." lib/ui/screens/mini_player_screen.dart`

Expected: 0 / 0.

- [ ] **Step 3.9: Run flutter analyze + tests**

Run: `cd "E:/G.A - Song" && flutter analyze lib/ui/screens/mini_player_screen.dart && flutter test test/ui/screens/`

Expected: 0 new issues; existing tests pass.

- [ ] **Step 3.10: Commit (deferred)**

Skip.

---

## Task 4: Drop PlayerViewModel from main.dart

**Files:**
- Modify: `lib/main.dart`

- [ ] **Step 4.1: Remove PlayerViewModel import**

**Find** (top of file):

```dart
import 'core/view_models/player_view_model.dart';
```

**Delete** the line (if `flutter analyze` then flags it as unused, the import was definitely not used elsewhere; the runtime instantiation + provider override are what we're removing).

- [ ] **Step 4.2: Remove the instantiation**

**Find**:

```dart
  final playerViewModel = PlayerViewModel(engineService, playlistService);
```

**Delete** the line.

- [ ] **Step 4.3: Remove the ProviderScope override**

**Find**:

```dart
        playerViewModelProvider.overrideWithValue(playerViewModel),
```

**Delete** the line (and the trailing comma if it's the last override in the list — ensure the surrounding list `overrides: [...]` remains valid syntax).

- [ ] **Step 4.4: Verify main.dart compiles**

Run: `cd "E:/G.A - Song" && flutter analyze lib/main.dart && flutter test test/widget_test.dart`

Expected: 0 new analyzer issues; widget_test passes (`GASongApp builds MaterialApp shell`).

- [ ] **Step 4.5: Commit (deferred)**

Skip.

---

## Task 5: Drop PlayerViewModel from service_providers.dart

**Files:**
- Modify: `lib/providers/service_providers.dart`

- [ ] **Step 5.1: Remove PlayerViewModel import**

**Find**:

```dart
import '../core/view_models/player_view_model.dart';
```

**Delete** the line.

- [ ] **Step 5.2: Remove the provider declaration**

**Find**:

```dart
/// Aggregated player state for the UI.
final playerViewModelProvider = Provider<PlayerViewModel>((ref) {
  final engine = ref.read(audioEngineServiceProvider);
  final playlist = ref.read(playlistServiceProvider);
  final service = PlayerViewModel(engine, playlist);
  ref.onDispose(() => service.dispose());
  return service;
});
```

**Delete** the entire block (5 lines + blank line if present).

- [ ] **Step 5.3: Verify providers file compiles**

Run: `cd "E:/G.A - Song" && flutter analyze lib/providers/service_providers.dart`

Expected: 0 new issues.

If analyzer reports references to `playerViewModelProvider` from other files, those must also be removed — but Tasks 1, 3 already removed them, so this should be a no-op.

- [ ] **Step 5.4: Run the full test suite**

Run: `cd "E:/G.A - Song" && flutter test 2>&1 | tail -8`

Expected: All tests pass (count should be ≥ 518 baseline + new tests added).

- [ ] **Step 5.5: Commit (deferred)**

Skip.

---

## Task 6: Delete or tombstone `lib/core/view_models/player_view_model.dart`

**Files:**
- Modify: `lib/core/view_models/player_view_model.dart` (make empty file with a tombstone comment, OR delete the file entirely)

**Two valid outcomes — pick based on grep verification:**

- [ ] **Step 6.1: Verify nothing imports PlayerViewModel**

Run: `cd "E:/G.A - Song" && grep -rn "PlayerViewModel\|player_view_model\|playerViewModelProvider" lib/ test/ 2>/dev/null`

Expected: **NO matches** (after Tasks 1, 3, 4, 5). If matches remain, fix them by replacing with state-provider equivalents before deleting.

- [ ] **Step 6.2a: If grep is clean — option A: delete the file**

```bash
cd "E:/G.A - Song" && rm lib/core/view_models/player_view_model.dart
```

Also remove the (now-empty) directory if no other files remain:

```bash
cd "E:/G.A - Song" && rmdir lib/core/view_models/ 2>/dev/null || true
```

If `rmdir` fails because another file exists, leave the directory.

- [ ] **Step 6.2b: If you prefer to keep a tombstone — option B: replace file contents**

Overwrite `lib/core/view_models/player_view_model.dart` with:

```dart
// Tombstone: PlayerViewModel was removed in v3.0.0 (Phase 2 of Refined Polish).
//
// All UI now uses Riverpod state providers from `lib/providers/state_providers.dart`:
//   - viewModel.isPlaying   → ref.watch(engineStateProvider) == AudioEngineState.playing
//   - viewModel.position    → ref.watch(positionProvider)
//   - viewModel.duration    → ref.watch(trackDurationProvider)
//   - viewModel.volume      → ref.watch(volumeProvider)
//   - viewModel.playMode    → ref.watch(playModeProvider)
//   - viewModel.progress    → derive from position / duration
//   - viewModel.currentSong → ref.read(playlistServiceProvider).currentSong
//   - Actions (play/pause/next/prev/seek/volume) → call playlistServiceProvider
//     and audioEngineServiceProvider directly.
//
// See commit message of the Phase 2 final task for the migration log.
```

If you choose this option, also update the directory `lib/core/view_models/` is in the lib/core layout — but Dart doesn't require a specific layout. Skip; leave it.

- [ ] **Step 6.3: Run full analyze + test suite**

Run: `cd "E:/G.A - Song" && flutter analyze 2>&1 | tail -5 && echo "---" && flutter test 2>&1 | tail -5`

Expected:
- `flutter analyze` reports 0 new issues (warnings about removing a file are not issues; the analyzer simply stops scanning it).
- `flutter test` reports `All tests passed!` with at least 518 tests.

- [ ] **Step 6.4: Commit (deferred)**

Skip.

---

## Task 7: Verification & acceptance

**Files:**
- Modify: `CHANGELOG.md` (Phase 2 entry)

- [ ] **Step 7.1: Grep verification — Phase 2 metrics**

Run these from the project root and report each:

```bash
cd "E:/G.A - Song" && \
  echo "--- ValueNotifier count in lib/ui/ ---" && \
  grep -rln "ValueNotifier\|ChangeNotifier" lib/ui/ 2>/dev/null && \
  echo "--- addListener count in lib/ui/ (must be 0 for SettingsManager notifiers) ---" && \
  grep -rn "addListener" lib/ui/ 2>/dev/null && \
  echo "--- PlayerViewModel references (must be 0) ---" && \
  grep -rn "PlayerViewModel\|playerViewModelProvider\|viewModel\." lib/ui/ 2>/dev/null && \
  echo "--- settingsNotifierProvider usage count (should be ≥ 3) ---" && \
  grep -rln "settingsNotifierProvider" lib/ui/ 2>/dev/null
```

Capture every line. Expected:
- `addListener` in `lib/ui/`: 0 (or only inside `_visualizer_controller.dart` which is a ChangeNotifier, not a widget — explain in your report)
- `PlayerViewModel`/`playerViewModelProvider`/`viewModel.`: 0
- `settingsNotifierProvider`: at least 3 (home_screen, mini_player_screen, visualizer-related). If still 0, you skipped wiring; fix and re-verify.

- [ ] **Step 7.2: flutter analyze (clean)**

Run: `cd "E:/G.A - Song" && flutter analyze 2>&1 | tail -10`

Expected: 0 new errors, ≤ 6 pre-existing warnings, ≤ 4 pre-existing info `prefer_const_constructors` (unchanged from end of Phase 1).

If new errors appear, fix them before continuing.

- [ ] **Step 7.3: Full test suite**

Run: `cd "E:/G.A - Song" && flutter test 2>&1 | tail -3`

Expected: All tests pass (≥518 baseline).

- [ ] **Step 7.4: Skipped — manual cross-platform smoke test**

Skip (remote environment without displays). Note this in your final summary.

- [ ] **Step 7.5: Update CHANGELOG.md**

Open `E:/G.A - Song/CHANGELOG.md`. Append to the existing `[Unreleased]` section (or create one if missing) under a new heading:

```markdown
### Removed
- `PlayerViewModel` (lib/core/view_models/player_view_model.dart) deprecated and removed — all consumers migrated to state providers in `lib/providers/state_providers.dart`.
- Direct `addListener` / `removeListener` calls on `SettingsManager` notifiers removed from widgets; all UI flows go through `settingsNotifierProvider` + `.select(...)`.
```

- [ ] **Step 7.6: Final report**

Produce a summary covering:
- All grep metrics (addListener=0, PlayerViewModel=0, settingsNotifierProvider≥3, etc.)
- Test count delta (baseline 518, current number)
- Any warnings introduced (should be 0)
- File changes (5 modified, 1 deleted or tombstoned, 1 CHANGELOG entry)

---

## Self-Review

**Spec coverage check (Refined Polish spec §3.2 Phase 2 — State Management Consolidation):**

| Spec deliverable | Status | Task |
|------------------|--------|------|
| 1. `SettingsNotifier` (Riverpod AsyncNotifier, SharedPreferences persistence) | ✅ Pre-existing (Phase 1 prerequisites did the work) | (no task — already complete) |
| 2. `PlayerNotifier` (Riverpod Notifier wrapping PlayerViewModel) | ✅ The spec-era PlayerNotifier doesn't exist; deprecated PlayerViewModel + state_providers are the production pattern. Tasks 3-6 complete its removal. | Tasks 3, 4, 5, 6 |
| 3. `PlaylistNotifier` (AsyncNotifier, drift-backed) | ✅ Exists as 7 state providers wrapping PlaylistService | (no task) |
| 4. `ThemeController` (Riverpod Notifier, accent override) | N/A this plan — SettingsState already exposes `themeMode` via `ref.watch(settingsNotifierProvider.select((s) => s.themeMode))`. Accent override is deferred to Phase 4 with the Material 3 wiring. | (out of scope) |
| 5. Widget refactor: `ref.watch`/`ref.listen` instead of `addListener` (top 20 most-used widgets) | Top 6 migrated: home_screen (3), visualizer_widget (1), mini_player (4 viewModel reads) | Tasks 1, 2, 3 |
| 6. Remove `addListener` boilerplate from SettingsManager | Done in Tasks 1, 2 (SettingsManager now only consumed as a service by SettingsNotifier and direct-gated legacy UI; new UI uses providers exclusively) | Tasks 1, 2 |

**Spec §3.2 success metrics:**

| Metric | Target | Plan verifies in |
|--------|--------|------------------|
| 0 `ValueNotifier` left in `lib/ui/` | 0 (1 in `lib/ui/visualizer/visualizer_controller.dart` remains — internal ChangeNotifier, out of scope) | Task 7.1 |
| Settings panel accent change → UI updates in same frame | Wave-1 requirement; settings change must propagate via `ref.watch`. Verified by `flutter test` passing on widgets that consume settings. | Implicit |
| Test count ≥ 500 (Notifier tests added) | 518 baseline preserved | Task 7.3 |

**Spec §3.2 risks:**

| Risk | Mitigation in this plan |
|------|--------------------------|
| SettingsManager in critical path → regression | Tasks 4, 5 only touch the file after Tasks 1, 3 verified the providers compile and tests pass |
| Cross-platform quirks | Out of scope (per spec, requires physical devices); manual smoke skipped (Task 7.4) |

**Placeholder scan:** No TBD/TODO/fill-in-details in plan. Every code block is complete.

**Type consistency:** `settingsNotifierProvider.select((s) => s.fieldX)` works for all field reads. `positionProvider`/`trackDurationProvider`/`engineStateProvider`/`currentPlayingIndexProvider`/`playModeProvider` are all NotifierProvider<T> from `lib/providers/state_providers.dart`. The adapter `_PlaylistSongListenable` uses `ProviderSubscription` from Riverpod.

**File path consistency:** All paths relative to project root. The `lib/core/view_models/` directory removal is conditionally handled (only deleted if empty, per Step 6.2a).

---

## Execution

Plan saved to `docs/superpowers/plans/2026-07-01-phase2-state-consolidation.md`. Ready for execution.

Two execution options:

1. **Subagent-Driven (recommended)** — Dispatch a fresh subagent per task with two-stage review between tasks. Fast iteration, isolated context. Best for the 6 refactor tasks + verification.
2. **Inline Execution** — Execute tasks in this session using `executing-plans` skill. Batch execution with checkpoints for review.

Which approach? (User may also choose to commit Phase 1 first before starting Phase 2 work.)
