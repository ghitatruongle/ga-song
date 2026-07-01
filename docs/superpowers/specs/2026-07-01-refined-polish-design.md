# Refined Polish — G.A - Song UX & Performance Evolution

**Date:** 2026-07-01
**Author:** ZCode (brainstorming session)
**Status:** Approved (pending user review of written spec)
**Scope:** Cross-cutting improvements (architecture + performance + UI/UX + testing + CI)
**Approach:** Evolution (backward-compatible, incremental, sequential phases)
**Supersedes:** `docs/superpowers/specs/2026-06-30-balanced-evolution-design.md` (archived to `docs/superpowers/specs/archive/`)

---

## 1. Overview

This spec is a user-perceived-quality evolution of G.A - Song. It supersedes the 2026-06-30 Balanced Evolution spec by **shifting the lens from technical debt to user experience**, while keeping the same 6-phase structure.

### 1.1 Four Pillars — Definition of Done

Every phase must contribute to all four pillars. A phase is not "done" if it improves one but regresses another.

| Pillar | What it means | How it's measured |
|--------|---------------|-------------------|
| **Smooth (Mượt)** | 60fps target, no jank > 8ms, responsive interactions | DevTools FPS, jank frame %, scroll perf |
| **Beautiful (Đẹp)** | Design tokens coherent, motion language consistent, micro-animations purposeful | Lint grep, golden tests, manual review |
| **Quality (Chất)** | Code clean, errors structured, tests reliable, no regression | Coverage %, `flutter analyze`, test count |
| **Feel (Cảm nhận)** | Haptic/sound/visual feedback at every interaction, satisfying to use | User review (qualitative), integration tests |

### 1.2 Non-Goals

- No breaking changes to user data (DB schema, SharedPreferences keys)
- No new platform support (macOS/iOS/Web stay at "partial")
- No new features (KTV, EQ, lyrics already extensive)
- **No UI rewrite** — subtle polish only; structure preserved

### 1.3 Target Platforms

Equal weight on **Android, Windows, Linux**. Per-platform quirks documented where motion/performance differ.

### 1.4 Sequence & Timeline

Approach: **Strict sequential** (Phase 1 → 6, each fully done before next).

| Phase | Duration | Calendar weeks | Primary outcome |
|-------|----------|----------------|-----------------|
| 1 — Foundation & Error Handling | 1 week | Week 1 | AppLogger + Result + Token foundation |
| 2 — State Management Consolidation | 2 weeks | Week 2-3 | Riverpod Notifier ecosystem, legacy ValueNotifier removed |
| 3 — Performance & Responsiveness | 2 weeks | Week 4-5 | 60fps everywhere, no jank |
| 4 — UI Polish & Motion Language | 1 week | Week 6 | Material 3 + motion applied |
| 5 — Test Coverage & Integration | 2 weeks | Week 7-8 | 70%+ core coverage, integration tests |
| 6 — CI Quality Gates & Performance Budgets | 1 week | Week 9 | Automated regression prevention |

**Total:** ~9 weeks (+20% buffer for Phase 3 perf tuning → ~10-11 weeks realistic).

---

## 2. Architecture & Design Token Foundation

Before phases execute, the spec establishes a token + motion foundation that every subsequent phase consumes.

### 2.1 Design Token System

**File:** `lib/core/theme/tokens.dart`

```dart
class AppColors {
  static const seedPrimary = Color(0xFF6750A4);
  static const seedSecondary = Color(0xFF625B71);
  static const seedTertiary = Color(0xFF7D5260);
  static const accent = Color(0xFFD0BCFF);
  static const surface = Color(0xFFFFFBFE);
  static const error = Color(0xFFB3261E);
}

class AppSpacing {
  static const xxs = 2.0, xs = 4.0, sm = 8.0;
  static const md = 16.0, lg = 24.0, xl = 32.0, xxl = 48.0;
}

class AppRadius {
  static const sm = 8.0, md = 12.0, lg = 16.0, xl = 28.0;
}

class AppElevation {
  static const level0 = 0.0, level1 = 1.0, level2 = 3.0, level3 = 6.0;
}
```

### 2.2 Motion Language

**File:** `lib/core/motion/app_motion.dart`

