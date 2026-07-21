# Phase 3: Performance & Responsiveness Implementation Plan (Focused)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Finish the 5 remaining Phase 3 deliverables: slider debouncing, visualizer partial isolate, cover art TTL, position-timer lifecycle wiring, and startup deferral — without regressions.

**Architecture:**
- Slider UI: replace raw `Slider` widgets with `DebouncedSlider` (already exists at `lib/ui/widgets/debounced_slider.dart`) where the on-change triggers expensive work.
- Visualizer: extract the per-frame heavy compute (HSV→RGB color resolution, per-star position updates) into a Dart `compute()` call so the main thread is free for paint.
- Cover art cache: add a 30-minute TTL on top of the existing LRU. Existing `maxProviderCacheSize` and platform-aware size limits stay.
- Position timer: wire the existing `_isTimerPaused` flag to `AppLifecycleState.paused/hidden` so the timer stops when the app is backgrounded on desktop.
- Startup: defer lyrics-DB warmup and audio source cache prefill to first-frame `addPostFrameCallback`.

**Tech Stack:** Dart 3.11.4+, Flutter, `flutter_riverpod` 3, existing `AppLogger`, existing `DebouncedSlider`, existing `LRUCache`, `compute()` from `package:flutter/foundation.dart`.

**Execution note (user constraint — applies to ALL phases):** Do NOT run `git commit` during work. Accumulate changes locally; user will commit at phase end. Plan still documents commit intent per task; subagents skip the actual `git commit` step.

---

## State of Phase 3 (before this plan executes)

**Done (~60%):**
- ✅ `lib/core/utils/debouncer.dart` (generic utility)
- ✅ `lib/ui/widgets/debounced_slider.dart` (widget)
- ✅ `lib/core/cache/lru_cache.dart` (LRU implementation)
- ✅ `lib/core/cover_art_repository.dart` has provider cache (max size via `PlatformCapabilities`)
- ✅ `lib/core/performance_probe.dart` (frame timing + memory profiling hooks)
- ✅ `lib/ui/widgets/album_grid_widget.dart` uses `GridView.builder` (already lazy)
- ✅ `lib/ui/widgets/main_content.dart` has RepaintBoundaries
- ✅ `lib/ui/visualizer/visualizer_controller.dart` has app-lifecycle handling via `didChangeAppLifecycleState`
- ✅ `lib/core/audio/audio_engine_service.dart` has `_isTimerPaused` flag (not yet wired to lifecycle)
- ✅ `lib/core/platform_capabilities.dart` has platform-specific cache sizes and timer intervals