```dart
class AppDurations {
  static const micro = Duration(milliseconds: 100);   // Tap feedback
  static const short = Duration(milliseconds: 200);   // Hover, ripple
  static const medium = Duration(milliseconds: 300);  // Standard transition
  static const long = Duration(milliseconds: 450);    // Page route
  static const extended = Duration(milliseconds: 600); // Theme switch
}

class AppCurves {
  static const standard = Curves.easeInOutCubic;
  static const decelerate = Curves.easeOutCubic;     // Enter animations
  static const accelerate = Curves.easeInCubic;      // Exit animations
  static const emphasized = Curves.easeInOutCubicEmphasized; // Material 3
}
```

**Motion rules per interaction:**

| Interaction | Duration | Curve | Effect |
|-------------|----------|-------|--------|
| Tap ripple | 200ms | standard | Material default |
| Card hover | 200ms | decelerate | Elevation +1 |
| Page push | 300ms | emphasized | Fade-through + slide 5% |
| Bottom sheet | 450ms | decelerate | Slide up + scale |
| Equalizer slider | 200ms | standard | Real-time, no debounce |
| Theme switch | 600ms | emphasized | Cross-fade ColorScheme |
| Visualizer morph | 1000ms | decelerate | Particle re-flow |

### 2.3 Theme Architecture

```
lib/core/theme/
├── tokens.dart              ← Single source of truth
├── app_theme.dart           ← ThemeData.builder() (M3 ColorScheme.fromSeed)
├── theme_extensions.dart    ← AppSpacing/Radius/Elevation via ThemeExtension
└── app_theme_controller.dart ← Riverpod notifier for ThemeMode + accent override

lib/core/motion/
├── app_motion.dart          ← Durations + Curves + signatures
└── motion_page_route.dart   ← Custom PageRoute using AppMotion
```

**ThemeExtension usage:**
```dart
final spacing = Theme.of(context).extension<AppSpacing>()!;
padding: EdgeInsets.all(spacing.md),
```

### 2.4 Cross-Platform Motion Mapping

| Platform | Special handling |
|----------|------------------|
| Android | Respect `Settings.Global.ANIMATOR_DURATION_SCALE`. If disabled → durations = 0 |
| Windows | Respect `SystemParametersInfo(SPI_GETANIMATION)`. If "fade menus" off → 0ms |
| Linux | Check `org.gnome.desktop.interface` reduce-motion setting |

`MotionPreferences.shouldReduce` is auto-detected from `MediaQuery.disableAnimations` + platform fallback.

### 2.5 Migration Strategy (Zero Breaking Change)

1. **Week 1 (Phase 1):** Create tokens + motion + extensions — do NOT modify any widget
2. **Week 2 (Phase 2):** ThemeController migrates to Riverpod (SettingsManager stays as persistence)
3. **Week 4 (Phase 3):** Apply ThemeExtension to 3 key widgets (home_screen, mini_player, ktv_screen)
4. **Week 6 (Phase 4):** Apply AppMotion to transitions + PageRoute

Every commit produces a working app.

---

## 3. Six Phases

### 3.1 Phase 1 — Foundation & Error Handling (Week 1)

**Goals:**
- Logging/Result foundation so all later phases build on clean infrastructure

**Deliverables:**

| # | Item | File |
|---|------|------|
| 1 | `AppLogger` (Riverpod-aware, level filter, optional remote sink) | `lib/core/logging/app_logger.dart` |
| 2 | `Result<T>` sealed class (already exists, expand usage) | `lib/core/utils/result.dart` |
| 3 | `AppException` (sealed, structured error) | `lib/core/exceptions/app_exception.dart` |
| 4 | Token foundation (`tokens.dart`, `app_motion.dart`, `theme_extensions.dart`) | `lib/core/theme/*` |
| 5 | Replace 113 `debugPrint` → `AppLogger.{debug,info,warn,error}` | All `lib/` |
| 6 | Remove dead code (`service_locator.dart`, unused imports) | - |

**Polish criteria:**
- **Quality:** 100% call sites use AppLogger; CI grep fails on new `debugPrint`
- **Feel:** Logger hooks for crash reporter (Sentry deferred to Phase 6, optional)
- **Smooth:** Performance tracing hooks (`Logger.perfStart/perfEnd`) ready for Phase 3
- **Beautiful:** Token system created but not yet applied to UI

**Success metrics:**
- `grep -r "debugPrint\|print(" lib/ | wc -l` = 0
- `flutter analyze` = 0 issues
- AppLogger unit test coverage ≥ 90%
- Test count ≥ 456 (no regression)

**Risks:** Low. Pure additive + replacement.

---

### 3.2 Phase 2 — State Management Consolidation (Week 2-3)

**Goals:**
- Single state flow (Riverpod Notifier ecosystem), no mixed patterns → consistent UI behavior

**Deliverables:**

| # | Item | Note |
|---|------|------|
| 1 | `SettingsNotifier` (Riverpod AsyncNotifier, SharedPreferences persistence) | Replaces 40+ ValueNotifier |
| 2 | `PlayerNotifier` (Riverpod Notifier wrapping PlayerViewModel) | Backward compat preserved |
| 3 | `PlaylistNotifier` (AsyncNotifier, drift-backed) | Single source of truth |
| 4 | `ThemeController` (Riverpod Notifier, accent override) | From Section 2 |
| 5 | Widget refactor: `ref.watch`/`ref.listen` instead of `addListener` | Top 20 most-used widgets |
| 6 | Remove `addListener` boilerplate from SettingsManager | - |

**Polish criteria:**
- **Smooth:** `select()` used in widgets to prevent unnecessary rebuilds → measurable scroll FPS improvement
- **Quality:** Single pattern — no mixed Riverpod/ValueNotifier/ChangeNotifier
- **Feel:** Settings change (theme, EQ) reflects immediately, no restart needed → "responsive" perception
- **Beautiful:** (deferred)

**Success metrics:**
- 0 `ValueNotifier` left in `lib/ui/`
- Settings panel accent change → UI updates in same frame (no rebuild flash)
- Test count ≥ 500 (Notifier tests added)

**Risks:** Medium. SettingsManager is in critical path. Smoke test on Android + Windows + Linux after each sub-step.

---

### 3.3 Phase 3 — Performance & Responsiveness (Week 4-5) ⭐ Core pillar

**Goals:**
- Every interaction < 16ms; startup < 1.5s; zero jank frames

**Deliverables:**

| # | Item | Impact |
|---|------|--------|
| 1 | Visualizer isolate (`compute()` or `Isolate.run`) — particle/starfield off main thread | 60fps stable |
| 2 | `LibraryGrid` lazy (`SliverGrid.builder` instead of `GridView.count`) | Smooth scroll 5k songs |
| 3 | Debounce all settings sliders (300ms) | EQ slider doesn't rebuild audio at 60Hz |
| 4 | Position timer pauses when window minimized | Save CPU on desktop |
| 5 | `RepaintBoundary` around visualizer + cover art in scroll | Avoid unnecessary repaint |
| 6 | Cover art cache TTL + size limit (memory pressure handling) | No OOM on 5k+ songs |
| 7 | Audio source LRU cache tuning (Android 50MB, Windows 200MB, Linux 100MB) | Per-device fit |
| 8 | Startup profile: defer non-critical init (lyrics DB, smart playlist) until after first frame | First frame < 800ms |

**Polish criteria:**
- **Smooth:** ⭐ Core pillar — this phase is the most important for "mượt"
- **Quality:** Performance marks in CI (Phase 6) — no regression
- **Feel:** Visualizer doesn't drop frames when user slides EQ
- **Beautiful:** (deferred — keep visuals, just smooth them)

**Success metrics:**

Quantitative:
- DevTools Performance overlay: 0 frames > 8ms
- Library scroll (5000 songs): average FPS ≥ 58
- Cold startup (Windows): < 1.5s
- Cold startup (Android mid-range): < 2.0s
- Cold startup (Linux): < 1.8s
- Visualizer: 60fps stable for ≥ 5 minutes playback
- Memory: < 300MB with library 1000 songs (Windows)

Qualitative:
- User reports "no jank on scroll playlist"

**Risks:** High. Performance tuning is iterative. 20% time buffer built in.

---

### 3.4 Phase 4 — UI Polish & Motion Language (Week 6) ⭐ Core pillar

**Goals:**
- Apply token system + motion language → visible/feel-able improvement at every interaction

**Deliverables:**