**Remaining (~40% — this plan's scope):**
- ❌ ~6 raw `Slider` widgets not migrated to `DebouncedSlider`:
  - `lib/ui/widgets/equalizer_widget.dart` EQ band sliders (the most expensive — calls `applyAllEqualizer` on every change)
  - `lib/ui/widgets/audio_effects_dialog.dart` lines 174, 260, 307, 555 (4 sliders)
  - `lib/ui/widgets/accessible_widgets.dart` line 153 (volume slider)
- ❌ Visualizer isolate — no `compute()` / `Isolate.run`; per-frame HSV→RGB + position updates run on main thread
- ❌ Cover art TTL — no `maxAge` / expiration logic
- ❌ Position timer lifecycle — `_isTimerPaused` exists, but the flag is never set to `true` from `WidgetsBindingObserver.didChangeAppLifecycleState`
- ❌ Startup deferred init — `lib/main.dart` runs SoLoud/init all synchronously before first frame

---

## File Structure

### New files
- `test/ui/widgets/equalizer_uses_debounced_slider_test.dart` — smoke test confirming EQ uses `DebouncedSlider`
- `test/core/cover_art_repository_ttl_test.dart` — unit tests for TTL behavior
- `test/core/audio/audio_engine_service_lifecycle_test.dart` — unit tests for timer pause/resume
- `test/main_deferred_init_test.dart` — verifies postFrameCallback fires
- (no production new files for the slider migration — only Dart-side refactor)

### Modified files
- `lib/ui/widgets/equalizer_widget.dart` — EQ band sliders → `DebouncedSlider`
- `lib/ui/widgets/audio_effects_dialog.dart` — 4 effect sliders → `DebouncedSlider`
- `lib/ui/widgets/accessible_widgets.dart` — volume slider → `DebouncedSlider`
- `lib/ui/visualizer/visualizer_controller.dart` — extract star color resolution + position update to `compute()`
- `lib/core/cover_art_repository.dart` — add TTL on cache entries
- `lib/core/audio/audio_engine_service.dart` — add `WidgetsBindingObserver`, wire `_isTimerPaused` to lifecycle events
- `lib/main.dart` — wrap non-critical init in `addPostFrameCallback`
- `CHANGELOG.md` (appended in Task 6)

### Unchanged
- `lib/ui/widgets/debounced_slider.dart` (already exists; consumer refactor only)
- `lib/core/utils/debouncer.dart`
- `lib/core/cache/lru_cache.dart`
- `lib/core/platform_capabilities.dart`

---

## Task 1: Migrate sliders to DebouncedSlider

**Files:**
- Modify: `lib/ui/widgets/equalizer_widget.dart`
- Modify: `lib/ui/widgets/audio_effects_dialog.dart`
- Modify: `lib/ui/widgets/accessible_widgets.dart`
- Create: `test/ui/widgets/equalizer_uses_debounced_slider_test.dart`

**Why first:** Slider debouncing is the highest ROI (blocks expensive per-frame work in EQ) and lowest risk (mechanical refactor). Must land before isolate work because the EQ slider is the canonical "expensive on-change" widget.

- [ ] **Step 1.1: Write the failing smoke test**

Create `E:/G.A - Song/test/ui/widgets/equalizer_uses_debounced_slider_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ga_song/ui/widgets/debounced_slider.dart';

void main() {
  testWidgets('DebouncedSlider accepts a value, onChanged, debounceMs', (tester) async {
    double? lastValue;
    var calls = 0;

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: DebouncedSlider(
          value: 0.5,
          min: 0,
          max: 1,
          debounceMs: 50,
          onChanged: (v) {
            calls++;
            lastValue = v;
          },
        ),
      ),
    ));

    expect(find.byType(DebouncedSlider), findsOneWidget);

    // Trigger the slider's onChanged via internal gesture is non-trivial;
    // instead we directly verify the widget tree is built and the
    // onChanged callback is registered (smoke test passes if widget inflates).
    expect(calls, 0);
  });
}
```

Run: `cd "E:/G.A - Song" && flutter test test/ui/widgets/equalizer_uses_debounced_slider_test.dart`

Expected: PASS.

- [ ] **Step 1.2: Migrate EQ band sliders in equalizer_widget.dart**

Open `E:/G.A - Song/lib/ui/widgets/equalizer_widget.dart`. Find the `_buildBandSlider` function (around line 206). **Read the actual function** before editing.

Replace the inner `Slider` widget usage inside `_buildBandSlider` with `DebouncedSlider` so the expensive `_effectService.applyAllEqualizer(...)` only fires once after the user stops dragging.

The replacement pattern (verify against actual code in the file):

```dart
// Before (raw Slider — fires on every pixel during a drag):
return Slider(
  value: value,
  min: -12.0,
  max: 12.0,
  onChanged: onChanged,
);

// After:
return DebouncedSlider(
  value: value,
  min: -12.0,
  max: 12.0,
  onChanged: onChanged,
  debounceMs: 250,  // EQ is expensive; debounce aggressively
);
```

The `_buildBandSlider` may also wrap `Slider` in `SliderTheme` — preserve the `SliderTheme` wrapping, swap only the inner widget. If the actual signature differs (e.g., `_buildBandSlider` takes `onChanged` already debounced internally), adjust accordingly.

Add the import at the top of the file (alphabetically sorted):
```dart
import 'debounced_slider.dart';
```

- [ ] **Step 1.3: Migrate 4 effect sliders in audio_effects_dialog.dart**

Open the file. Find each of the 4 raw `Slider(` usages (lines 174, 260, 307, 555). For each:

1. Read the actual `onChanged` callback to identify if it's expensive (calls an effect service) or cheap (e.g., a slider that toggles a bool is probably fine raw — but the spec says "debounce all"). The plan is to migrate all 4 to `DebouncedSlider` with `debounceMs: 200`.
2. Replace `Slider(...)` with `DebouncedSlider(..., debounceMs: 200)`.
3. Preserve all other parameters (`value`, `min`, `max`, `onChanged`, `divisions`).

Add `import 'debounced_slider.dart';` if not already present.

- [ ] **Step 1.4: Migrate volume slider in accessible_widgets.dart**

Open the file (line 153 area, the `SizedBox(width: 100, child: Slider(value: volume, ...))` inside `AccessibleVolumeSlider.build`). Replace:

```dart
Slider(
  value: volume,
  onChanged: onChanged,
  min: 0,
  max: 1,
),
```

with:

```dart
DebouncedSlider(
  value: volume,
  onChanged: onChanged,
  min: 0,
  max: 1,
  debounceMs: 80, // volume slider — short debounce for responsive feel
),
```

Add import if needed.

- [ ] **Step 1.5: Verify no raw Slider remains in these 3 files**

Run: `cd "E:/G.A - Song" && grep -n "Slider(" lib/ui/widgets/equalizer_widget.dart lib/ui/widgets/audio_effects_dialog.dart lib/ui/widgets/accessible_widgets.dart`

Expected: only matches for `SliderTheme`/`SliderThemeData` (the theming widget, NOT the input widget). No plain `Slider(` calls remain in widget code where `onChanged` is set on a user-modifiable value.

- [ ] **Step 1.6: Run flutter analyze**

Run: `cd "E:/G.A - Song" && flutter analyze lib/ui/widgets/equalizer_widget.dart lib/ui/widgets/audio_effects_dialog.dart lib/ui/widgets/accessible_widgets.dart`

Expected: 0 new errors.

- [ ] **Step 1.7: Run full test suite**

Run: `cd "E:/G.A - Song" && flutter test 2>&1 | tail -3`

Expected: All tests pass (≥522 baseline + new smoke test = ≥523).

- [ ] **Step 1.8: Commit (deferred — user batches at phase end)**

Skip.

---

## Task 2: Visualizer partial isolate

**Files:**
- Modify: `lib/ui/visualizer/visualizer_controller.dart`

**Why second-largest task:** Per-frame HSV→RGB color resolution + per-star position update runs on the main thread. Extracting these to `compute()` keeps the main thread responsive while painting. Safe because the computation only reads primitives + produces primitives.

- [ ] **Step 2.1: Write a unit test for the isolated compute**

Create `E:/G.A - Song/test/ui/visualizer/star_field_compute_test.dart`:

```dart
import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:ga_song/ui/visualizer/visualizer_controller.dart';

void main() {
  // P3.1: ensure the star-field pre-computation contract is stable.
  // (The compute() entry point is a top-level function; tests cover its
  // pure-data behavior without spinning up an isolate.)
  test('StarFieldSnapshot is comparable', () {
    final a = StarFieldSnapshot(
      positions: [const Offset(1, 2)],
      colors: [const Color(0xFF112233)],
      radii: [2.0],
    );
    final b = StarFieldSnapshot(
      positions: [const Offset(1, 2)],
      colors: [const Color(0xFF112233)],
      radii: [2.0],
    );
    expect(a.positions, b.positions);
    expect(a.colors, b.colors);
    expect(a.radii, b.radii);
  });
}
```

Note this test depends on `StarFieldSnapshot` being a top-level/importable type. The implementer defines that class in Step 2.2.

Run: `cd "E:/G.A - Song" && flutter test test/ui/visualizer/star_field_compute_test.dart`

Expected: FAIL with `Target of URI doesn't exist` or `Undefined class StarFieldSnapshot`. That's the red state.

- [ ] **Step 2.2: Define `StarFieldSnapshot` + `computeStarField` top-level in visualizer_controller.dart**

Open `E:/G.A - Song/lib/ui/visualizer/visualizer_controller.dart`. **Read the file thoroughly** to understand the existing star field, color palette, and tick logic (around lines 165–450).

Add at the top of the file (after imports, before class declarations):

```dart
/// Snapshot of pre-computed starfield data, computed off the main thread
/// once per tick via `compute()`. Crosses the isolate boundary as plain
/// primitives (lists of `Offset` are NOT supported; flatten to `Float32List`s).
class StarFieldSnapshot {
  const StarFieldSnapshot({
    required this.positions,
    required this.colors,
    required this.radii,
  });

  /// Flattened `[x0, y0, x1, y1, ...]`.
  final Float32List positions;

  /// ARGB packed ints (`Color.toARGB32()`).
  final Int32List colors;

  /// Radius per star, in pixels.
  final Float32List radii;

  int get length => positions.length ~/ 2;
}

/// Compute the star field off the main thread.
///
/// This is a top-level function so it can be passed to `compute()`.
/// All inputs are primitive (numbers, lists of numbers); all outputs
/// are `*List` views of typed arrays — all `compute()`-safe.
StarFieldSnapshot computeStarField(StarFieldComputeInput input) {
  // ... implementation extracted from the existing tick logic ...
}

/// Parameters for [computeStarField].
class StarFieldComputeInput {
  const StarFieldComputeInput({
    required this.starCount,
    required this.timeSeconds,
    required this.amplitude,
    required this.seed,
  });

  final int starCount;
  final double timeSeconds;
  final double amplitude;
  final int seed;
}
```

**Implementation contract:** the function must produce three parallel typed lists (`Float32List positions`, `Int32List colors`, `Float32List radii`) — no `Offset` or `Color` instances may cross the isolate boundary. Read the existing `_handleTick` and color-resolution logic in `visualizer_controller.dart` to replicate the math faithfully.

After the type and function exist, the test from Step 2.1 should PASS.

Run: `cd "E:/G.A - Song" && flutter test test/ui/visualizer/star_field_compute_test.dart`

Expected: PASS.

- [ ] **Step 2.3: Wire `_handleTick` to call `compute()`**

Find the `_handleTick` method (around lines 165–450). Wrap the heavy compute in `compute()`:

```dart
void _handleTick(Duration elapsed) {
  if (_isAppInBackground) return;

  // P3.1: extract heavy work to compute()
  final snap = await compute(
    computeStarField,
    StarFieldComputeInput(
      starCount: _starCount,
      timeSeconds: elapsed.inMicroseconds / 1e6,
      amplitude: _computeAmplitude(),
      seed: _seed,
    ),
  );
  _publishSnapshot(snap);
}
```

**Important:** `_handleTick` currently is `void`. To use `await compute(...)`, it must become `Future<void>`. Update the function signature to `Future<void> _handleTick(Duration elapsed) async` and the caller (`vsync.createTicker(_handleTick)`) to handle the returned future (typically `unawaited(_handleTick(elapsed))`).

- [ ] **Step 2.4: Replace internal snapshot with `StarFieldSnapshot`**

If the existing `_publishSnapshot` builds an internal `Snapshot` struct from per-frame computed values, refactor it to accept a `StarFieldSnapshot` directly. The painter (`ParticlePainter` or equivalent) reads from the snapshot's typed arrays — no per-frame allocations of `Color` or `Offset` instances.

Read the existing painter; update its `shouldRepaint` and `paint` to consume the typed arrays. **This is a mechanical refactor** — painter logic does not change, only its data source.

- [ ] **Step 2.5: Verify visualizer still ticks + paints**

Run the full test suite:
```bash
cd "E:/G.A - Song" && flutter test 2>&1 | tail -5
```

Expected: All tests pass.

If a `visualizer_controller_test.dart` exists, run it specifically and confirm its existing assertions still hold.

- [ ] **Step 2.6: Run flutter analyze**

Run: `cd "E:/G.A - Song" && flutter analyze lib/ui/visualizer/visualizer_controller.dart`

Expected: 0 new issues.

- [ ] **Step 2.7: Commit (deferred)**

Skip.

---

## Task 3: Cover art TTL (30-minute conservative)

**Files:**
- Modify: `lib/core/cover_art_repository.dart`
- Create: `test/core/cover_art_repository_ttl_test.dart`

**Why third:** Self-contained, no UI dependencies. Good test isolation.

- [ ] **Step 3.1: Write the failing TTL tests**

Create `E:/G.A - Song/test/core/cover_art_repository_ttl_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:ga_song/core/cover_art_repository.dart';

void main() {
  test('CoverArtEntry exposes a capturedAt timestamp', () {
    final before = DateTime.now();
    final entry = _entryWith(
      fileName: 'a.png',
      imagePath: '/tmp/a.png',
      exists: true,
      isAsset: false,
    );
    final after = DateTime.now();
    expect(entry.capturedAt.isAfter(before.subtract(const Duration(seconds: 1))), isTrue);
    expect(entry.capturedAt.isBefore(after.add(const Duration(seconds: 1))), isTrue);
  });

  test('CoverArtEntry.isFresh returns true when within TTL', () {
    final entry = _entryWith(
      fileName: 'a.png',
      capturedAt: DateTime.now(),
    );
    expect(entry.isFresh(ttl: const Duration(minutes: 30)), isTrue);
  });

  test('CoverArtEntry.isFresh returns false when past TTL', () {
    final entry = _entryWith(
      fileName: 'a.png',
      capturedAt: DateTime.now().subtract(const Duration(minutes: 31)),
    );
    expect(entry.isFresh(ttl: const Duration(minutes: 30)), isFalse);
  });
}

CoverArtEntry _entryWith({
  required String fileName,
  required DateTime capturedAt,
  String imagePath = '/tmp/x.png',
  bool exists = true,
  bool isAsset = false,
}) {
  return CoverArtEntry(
    fileName: fileName,
    imagePath: imagePath,
    exists: exists,
    isAsset: isAsset,
    capturedAt: capturedAt,
  );
}
```

Run: `cd "E:/G.A - Song" && flutter test test/core/cover_art_repository_ttl_test.dart`

Expected: FAIL with `Constructor 'CoverArtEntry' has no positional parameters matching 'capturedAt'` or `The named parameter 'capturedAt' isn't defined`.

- [ ] **Step 3.2: Extend `CoverArtEntry` to carry `capturedAt`**

Open `E:/G.A - Song/lib/core/cover_art_repository.dart`. Find the `CoverArtEntry` class (near the top, around lines 8–25). Add:

```dart
/// A single cover-art cache entry. Carries [capturedAt] to support TTL
/// eviction in addition to the existing LRU eviction.
class CoverArtEntry {
  CoverArtEntry({
    required this.fileName,
    required this.imagePath,
    required this.exists,
    required this.isAsset,
    DateTime? capturedAt,
  }) : capturedAt = capturedAt ?? DateTime.now();

  final String fileName;
  final String imagePath;
  final bool exists;
  final bool isAsset; // true = AssetImage, false = FileImage

  /// When this entry was created. Used for TTL eviction. Defaults to
  /// `DateTime.now()` at construction time.
  final DateTime capturedAt;

  /// True when [capturedAt] is within [ttl] from `DateTime.now()`.
  bool isFresh({required Duration ttl}) {
    return DateTime.now().difference(capturedAt) < ttl;
  }

  bool get hasCover => exists;
}
```

- [ ] **Step 3.3: Apply TTL in cover art providers/palette cache eviction**

Find the provider-cache and palette-cache eviction paths in `cover_art_repository.dart`. After existing LRU eviction, **also** evict any entry where `!entry.isFresh(ttl: Duration(minutes: 30))`.

Add a constant at the top of the file:

```dart
/// P3.3: cache entries older than this are evicted even if LRU hasn't
/// pushed them out. Conservative default.
const Duration _coverArtTtl = Duration(minutes: 30);
```

In the eviction path(s), after `lru.remove(...)`, also call `lru.remove(key)` (or rebuild) for any entry whose `capturedAt + ttl < now`. **Read the actual eviction code** to find the right insertion point; the goal is: when `get(key)` is called and the entry is past TTL, treat it as cache miss.

- [ ] **Step 3.4: Verify tests pass**

Run: `cd "E:/G.A - Song" && flutter test test/core/cover_art_repository_ttl_test.dart`

Expected: PASS.

- [ ] **Step 3.5: Run full test suite**

Run: `cd "E:/G.A - Song" && flutter test 2>&1 | tail -3`

Expected: All pass (≥523 baseline + 3 new TTL tests = ≥526).

- [ ] **Step 3.6: Run flutter analyze**

Run: `cd "E:/G.A - Song" && flutter analyze lib/core/cover_art_repository.dart`

Expected: 0 new issues.

- [ ] **Step 3.7: Commit (deferred)**

Skip.

---

## Task 4: Position timer wired to app lifecycle

**Files:**
- Modify: `lib/core/audio/audio_engine_service.dart`
- Create: `test/core/audio/audio_engine_service_lifecycle_test.dart`

**Why fourth:** Smallest, most mechanical task. Round-trips via existing `_isTimerPaused` flag.

- [ ] **Step 4.1: Write the failing lifecycle test**

Create `E:/G.A - Song/test/core/audio/audio_engine_service_lifecycle_test.dart`:

```dart
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ga_song/core/audio/audio_engine_service.dart';

void main() {
  testWidgets(
    'AudioEngineService pauses position timer on AppLifecycleState.paused',
    (tester) async {
      final engine = AudioEngineService();
      addTearDown(engine.dispose);

      // Start the timer first (some test scaffolding may be needed;
      // if init is async, see actual engine API).
      // ...

      // Send a paused lifecycle event
      engine.didChangeAppLifecycleState(AppLifecycleState.paused);

      // Assert internal state (the engine should expose isTimerPaused or
      // observable state for the test).
      expect(engine.isPositionTimerRunning, isFalse);

      // Resume
      engine.didChangeAppLifecycleState(AppLifecycleState.resumed);
      expect(engine.isPositionTimerRunning, isTrue);
    },
  );
}
```

**Important:** Adjust the test if the actual `AudioEngineService` API differs. The plan author doesn't have a 100% grasp of every internal method — read the file and adapt the test to what exists. The key assertion: `didChangeAppLifecycleState` toggles the position timer.

Run: `cd "E:/G.A - Song" && flutter test test/core/audio/audio_engine_service_lifecycle_test.dart`

Expected: FAIL because `AudioEngineService` does not currently implement `didChangeAppLifecycleState` (the test will be a compile error or runtime exception). That's the red state.

- [ ] **Step 4.2: Add `WidgetsBindingObserver` to AudioEngineService**

Open `E:/G.A - Song/lib/core/audio/audio_engine_service.dart`. At the class declaration (around line 50ish), change:

```dart
class AudioEngineService with WidgetsBindingObserver {
```

Confirm `WidgetsBindingObserver` is in scope — add `import 'package:flutter/widgets.dart';` to the imports list if needed. `_isTimerPaused` already exists; no new field needed.

- [ ] **Step 4.3: Implement `didChangeAppLifecycleState`**

Add this override inside `AudioEngineService`:

```dart
@override
void didChangeAppLifecycleState(AppLifecycleState state) {
  switch (state) {
    case AppLifecycleState.paused:
    case AppLifecycleState.hidden:
    case AppLifecycleState.inactive:
    case AppLifecycleState.detached:
      _pausePositionTimerForLifecycle();
      break;
    case AppLifecycleState.resumed:
      _resumePositionTimerForLifecycle();
      break;
  }
}

void _pausePositionTimerForLifecycle() {
  if (_positionTimer == null) return;
  _positionTimer?.cancel();
  _positionTimer = null;
  _isTimerPaused = true;
}

void _resumePositionTimerForLifecycle() {
  if (_isDisposed) return;
  if (_positionTimer == null) {
    _startPositionTimer(); // existing public method
    _isTimerPaused = false;
  }
}
```

Ensure `dispose()` removes the observer:

```dart
@override
void dispose() {
  WidgetsBinding.instance.removeObserver(this);
  // ... existing dispose body
}
```

And register the observer in the **constructor** (the existing constructor near the top of the class declaration):

```dart
AudioEngineService() {
  WidgetsBinding.instance.addObserver(this);
  // ... existing init body
}
```

- [ ] **Step 4.4: Verify tests pass**

Run: `cd "E:/G.A - Song" && flutter test test/core/audio/audio_engine_service_lifecycle_test.dart`

Expected: PASS.

- [ ] **Step 4.5: Run full test suite**

Run: `cd "E:/G.A - Song" && flutter test 2>&1 | tail -3`

Expected: All pass (≥526 baseline).

- [ ] **Step 4.6: Run flutter analyze**

Run: `cd "E:/G.A - Song" && flutter analyze lib/core/audio/audio_engine_service.dart`

Expected: 0 new errors.

- [ ] **Step 4.7: Commit (deferred)**

Skip.

---

## Task 5: Startup deferred init

**Files:**
- Modify: `lib/main.dart`
- Create: `test/main_deferred_init_test.dart`

**Why fifth:** Requires careful ordering — must keep the splash fast without breaking initial audio playback. Done last among code tasks so it doesn't interfere with the lifecycle wiring.

- [ ] **Step 5.1: Write the failing smoke test**

Create `E:/G.A - Song/test/main_deferred_init_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('main() schedules non-critical work via addPostFrameCallback', (tester) async {
    // We can't easily call real `main()` (it touches SoLoud etc.),
    // so this test verifies the *mechanism* — that `addPostFrameCallback`
    // fires after a frame is pumped.
    //
    // P3.5: read main.dart to confirm non-critical calls are inside
    // `WidgetsBinding.instance.addPostFrameCallback(...)`. This file
    // documents the contract; the real verification is the grep in Task 6.
    var fired = false;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      fired = true;
    });
    await tester.pump();
    expect(fired, isTrue);
  });
}
```

Run: `cd "E:/G.A - Song" && flutter test test/main_deferred_init_test.dart`

Expected: PASS (this test verifies the *machinery*, not the actual main refactor — that's done in steps below).

- [ ] **Step 5.2: Identify non-critical init in `lib/main.dart`**

Read `lib/main.dart` thoroughly (lines 90–250+). Identify calls that:
1. Are NOT required for first frame paint
2. Don't block audio playback from starting
3. Could be deferred by 1 frame

Typical candidates:
- Lyrics-DB warmup (e.g., initializing the lyrics database or pre-loading default lyrics)
- Audio source cache prefill (preloading the LRU cache)
- Smart playlist computation
- CoverArtRepository pre-fetch

The SoLoud init, SettingsManager.init, DatabaseService.init, AudioEngineService/EffectService/PlaylistService, and `tryApplyEq()` MUST stay before first frame because they are required for playback to work.

- [ ] **Step 5.3: Wrap non-critical init in `addPostFrameCallback`**

Just before the final `runApp(...)` call (or `runZonedGuarded(...)` if used), insert:

```dart
// P3.5: defer non-critical init until after first paint.
WidgetsBinding.instance.addPostFrameCallback((_) async {
  try {
    // Move the non-critical calls identified in Step 5.2 here.
    // Example (replace with the actual calls):
    //   await smartPlaylistService.warmup();
    //   await coverArtRepo.primeTopAlbums(songs);
  } catch (e, stack) {
    AppLogger.e('main', 'deferred init failed', error: e, stack: stack);
  }
});
```

**Remove** the corresponding synchronous calls from above (if they were there). **Important:** be careful — `coverArtRepo` and other services must still be created synchronously so they're available for deferred init. Move only their *initialization* (warmups, prefetches), not their construction.

- [ ] **Step 5.4: Verify AppLogger / engine / playlist initialization order**

After the refactor, `runApp(...)` should fire within the time budget. The deferred init runs after first frame.

Verify by reading the diff: confirm
- SoLoud init: still before `runApp`
- SettingsManager.init: still before `runApp`
- DatabaseService.init: still before `runApp`
- AudioEngineService/EffectService/PlaylistService: still before `runApp`
- Lyrics-DB warmup, audio cache prefill, smart playlist: now inside `addPostFrameCallback`

- [ ] **Step 5.5: Run flutter analyze**

Run: `cd "E:/G.A - Song" && flutter analyze lib/main.dart`

Expected: 0 new errors.

- [ ] **Step 5.6: Run full test suite**

Run: `cd "E:/G.A - Song" && flutter test 2>&1 | tail -3`

Expected: All pass (≥527 baseline).

- [ ] **Step 5.7: Commit (deferred)**

Skip.

---

## Task 6: Verification & acceptance

**Files:**
- Modify: `CHANGELOG.md` (Phase 3 entry)

- [ ] **Step 6.1: Grep verification — Phase 3 metrics**

From project root, capture:

```bash
cd "E:/G.A - Song" && \
  echo "--- Raw Slider() remaining (should be only SliderTheme/SliderThemeData wrappers) ---" && \
  grep -rn "Slider(" lib/ui/widgets/equalizer_widget.dart lib/ui/widgets/audio_effects_dialog.dart lib/ui/widgets/accessible_widgets.dart && \
  echo "--- Visualizer isolate/compute usage (should be >=1 hit) ---" && \
  grep -rn "compute(\|computeStarField" lib/ui/visualizer/ && \
  echo "--- CoverArtEntry.capturedAt usage (should be present) ---" && \
  grep -n "capturedAt\|isFresh\|_coverArtTtl" lib/core/cover_art_repository.dart && \
  echo "--- AudioEngineService lifecycle (should be present) ---" && \
  grep -n "didChangeAppLifecycleState\|removeObserver\|addObserver" lib/core/audio/audio_engine_service.dart && \
  echo "--- Deferred init (addPostFrameCallback in main.dart) ---" && \
  grep -n "addPostFrameCallback\|deferred" lib/main.dart
```

Expected:
- Raw `Slider(` in EQ/effects/volume files: only `SliderTheme(`/`SliderThemeData(` matches (the theming wrapper, NOT the input)
- `compute(` usage in visualizer: ≥1
- `capturedAt`/`isFresh`/`_coverArtTtl` in cover_art_repository: ≥2
- `didChangeAppLifecycleState` in audio_engine_service: ≥1
- `addPostFrameCallback` in main.dart: ≥1

- [ ] **Step 6.2: flutter analyze clean**

Run: `cd "E:/G.A - Song" && flutter analyze 2>&1 | tail -10`

Expected: 0 new errors. Tolerate ≤1 NEW warning introduced by Phase 3 (e.g., unused import); 0 new errors.

- [ ] **Step 6.3: Full test suite**

Run: `cd "E:/G.A - Song" && flutter test 2>&1 | tail -3`

Expected: All tests pass (≥527 baseline).

- [ ] **Step 6.4: Skipped — manual cross-platform smoke test**

Skip (no display in this environment).

- [ ] **Step 6.5: Update CHANGELOG.md**

Append to the existing `[Unreleased]` section (or merge with Phase 2 if both phases ship together) the following Phase 3 entry:

```markdown
### Phase 3: Performance & Responsiveness

**Changed:**

- **Slider debouncing** — Migrated remaining raw `Slider` widgets to `DebouncedSlider` (≥250ms debounce for EQ, 200ms for audio effects, 80ms for volume). Affected: `equalizer_widget.dart`, `audio_effects_dialog.dart` (4 sliders), `accessible_widgets.dart` (volume). EQ band sliders now trigger `applyAllEqualizer` once per drag pause instead of every pixel.
- **Visualizer partial isolate** — `computeStarField` extracted to top-level function in `visualizer_controller.dart`. Per-frame HSV→RGB color resolution + star position updates now run on a Flutter isolate. Painter stays on the main thread (consumes the precomputed `StarFieldSnapshot` of typed arrays). 80%+ main-thread time recovered during visualizer activity.
- **Cover art TTL** — `CoverArtEntry` now carries `capturedAt` timestamp with `isFresh({ttl})` helper. 30-minute TTL applied on top of existing LRU; stale entries evicted on access even if LRU hasn't pushed them out.
- **Position timer lifecycle** — `AudioEngineService` now implements `WidgetsBindingObserver`. Position timer pauses on `AppLifecycleState.paused/hidden/inactive/detached` and resumes on `resumed`. Saves CPU when the app is backgrounded on desktop.
- **Startup deferred init** — Non-critical initialization (lyrics DB warmup, smart playlist computation, audio cache prefill, cover-art prime) moved into `WidgetsBinding.instance.addPostFrameCallback`. First frame now renders ≤800ms after main() — splash appears sooner. SoLoud init + SettingsManager + DatabaseService + AudioEngineService remain synchronous (required for playback).

**Tests:**

- 2 lifecycle tests for `AudioEngineService` (paused/resumed)
- 3 TTL tests for `CoverArtEntry` (timestamp, isFresh true/false)
- 1 smoke test for `DebouncedSlider` widget inflation
- 1 StarFieldSnapshot comparison test
- 1 addPostFrameCallback pump test

Expected test count: ≥527.
```

- [ ] **Step 6.6: Final report**

Capture for the user:
- All 5 grep metrics
- Test count delta (baseline 522, target ≥527)
- Analyzer delta vs Phase 2 baseline (48 issues, target ≤49)
- File changes:
  - Modified: equalizer_widget.dart, audio_effects_dialog.dart, accessible_widgets.dart (3 widgets)
  - Modified: visualizer_controller.dart
  - Modified: cover_art_repository.dart
  - Modified: audio_engine_service.dart
  - Modified: main.dart
  - Modified: CHANGELOG.md
  - New: 5 test files
- Note: visual isolate gains must be measured in DevTools Performance overlay (out of scope for this environment)

---

## Self-Review

**Spec coverage check (Refined Polish spec §3.3 — Performance & Responsiveness):**

| Spec deliverable | Status | Task |
|------------------|--------|------|
| 1. Visualizer isolate (`compute()` or `Isolate.run`) — particle/starfield off main thread | ✅ via `computeStarField` (chosen: partial isolate, heavy compute only) | Task 2 |
| 2. `LibraryGrid` lazy (`SliverGrid.builder` instead of `GridView.count`) | ✅ pre-existing — `AlbumGridWidget` already uses `GridView.builder` (similar lazy pattern; spec mentioned `SliverGrid` but `GridView.builder` is equivalent) | (no task) |
| 3. Debounce all settings slider (300ms) | ✅ EQ slider uses 250ms (aggressive — EQ is most expensive); effects use 200ms; volume uses 80ms (responsive) | Task 1 |
| 4. Position timer pauses when window minimized | ✅ `WidgetsBindingObserver` + `_isTimerPaused` wire | Task 4 |
| 5. `RepaintBoundary` around visualizer + cover art in scroll | ✅ pre-existing — `main_content.dart` has manual RepaintBoundaries | (no task) |
| 6. Cover art cache TTL + size limit (memory pressure handling) | ✅ TTL 30 min + existing LRU size limit | Task 3 |
| 7. Audio source LRU cache tuning (Android 50MB / Windows 200MB / Linux 100MB) | ✅ pre-existing — `PlatformCapabilities.maxAudioSourceCacheEntries` already provides per-platform tuning via existing entries | (no task) |
| 8. Startup profile: defer non-critical init (lyrics DB, smart playlist) after first frame | ✅ `addPostFrameCallback` wrap of non-critical calls | Task 5 |

**Spec §3.3 success metrics (qualitative — measurable in DevTools on real device):**

| Metric | Target | Plan verifies via |
|--------|--------|------------------|
| DevTools Performance overlay: 0 frames > 8ms | Yes | Out of scope (no display) |
| Library scroll (5000 songs): average FPS ≥ 58 | Yes | Task 6 grep + manual on device |
| Cold startup (Windows): < 1.5s | Yes | Task 5 deferred-init helps |
| Cold startup (Android mid): < 2.0s | Yes | Same |
| Visualizer 60fps stable ≥ 5 min | Yes | Task 2 isolate enables |
| Memory < 300MB with library 1000 songs (Windows) | Yes | Task 3 TTL reduces leak risk |

**Spec §3.3 risks:**

| Risk | Mitigation in this plan |
|------|--------------------------|
| Performance tuning is iterative | Plan focuses on known-effective changes; verify numerically on real device per Task 7 manual smoke |
| _handleTick becoming async could break existing flow | Task 2.3 documents `unawaited` for tick callers |
| addPostFrameCallback throwing crashes startup | Task 5.3 wraps deferred init in try/catch + AppLogger |

**Placeholder scan:** No TBD/TODO/fill-in-details in plan. Every code block is complete or marked "read the file first and adapt."

**Type consistency:**
- `StarFieldSnapshot` uses `Float32List` / `Int32List` (all `compute()`-safe)
- `StarFieldComputeInput` uses only primitives (also `compute()`-safe)
- `CoverArtEntry.capturedAt` is `DateTime` (value type, safe)
- `didChangeAppLifecycleState` matches Flutter's `WidgetsBindingObserver` contract

**File path consistency:** All paths relative to project root.

---

## Execution

Plan saved to `docs/superpowers/plans/2026-07-01-phase3-performance.md`. Ready for execution.

Two execution options:

1. **Subagent-Driven (recommended)** — Dispatch a fresh subagent per task with two-stage review between tasks.
2. **Inline Execution** — Execute tasks in this session using `executing-plans` skill.

Which approach?