| # | Item | Pillar |
|---|------|--------|
| 1 | Replace hardcoded colors/spacing in top 10 screens → `ThemeExtension` lookup | Quality + Beautiful |
| 2 | PageRoute uses `MotionPageRoute` (fade-through + slide 5%) | Smooth + Beautiful |
| 3 | Card hover/press state animation (200ms, decelerate) | Feel |
| 4 | Bottom player bar: smooth show/hide on scroll | Smooth + Feel |
| 5 | Equalizer slider: real-time visual feedback (waveform pulse) | Feel |
| 6 | Lyric transition: cross-fade 300ms between current/next line | Beautiful + Feel |
| 7 | Theme switch: ColorScheme cross-fade 600ms (no flash) | Feel |
| 8 | Material 3 ColorScheme complete (30+ tokens, not just 3) | Beautiful |
| 9 | Haptic feedback on Android (`HapticFeedback.lightImpact`) for: tap play/pause, swipe song, change EQ | Feel |
| 10 | Sound feedback (subtle click) for: play next/prev — opt-in in settings | Feel |

**Polish criteria:**
- **Beautiful:** ⭐ Core pillar — Material 3 ColorScheme complete, spacing/radius consistent
- **Feel:** ⭐ Core pillar — haptic + sound + visual feedback at every interaction
- **Smooth:** Motion uses correct duration, no jank from animations
- **Quality:** No `Color(0xFF...)` magic numbers in widget code

**Success metrics:**

Quantitative:
- `grep -r "Color(0x" lib/ui/ | wc -l` = 0
- `grep -r "Duration(milliseconds:" lib/ui/ | wc -l` = 0 (use `AppDurations`)
- `grep -r "EdgeInsets.all(" lib/ui/` reduced ≥ 70%
- Theme switch animation = 600ms ± 50ms (DevTools)
- Lyric transition ≥ 58 FPS across 1 album playback

Qualitative:
- User review: "đẹp hơn" (feeling-based)
- User review: "thỏa mãn khi tap play"
- User review: "lyric chuyển dòng mượt"

**Risks:** Medium. Motion could cause jank — revisit Phase 3 if it happens.

---

### 3.5 Phase 5 — Test Coverage & Integration (Week 7-8)

**Goals:**
- 70%+ coverage on `lib/core/`, integration tests for 5 main user flows

**Deliverables:**

| # | Item |
|---|------|
| 1 | Unit tests for `audio_engine_service.dart` (LRU cache, platform limits) |
| 2 | Unit tests for `smtc_service.dart`, `hotkey_service.dart`, `window_manager_service.dart` |
| 3 | Unit tests for visualizer logic (isolated, deterministic) |
| 4 | Widget tests for top 20 screens (golden tests for layout) |
| 5 | Integration tests for 5 flows: PlayFromLibrary, ChangeTheme, PlayKTV, AdjustEQ, Search |
| 6 | Drift migration: replace raw sqflite `database_service.dart` with already-defined Drift |
| 7 | Performance regression test (script: library 1000 songs, measure FPS, fail if < 55) |

**Polish criteria:**
- **Quality:** ⭐ Core pillar — regression prevention, confidence
- **Smooth:** Perf regression test ensures Phase 3 polish doesn't break
- **Feel:** Integration tests verify haptic/sound triggers on right events
- **Beautiful:** Golden tests catch visual regression

**Success metrics:**
- `lib/core/` coverage ≥ 70%, `lib/ui/` ≥ 50%
- Integration tests: 5/5 pass on Android + Windows + Linux
- Performance regression test passes
- Test count ≥ 600 (from 456 baseline)

**Risks:** Medium. Drift migration may touch many call sites.

---

### 3.6 Phase 6 — CI Quality Gates & Performance Budgets (Week 9)

**Goals:**
- Prevent regression automatically; codify performance budgets

**Deliverables:**

| # | Item |
|---|------|
| 1 | CI step: `dart analyze` (fail on issues) |
| 2 | CI step: `flutter test --coverage` (fail if coverage drops > 2%) |
| 3 | CI step: custom lint rules (no `debugPrint`, no `Color(0xFF` in UI) |
| 4 | Performance budget YAML (max startup, max memory, min FPS) |
| 5 | Optional: Sentry/Crashlytics via AppLogger remote sink — **default: skip**, decide at Phase 6 planning |
| 6 | Docs: `docs/PERFORMANCE_BUDGETS.md` |
| 7 | GitHub Actions matrix: Windows + Ubuntu + macOS host build, Android emulator test |

**Polish criteria:**
- **Quality:** CI gates prevent regression — long-term "chất"
- **Smooth:** Performance budget codified
- **Feel:** Crash reporting helps users report bugs easily (when enabled)
- **Beautiful:** (covered in Phase 4)

**Success metrics:**
- CI passes on 3 platforms
- Coverage trend visible in PR comments
- Performance budget enforced — fail PR with clear message if exceeded
- `docs/PERFORMANCE_BUDGETS.md` published

**Risks:** Low. Mostly CI config + docs.

---

## 4. Cross-Cutting Concerns

Policies that apply across all phases, not owned by any single phase.

### 4.1 Error Handling Matrix

Standardize on `Result<T>` + `AppException` (Phase 1 deliverable). UI never directly `try/catch` — only consumes `Result<T>` via `.when(success:, failure:)`.

| Failure mode | Handling | UX outcome |
|--------------|----------|------------|
| File not found (cover art, song path) | `Result.failure(AppException.notFound)` + skip + log warn | Silent skip, no modal |
| Permission denied (storage, mic) | `Result.failure(AppException.permissionDenied)` + inline banner | Inline guidance, no crash |
| Network failure (lyrics, online playlist) | `Result.failure(AppException.network)` + retry 2x exponential + toast | "Không có mạng" |
| Audio decode failure | `Result.failure(AppException.decodeFailed)` + skip song + log error | Auto next, AppLogger |
| DB corruption | `AppException.fatal` + full-screen recovery dialog | "Khôi phục dữ liệu?" |
| User cancel (file picker, dialog) | `Result.failure(AppException.cancelled)` | Silent return |
| Unknown exception | `AppException.unknown(cause)` + log with stack + breadcrumb | Generic toast, log full |

### 4.2 Accessibility (WCAG 2.1 AA target)

| Element | Requirement |
|---------|-------------|
| Buttons | `Semantics.button` + localized `onTap` label |
| Sliders (EQ, volume, seek) | `Semantics.slider` + value announcement |
| Images | `Semantics.image` + alt text from song metadata |
| Color contrast | ≥ 4.5:1 (normal text), ≥ 3:1 (large) — light + dark themes |
| Focus order | Keyboard tab order matches visual order |
| Font scaling | Respect `MediaQuery.textScaler` up to 2.0x without overflow |
| Reduce motion | Honor `MediaQuery.disableAnimations` + platform preference |
| Screen reader | Visualizer: `aria-hidden=true`; controls have labels |

**Audit tool:** `flutter test --tags a11y` (custom tag) — fail if widget missing Semantics. Manual Android TalkBack + Windows Narrator audit at each Phase 4 completion.

### 4.3 Localization (i18n)

- All user-visible strings via `AppLocalizations.of(context).xxx` — no hardcoded VI/EN in widget code
- `.arb` files (`app_vi.arb`, `app_en.arb`) synced via `flutter gen-l10n`
- Tone: VI casual-friendly (bạn/mình), EN concise
- Pluralization via ICU MessageFormat
- Date/time via `intl` package locale-aware

**CI lint:** grep fail on hardcoded UI strings in `lib/ui/` (except `.arb` files and `//` comments).

### 4.4 Backward Compatibility

| Data | Current schema | In this spec |
|------|----------------|--------------|
| SQLite (songs, playlists, cover_art_cache) | sqflite raw | Drift (Phase 5) — same tables, same columns, on-disk format unchanged |
| SharedPreferences (settings) | JSON-encoded | Same key prefix `ga_song.*` — only in-memory state refactored |
| Drift database files (`app_database.dart`) | Defined but unused | Activated Phase 5 |

**Pre-ship test (Phase 5):** Copy production DB → open in new version → verify read OK.

### 4.5 Security & Permissions

| Concern | Policy |
|---------|--------|
| File system | Read-only in user-chosen directories (file picker); no full disk scan |
| Microphone (KTV) | Runtime permission on Android 6+; `package:win32` on Windows; PulseAudio contract on Linux |
| Hotkey conflicts | `HotkeyService` via `HotKeyManager` `scope.system`; catch conflict, fallback no-op + log |
| IPC (tray ↔ main isolate) | `IsolateNameServer`, JSON-serialized payload |
| Crash reports (Phase 6, opt-in) | Strip user file paths; log exception type + first 200 chars stack only |
| SharedPreferences | No secrets/tokens. If auth added later → `flutter_secure_storage` |
| SQL injection | Drift parameterized queries only — no raw concat |

### 4.6 Performance Budgets (codified Phase 6)

| Metric | Budget | Measurement |
|--------|--------|-------------|
| Cold startup (Windows) | ≤ 1.5s | `flutter run --profile`, time to first frame |
| Cold startup (Android mid-range) | ≤ 2.0s | Same |
| Cold startup (Linux) | ≤ 1.8s | Same |
| Library scroll FPS (1000 songs) | ≥ 58 avg | DevTools overlay, 10s sample |
| Visualizer FPS (continuous) | ≥ 58 stable ≥ 5min | Same |
| Jank frames | < 5% in 60s session | DevTools "Slow frames" |
| Memory baseline (1000 songs, no playback) | < 250MB Windows, < 180MB Android | Task Manager / `dumpsys meminfo` |
| Memory during playback + visualizer | < 350MB Windows | Same |
| Disk I/O during scroll | < 5MB/s read | Resource monitor |
| Network (idle) | 0 KB/s | Verify no background polling |

Budgets enforced by CI in Phase 6 — over-budget → fail PR.

### 4.7 Privacy & Telemetry

- **Default:** Zero telemetry. No analytics, no home calls.
- **Optional Phase 6:** Crash reports opt-in via Settings (off by default). When enabled, dialog explains what data is sent.
- **Permissions:** Each permission request has Vietnamese rationale string (Android 11+ requirement + best practice).

---

## 5. Open Questions, Risks & Done Definition

### 5.1 Open Questions — to resolve during implementation

| # | Question | Resolution timing | Default if unresolved |
|---|----------|-------------------|------------------------|
| Q1 | Visualizer: `compute()` (single isolate) vs `Isolate.run` (parallel)? | Phase 3 planning | `compute()` (simpler) |
| Q2 | Drift migration: on app startup or background? | Phase 5 planning | Startup sync (≤ 200ms budget), fallback background |
| Q3 | Theme switch: per-song accent (from cover art) or global only? | Phase 4 planning | Global only Phase 4; per-song = Phase 7+ |
| Q4 | Sound feedback: pre-built asset or procedural? | Phase 4 planning | Procedural (short sine sweep, no licensing) |
| Q5 | Haptic: `HapticFeedback` Flutter default or Android platform-channel patterns? | Phase 4 planning | `HapticFeedback` (sufficient) |
| Q6 | Integration tests: emulator or physical device? | Phase 5 planning | CI = emulator; manual final check = physical device |
| Q7 | Performance regression test: random 1000 songs or fixed dataset? | Phase 5 planning | Fixed dataset (deterministic), commit as fixture |
| Q8 | Cover art cache: in-memory only or persist to disk? | Phase 3 planning | In-memory LRU only (disk already via Drift) |
| Q9 | Material You (Android 12+) dynamic color: support or skip? | Phase 4 planning | Skip Phase 4 (subtle polish scope); Phase 7+ if wanted |
| Q10 | Sentry/Crashlytics: opt-in now or later? | Phase 6 planning | **Skip Phase 6** — AppLogger + GitHub Issues suffice for solo dev |

### 5.2 Risks (Impact × Likelihood)

| # | Risk | Impact | Likelihood | Mitigation |
|---|------|--------|-----------|------------|
| R1 | Phase 3 perf tuning takes longer than estimate | High | High | 20% time buffer; if still fails, ship improvements + create Phase 3.5 |
| R2 | Drift migration (Phase 5) corrupts user data if schema differs | High | Low | Integration test copy production DB pre-ship; rollback plan |
| R3 | Phase 2 state consolidation regression on desktop quirks | High | Medium | Smoke test 3 platforms per sub-step; feature flag `useNewStateManagement` |
| R4 | Phase 4 motion causes jank on low-end Android | Medium | Medium | Honor `disableAnimations`; device budget check |
| R5 | Visualizer isolate migration changes timing → audio sync drift | Medium | Medium | Snapshot test for frame output; A/B 5 songs pre/post |
| R6 | A11y audit finds hard-to-fix widgets (visualizer, lyric) | Medium | High | Mark "decorative" + aria-hidden if no interactive meaning |
| R7 | Phase 6 CI: GitHub Actions free tier slow for 3-platform matrix | Low | Medium | Cache deps; self-hosted runner if needed |
| R8 | Phase 5 coverage grows slowly (visualizer/audio mocks complex) | Medium | Medium | Focus on `lib/core/` (deterministic); accept lower UI coverage |
| R9 | Solo dev burnout over 9 weeks | High | Medium | Each phase = shippable increment; breaks between OK |
| R10 | Cross-platform animation divergence hard to test | Medium | High | Smoke test all 3 platforms; document known differences |

**Top 3 risks to monitor:** R1 (perf), R3 (state regression), R9 (burnout).

### 5.3 Out-of-Scope (explicit non-goals)

To prevent scope creep:
- ❌ New platforms (macOS, iOS, Web feature parity)
- ❌ New KTV features (only polish)
- ❌ Cloud sync / accounts
- ❌ New lyrics sources
- ❌ Plugin/extension API
- ❌ Material You dynamic color
- ❌ Major UI redesign (committed to "polish vi tế")
- ❌ Database schema redesign (only Drift activation, no schema changes)

### 5.4 Consolidated Success Criteria

**Quantitative gates (CI-enforced Phase 6):**
- ✅ `flutter analyze` 0 issues
- ✅ Test count ≥ 600, `lib/core/` coverage ≥ 70%
- ✅ Library scroll ≥ 58 FPS (1000 songs)
- ✅ Cold startup ≤ 1.5s (Windows), 2.0s (Android mid), 1.8s (Linux)
- ✅ Visualizer ≥ 58 FPS stable 5min
- ✅ Jank frames < 5%
- ✅ Memory < 350MB during playback
- ✅ 0 `debugPrint`, 0 `Color(0xFF` in UI, 0 hardcoded UI strings

**Qualitative targets (user review):**
- ✅ "Mượt" — no noticeable jank on scroll/transition/visualizer
- ✅ "Đẹp" — Material 3 ColorScheme coherent, motion language consistent
- ✅ "Chất" — code clean, error messages helpful, no silent failures
- ✅ "Cảm nhận" — haptic/sound/visual feedback at every interaction point, satisfying

**Done definition:** All quantitative gates pass CI + user review qualitative 4/4 pillars.

### 5.5 Deferred (Phase 7+ Roadmap)

Items surfaced during brainstorm but NOT in this spec:
- 🌱 Per-song accent color extraction (dynamic theme from cover art)
- 🌱 Material You (Android 12+ dynamic color)
- 🌱 Cloud sync / cross-device library
- 🌱 Plugin system for audio sources
- 🌱 AI-generated playlists / smart mix
- 🌱 macOS/iOS feature parity
- 🌱 Lyrics translation / romanization
- 🌱 Social features (share, listen-together)

### 5.6 Timeline Summary

| Phase | Duration | Calendar |
|-------|----------|----------|
| Phase 1 — Foundation | 1 week | Week 1 |
| Phase 2 — State Mgmt | 2 weeks | Week 2-3 |
| Phase 3 — Performance | 2 weeks (+ 20% buffer) | Week 4-5 |
| Phase 4 — UI Polish | 1 week | Week 6 |
| Phase 5 — Tests | 2 weeks | Week 7-8 |
| Phase 6 — CI | 1 week | Week 9 |
| **Total** | **9 weeks** | **~2 months** |

Realistic with buffer: **~10-11 weeks**.

---

## 6. References

- Supersedes: `docs/superpowers/specs/2026-06-30-balanced-evolution-design.md` (moved to `docs/superpowers/specs/archive/`)
- Related: `docs/superpowers/plans/2026-06-30-phase1-foundation.md` (Phase 1 plan, to be re-derived from this spec)
- Related: `docs/upgrade_plan.md`, `docs/upgrade_plan_complete.md` (older Vietnamese plans, kept for history)
- Architecture: `docs/architecture.md`
- Settings migration: `docs/migration_guide_settings.md`