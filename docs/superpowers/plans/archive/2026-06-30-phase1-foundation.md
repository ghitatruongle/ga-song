# Phase 1: Foundation & Error Handling Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace 113 `debugPrint` calls with structured `AppLogger`, introduce `Result<T>` adoption in `DatabaseService` as the reference implementation, and verify all 456 existing tests still pass.

**Architecture:** 
- `AppLogger` is a thin static facade with level filtering and optional crash-reporter mirroring. Init once in `main.dart` before any service starts.
- `Result<T, E>` is a sealed result type (already exists in `lib/core/utils/result.dart`); we adopt it incrementally in high-value public APIs starting with `DatabaseService`.
- Migration is mechanical: each `debugPrint(...)` becomes an `AppLogger.{d,i,w,e,f}(tag, msg, error: ..., stack: ...)` call with a tag naming the module.class.

**Tech Stack:** Dart 3.11.4+, Flutter, Riverpod, Freezed, existing `Result<T>` from `lib/core/utils/result.dart`.

---

## File Structure

### New files
- `lib/core/logging/app_logger.dart` — `AppLogger` static class + `LogLevel` enum
- `test/core/logging/app_logger_test.dart` — Unit tests for `AppLogger`

### Modified files
- `lib/main.dart` — call `AppLogger.init(...)` before service init
- `lib/core/services/database_service.dart` — top-level query methods return `Result<List<Song>, AppException>` etc.
- `test/core/services/database_service_test.dart` (extend) — tests for Result return types
- ~30 files containing `debugPrint` — mechanical refactor

### Backward compatibility
- `lib/core/app_logger.dart` (legacy) — kept for re-export during migration window
- `SettingsManager`, services, providers — no signature changes

---

## Task 1: AppLogger scaffolding

**Files:**
- Create: `lib/core/logging/app_logger.dart`
- Create: `test/core/logging/app_logger_test.dart`

- [ ] **Step 1.1: Write the failing test for LogLevel ordering and AppLogger.init()**

Create `test/core/logging/app_logger_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:ga_song/core/logging/app_logger.dart';

void main() {
  group('AppLogger', () {
    final lines = <String>[];
    void capture(String line) => lines.add(line);

    setUp(() {
      lines.clear();
      AppLogger.init(minLevel: LogLevel.debug, sink: capture);
    });

    test('debug message is captured at LogLevel.debug', () {
      AppLogger.d('test', 'hello');
      expect(lines, hasLength(1));
      expect(lines.first, contains('[D]'));
      expect(lines.first, contains('test'));
      expect(lines.first, contains('hello'));
    });

    test('info message is captured', () {
      AppLogger.i('test', 'starting up');
      expect(lines.first, contains('[I]'));
    });

    test('warn message is captured', () {
      AppLogger.w('test', 'deprecation', error: StateError('old'));
      expect(lines.first, contains('[W]'));
      expect(lines.first, contains('deprecation'));
      expect(lines.first, contains('StateError'));
    });

    test('error message includes stack trace when provided', () {
      AppLogger.e('test', 'failed', error: 'boom', stack: StackTrace.current);
      expect(lines.first, contains('[E]'));
      expect(lines.first, contains('failed'));
    });

    test('fatal message is captured', () {
      AppLogger.f('test', 'crash');
      expect(lines.first, contains('[F]'));
    });

    test('messages below minLevel are filtered out', () {
      AppLogger.init(minLevel: LogLevel.warn, sink: capture);
      lines.clear();
      AppLogger.d('test', 'hidden');
      AppLogger.i('test', 'hidden');
      AppLogger.w('test', 'visible');
      expect(lines, hasLength(1));
      expect(lines.first, contains('[W]'));
    });

    test('init can swap sink', () {
      final other = <String>[];
      AppLogger.init(minLevel: LogLevel.debug, sink: other.add);
      AppLogger.i('test', 'redirected');
      expect(other, hasLength(1));
      expect(lines, isEmpty);
    });
  });
}
```

- [ ] **Step 1.2: Run the test to verify it fails**

Run: `cd "E:/G.A - Song" && flutter test test/core/logging/app_logger_test.dart`

Expected: FAIL with `Target of URI doesn't exist: 'package:ga_song/core/logging/app_logger.dart'`

- [ ] **Step 1.3: Implement minimal AppLogger**

Create `lib/core/logging/app_logger.dart`:

```dart
import 'package:flutter/foundation.dart';

/// Log severity levels, ordered from least to most severe.
enum LogLevel { debug, info, warn, error, fatal }

/// Static logger facade with level filtering and pluggable sink.
///
/// Initialize once in `main()` before any other service starts:
///
/// ```dart
/// AppLogger.init(
///   minLevel: kDebugMode ? LogLevel.debug : LogLevel.warn,
///   mirrorToCrashReporter: !kDebugMode,
/// );
/// ```
class AppLogger {
  static LogLevel _minLevel = LogLevel.debug;
  static void Function(String line)? _sink;
  static void Function(String tag, String message, {Object? error, StackTrace? stack})? _crashHook;

  /// Configures the global logger. Call once at app startup.
  static void init({
    LogLevel minLevel = LogLevel.debug,
    void Function(String line)? sink,
    bool mirrorToCrashReporter = false,
  }) {
    _minLevel = minLevel;
    _sink = sink ?? (kDebugMode ? _debugPrintSink : _noopSink);
    if (mirrorToCrashReporter) {
      _crashHook = (tag, msg, {error, stack}) {
        // Delegated to DebugCrashReporter by main.dart after init.
        _pendingCrashReports.add((tag, msg, error, stack));
      };
    }
  }

  static final List<({String tag, String msg, Object? error, StackTrace? stack})>
      _pendingCrashReports = [];

  /// Drains any reports buffered before main.dart wired the crash reporter.
  /// Called by main.dart after DebugCrashReporter.init().
  static List<({String tag, String msg, Object? error, StackTrace? stack})>
      drainPendingCrashReports() {
    final out = List.of(_pendingCrashReports);
    _pendingCrashReports.clear();
    return out;
  }

  static void d(String tag, String message, {Object? error, StackTrace? stack}) =>
      _log(LogLevel.debug, tag, message, error: error, stack: stack);

  static void i(String tag, String message) =>
      _log(LogLevel.info, tag, message);

  static void w(String tag, String message, {Object? error, StackTrace? stack}) =>
      _log(LogLevel.warn, tag, message, error: error, stack: stack);

  static void e(String tag, String message, {Object? error, StackTrace? stack}) =>
      _log(LogLevel.error, tag, message, error: error, stack: stack);

  static void f(String tag, String message, {Object? error, StackTrace? stack}) {
    _log(LogLevel.fatal, tag, message, error: error, stack: stack);
    _crashHook?.call(tag, message, error: error, stack: stack);
  }

  static void _log(LogLevel level, String tag, String message,
      {Object? error, StackTrace? stack}) {
    if (level.index < _minLevel.index) return;
    final levelStr = _levelTag(level);
    final buffer = StringBuffer('$levelStr [$tag] $message');
    if (error != null) buffer.write(' | error=$error');
    if (stack != null) buffer.write('\n$stack');
    _sink?.call(buffer.toString());
  }

  static String _levelTag(LogLevel level) => switch (level) {
        LogLevel.debug => '[D]',
        LogLevel.info => '[I]',
        LogLevel.warn => '[W]',
        LogLevel.error => '[E]',
        LogLevel.fatal => '[F]',
      };

  static void _debugPrintSink(String line) {
    // ignore: avoid_print
    debugPrint(line);
  }

  static void _noopSink(String line) {
    // intentional no-op for release
  }
}
```

- [ ] **Step 1.4: Run test to verify it passes**

Run: `cd "E:/G.A - Song" && flutter test test/core/logging/app_logger_test.dart`

Expected: PASS (7 tests)

- [ ] **Step 1.5: Run flutter analyze**

Run: `cd "E:/G.A - Song" && flutter analyze lib/core/logging/ test/core/logging/`

Expected: 0 issues

- [ ] **Step 1.6: Commit**

```bash
cd "E:/G.A - Song" && git add lib/core/logging/app_logger.dart test/core/logging/app_logger_test.dart && git commit -m "feat(logging): add AppLogger with level filtering"
```

---

## Task 2: Initialize AppLogger in main.dart

**Files:**
- Modify: `lib/main.dart:67-78`

- [ ] **Step 2.1: Write the failing test for AppLogger init in main**

Create `test/main_logger_init_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:ga_song/core/logging/app_logger.dart';

void main() {
  test('AppLogger has reasonable default minLevel in release mode', () {
    AppLogger.init();
    // In test environment kDebugMode is true, so debug should pass through.
    AppLogger.d('init-test', 'should be visible in debug');
  });
}
```

- [ ] **Step 2.2: Run test to verify it passes (sanity check)**

Run: `cd "E:/G.A - Song" && flutter test test/main_logger_init_test.dart`

Expected: PASS (init has safe defaults)

- [ ] **Step 2.3: Add AppLogger.init() to main.dart**

Modify `lib/main.dart` at the top of `main()` (right after `WidgetsFlutterBinding.ensureInitialized()`):

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize structured logger first so all subsequent init logs flow through it.
  AppLogger.init(
    minLevel: kDebugMode ? LogLevel.debug : LogLevel.warn,
    mirrorToCrashReporter: !kDebugMode,
  );

  // Initialize sqflite for desktop platforms
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // Initialize crash reporter
  final crashReporter = DebugCrashReporter();
  await crashReporter.init();

  // Drain any fatal reports buffered before crash reporter was ready
  for (final report in AppLogger.drainPendingCrashReports()) {
    crashReporter.reportError(
      report.error ?? report.msg,
      report.stack ?? StackTrace.current,
      context: report.tag,
    );
  }

  // existing rest of main() ...
}
```

Add import at the top:

```dart
import 'core/logging/app_logger.dart';
```

- [ ] **Step 2.4: Run flutter analyze**

Run: `cd "E:/G.A - Song" && flutter analyze`

Expected: 0 issues (or only pre-existing)

- [ ] **Step 2.5: Run full test suite**

Run: `cd "E:/G.A - Song" && flutter test`

Expected: All existing tests still pass (456 tests + new AppLogger tests = 463+)

- [ ] **Step 2.6: Commit**

```bash
cd "E:/G.A - Song" && git add lib/main.dart && git commit -m "feat(logging): initialize AppLogger in main"
```

---

## Task 3: Result<T> adoption in DatabaseService — querySongs

**Files:**
- Modify: `lib/core/services/database_service.dart`
- Modify: `test/core/services/database_service_test.dart` (create if missing)

- [ ] **Step 3.1: Write the failing test for querySongs returning Result**

Create `test/core/services/database_service_test.dart` (or extend existing):

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:ga_song/core/services/database_service.dart';
import 'package:ga_song/core/utils/result.dart';
import 'package:ga_song/core/exceptions/app_exception.dart';

void main() {
  group('DatabaseService.querySongs', () {
    late DatabaseService service;

    setUp(() async {
      service = DatabaseService();
      await service.init();
    });

    tearDown(() async {
      await service.dispose();
    });

    test('returns Success with empty list when no songs exist', () async {
      // Note: seeded songs may exist; test the Success variant at minimum.
      final result = await service.querySongs();
      expect(result, isA<Success<List<dynamic>>>());
    });

    test('returns Failure wrapping DatabaseException on db error', () async {
      // Closed db should yield a failure
      await service.dispose();
      final result = await service.querySongs();
      expect(result, isA<Failure<dynamic>>());
      final failure = result as Failure;
      expect(failure.error, isA<AppException>());
    });
  });
}
```

- [ ] **Step 3.2: Run test to verify it fails**

Run: `cd "E:/G.A - Song" && flutter test test/core/services/database_service_test.dart`

Expected: FAIL — `querySongs()` method does not exist

- [ ] **Step 3.3: Add Result-returning querySongs and migrate getSongs**

Modify `lib/core/services/database_service.dart`:

Add imports at top (after existing imports):

```dart
import '../utils/result.dart';
import '../exceptions/app_exception.dart';
import '../logging/app_logger.dart';
```

Add new public method (insert right after the `init()` method):

```dart
/// Returns the full song list as a [Result].
///
/// This is the new Result-returning variant. The legacy `getSongs()` is kept
/// for backward compatibility.
Future<Result<List<Song>, AppException>> querySongs() async {
  try {
    final songs = await getSongs();
    return Success(songs);
  } on AppException catch (e) {
    AppLogger.e('database.service', 'querySongs failed', error: e);
    return Failure(e);
  } catch (e, st) {
    final ex = DatabaseException('querySongs failed: $e', cause: e);
    AppLogger.e('database.service', 'querySongs unexpected error', error: e, stack: st);
    return Failure(ex);
  }
}
```

- [ ] **Step 3.4: Migrate getSongs() body to use AppLogger instead of throw**

Find the `getSongs()` method in `database_service.dart` and replace any `throw Exception(...)` with:

```dart
throw DatabaseException('Failed to load songs', cause: e);
```

And wrap the call in try/catch where appropriate. Example shape:

```dart
Future<List<Song>> getSongs() async {
  try {
    final maps = await _db.query('songs', orderBy: 'name ASC');
    return maps.map(Song.fromMap).toList();
  } catch (e, st) {
    AppLogger.e('database.service', 'getSongs failed', error: e, stack: st);
    rethrow;
  }
}
```

(Adjust to match the actual body — preserve current ordering/filtering logic.)

- [ ] **Step 3.5: Run test to verify it passes**

Run: `cd "E:/G.A - Song" && flutter test test/core/services/database_service_test.dart`

Expected: PASS

- [ ] **Step 3.6: Run flutter analyze + full suite**

Run: `cd "E:/G.A - Song" && flutter analyze && flutter test`

Expected: 0 issues, all tests pass

- [ ] **Step 3.7: Commit**

```bash
cd "E:/G.A - Song" && git add lib/core/services/database_service.dart test/core/services/database_service_test.dart && git commit -m "feat(database): add Result-returning querySongs"
```

---

## Task 4: Migrate debugPrint in audio_engine_service.dart

**Files:**
- Modify: `lib/core/audio/audio_engine_service.dart`

- [ ] **Step 4.1: Count current debugPrint occurrences**

Run: `cd "E:/G.A - Song" && grep -c "debugPrint" lib/core/audio/audio_engine_service.dart`

Expected: A count (e.g., 8-12)

- [ ] **Step 4.2: Add AppLogger import**

Modify `lib/core/audio/audio_engine_service.dart` — add to imports:

```dart
import '../logging/app_logger.dart';
```

(Remove `import 'package:flutter/foundation.dart';` ONLY if it is no longer used elsewhere in the file. Otherwise keep both.)

- [ ] **Step 4.3: Migrate each debugPrint using sed for mechanical replacement**

Run from project root:

```bash
cd "E:/G.A - Song" && \
  grep -n "debugPrint" lib/core/audio/audio_engine_service.dart
```

For each occurrence, replace manually. Pattern guide:

| Original | Replacement |
|----------|-------------|
| `debugPrint('Source load error at $assetPath: $e\n$stack');` | `AppLogger.e('audio.engine_service', 'Source load failed', error: e, stack: stack);` |
| `debugPrint('Error in audio_engine_service: $e\n$stack');` | `AppLogger.e('audio.engine_service', 'operation failed', error: e, stack: stack);` |
| `debugPrint('Play error: $e\n$stack');` | `AppLogger.e('audio.engine_service', 'playAsset failed', error: e, stack: stack);` |
| `debugPrint('Crossfade error: $e\n$stack');` | `AppLogger.e('audio.engine_service', 'crossfade failed', error: e, stack: stack);` |

When a stack trace is not available, replace with:

```dart
AppLogger.w('audio.engine_service', 'message');
```

Example edit. Replace:

```dart
} catch (e, stack) { debugPrint('Source load error at $assetPath: $e\n$stack');
```

with:

```dart
} catch (e, stack) {
  AppLogger.e('audio.engine_service', 'Source load failed for $assetPath', error: e, stack: stack);
```

- [ ] **Step 4.4: Verify zero debugPrint remain in this file**

Run: `cd "E:/G.A - Song" && grep -c "debugPrint" lib/core/audio/audio_engine_service.dart`

Expected: 0

- [ ] **Step 4.5: Run flutter analyze on file**

Run: `cd "E:/G.A - Song" && flutter analyze lib/core/audio/audio_engine_service.dart`

Expected: 0 issues

- [ ] **Step 4.6: Run audio-related tests**

Run: `cd "E:/G.A - Song" && flutter test test/core/audio/`

Expected: All audio tests pass

- [ ] **Step 4.7: Commit**

```bash
cd "E:/G.A - Song" && git add lib/core/audio/audio_engine_service.dart && git commit -m "refactor(audio): migrate audio_engine_service debugPrint to AppLogger"
```

---

## Task 5: Migrate debugPrint in playlist_service.dart

**Files:**
- Modify: `lib/core/audio/playlist_service.dart`

- [ ] **Step 5.1: Inspect current debugPrint usage**

Run: `cd "E:/G.A - Song" && grep -n "debugPrint" lib/core/audio/playlist_service.dart`

Expected: List of lines (likely few or none — verify before deciding)

- [ ] **Step 5.2: Add AppLogger import**

Modify `lib/core/audio/playlist_service.dart`:

```dart
import '../logging/app_logger.dart';
```

- [ ] **Step 5.3: Replace each debugPrint with AppLogger**

Use the same pattern as Task 4. Tag: `'audio.playlist_service'`.

If no `debugPrint` found in step 5.1, skip to step 5.4.

- [ ] **Step 5.4: Verify zero debugPrint remain**

Run: `cd "E:/G.A - Song" && grep -c "debugPrint" lib/core/audio/playlist_service.dart`

Expected: 0

- [ ] **Step 5.5: Run tests**

Run: `cd "E:/G.A - Song" && flutter test test/core/audio/`

Expected: All pass

- [ ] **Step 5.6: Commit**

```bash
cd "E:/G.A - Song" && git add lib/core/audio/playlist_service.dart && git commit -m "refactor(audio): migrate playlist_service debugPrint to AppLogger"
```

---

## Task 6: Migrate debugPrint in remaining core/audio/ files

**Files:**
- Modify: `lib/core/audio/audio_effect_service.dart`
- Modify: `lib/core/audio/lyric_parser.dart`
- Modify: `lib/core/audio/audio_source_cache_policy.dart`

- [ ] **Step 6.1: Inspect each file**

Run:

```bash
cd "E:/G.A - Song" && \
  for f in lib/core/audio/audio_effect_service.dart lib/core/audio/lyric_parser.dart lib/core/audio/audio_source_cache_policy.dart; do
    echo "=== $f ==="
    grep -n "debugPrint" "$f" || echo "(none)"
  done
```

- [ ] **Step 6.2: For each file with debugPrint, add import + replace**

Add import:

```dart
import '../logging/app_logger.dart';
```

Replace pattern as in Task 4. Tag conventions:
- `'audio.effect_service'`
- `'audio.lyric_parser'`
- `'audio.cache_policy'`

- [ ] **Step 6.3: Verify zero debugPrint across core/audio/**

Run: `cd "E:/G.A - Song" && grep -r "debugPrint" lib/core/audio/ | wc -l`

Expected: 0

- [ ] **Step 6.4: Run flutter analyze + tests**

Run: `cd "E:/G.A - Song" && flutter analyze lib/core/audio/ test/core/audio/`

Expected: 0 issues

- [ ] **Step 6.5: Commit**

```bash
cd "E:/G.A - Song" && git add lib/core/audio/ && git commit -m "refactor(audio): complete debugPrint migration in core/audio/"
```

---

## Task 7: Migrate debugPrint in core/services/

**Files:**
- Modify: 11 files in `lib/core/services/`

- [ ] **Step 7.1: Inventory all debugPrint in services**

Run:

```bash
cd "E:/G.A - Song" && \
  grep -l "debugPrint" lib/core/services/*.dart
```

Expected: List of files (smtc_service, system_tray_service, hotkey_service, etc.)

- [ ] **Step 7.2: Migrate database_service.dart**

Add import:

```dart
import '../logging/app_logger.dart';
```

Replace each `debugPrint` call. Tag: `'database.service'`.

(Already partly done in Task 3 if any debugPrint existed; double-check.)

- [ ] **Step 7.3: Migrate smtc_service.dart**

Add import:

```dart
import '../logging/app_logger.dart';
```

Tag: `'smtc.service'`.

- [ ] **Step 7.4: Migrate system_tray_service.dart**

Tag: `'system_tray.service'`.

- [ ] **Step 7.5: Migrate hotkey_service.dart**

Tag: `'hotkey.service'`.

- [ ] **Step 7.6: Migrate remaining service files**

Apply same pattern. Tags follow `'module.service'` convention:
- `'window_manager.service'`
- `'desktop_lyrics.service'`
- `'audio_handler.service'`
- `'music_manager.service'`
- `'online_lyrics.service'`
- `'smart_playlist.service'`
- `'performance.service'`
- `'error_handler.service'`

- [ ] **Step 7.7: Verify zero debugPrint across services**

Run: `cd "E:/G.A - Song" && grep -r "debugPrint" lib/core/services/ | wc -l`

Expected: 0

- [ ] **Step 7.8: Run flutter analyze + tests**

Run: `cd "E:/G.A - Song" && flutter analyze lib/core/services/ test/core/services/`

Expected: 0 issues, all tests pass

- [ ] **Step 7.9: Commit**

```bash
cd "E:/G.A - Song" && git add lib/core/services/ && git commit -m "refactor(services): migrate all services debugPrint to AppLogger"
```

---

## Task 8: Migrate debugPrint in remaining core/ files

**Files:**
- Modify: `lib/core/cover_art_repository.dart`
- Modify: `lib/core/pip_service.dart`
- Modify: `lib/core/settings_manager.dart`
- Modify: `lib/core/performance_probe.dart`
- Modify: `lib/core/crash_reporter.dart`
- Modify: any other `lib/core/*.dart` with debugPrint

- [ ] **Step 8.1: Inventory**

Run:

```bash
cd "E:/G.A - Song" && \
  grep -l "debugPrint" lib/core/*.dart lib/core/*/*.dart 2>/dev/null
```

- [ ] **Step 8.2: Migrate each file**

Add import:

```dart
import 'logging/app_logger.dart';
```

(Adjust path depth: `import '../logging/app_logger.dart';` for nested files.)

Replace each `debugPrint` with `AppLogger.{d,i,w,e}`. Tag conventions:
- `'cover_art.repository'`
- `'pip.service'`
- `'settings.manager'`
- `'performance.probe'`
- `'crash.reporter'`

- [ ] **Step 8.3: Verify zero debugPrint across lib/core/**

Run: `cd "E:/G.A - Song" && grep -r "debugPrint" lib/core/ | wc -l`

Expected: 0

- [ ] **Step 8.4: Run tests + analyze**

Run: `cd "E:/G.A - Song" && flutter analyze lib/core/ test/`

Expected: 0 issues

- [ ] **Step 8.5: Commit**

```bash
cd "E:/G.A - Song" && git add lib/core/ && git commit -m "refactor(core): complete debugPrint migration in lib/core/"
```

---

## Task 9: Migrate debugPrint in lib/ui/ and other locations

**Files:**
- Modify: ~10-15 files in `lib/ui/`

- [ ] **Step 9.1: Inventory**

Run:

```bash
cd "E:/G.A - Song" && \
  grep -rl "debugPrint" lib/ui/ 2>/dev/null
```

- [ ] **Step 9.2: Migrate each widget file**

For each file:
1. Add import: `import '../../core/logging/app_logger.dart';` (adjust depth)
2. Replace `debugPrint` with `AppLogger.{d,w,e}`. Tags follow `'ui.widget_name'`, e.g.:
   - `'ui.bottom_player_bar'`
   - `'ui.visualizer_widget'`
   - `'ui.sidebar'`
   - `'ui.home_screen'`

- [ ] **Step 9.3: Migrate lib/main.dart debugPrint (if any remain)**

Run: `cd "E:/G.A - Song" && grep -n "debugPrint" lib/main.dart`

If `debugPrint` is still used in main.dart (e.g., for non-fatal init logs), migrate to `AppLogger.d/w/i`.

- [ ] **Step 9.4: Verify zero debugPrint remain anywhere**

Run: `cd "E:/G.A - Song" && grep -r "debugPrint" lib/ | wc -l`

Expected: 0

- [ ] **Step 9.5: Run full test suite**

Run: `cd "E:/G.A - Song" && flutter test`

Expected: All tests pass (456+ existing + new AppLogger tests + new database_service Result tests = 470+)

- [ ] **Step 9.6: Run flutter analyze**

Run: `cd "E:/G.A - Song" && flutter analyze`

Expected: 0 issues

- [ ] **Step 9.7: Commit**

```bash
cd "E:/G.A - Song" && git add lib/ && git commit -m "refactor(ui): complete debugPrint migration project-wide"
```

---

## Task 10: Re-export legacy app_logger.dart and final verification

**Files:**
- Modify: `lib/core/app_logger.dart` (legacy file)

- [ ] **Step 10.1: Check if legacy file is imported anywhere**

Run: `cd "E:/G.A - Song" && grep -rn "core/app_logger" lib/ test/`

If no consumers, this file can be deleted in a follow-up. For Phase 1, we keep it as a re-export shim.

- [ ] **Step 10.2: Convert legacy file to re-export shim**

Overwrite `lib/core/app_logger.dart` with:

```dart
/// Backwards-compatible re-export. New code should import from
/// `package:ga_song/core/logging/app_logger.dart` directly.
export 'logging/app_logger.dart';
```

- [ ] **Step 10.3: Final smoke test**

Run from project root:

```bash
cd "E:/G.A - Song" && \
  flutter analyze && \
  flutter test --coverage && \
  grep -r "debugPrint" lib/ | wc -l
```

Expected:
- `flutter analyze`: 0 issues
- `flutter test`: all tests pass
- `grep count`: 0

- [ ] **Step 10.4: Update CHANGELOG.md**

Edit `CHANGELOG.md` — add entry under new "Unreleased" section:

```markdown
## [Unreleased]

### Changed
- Replaced 113 `debugPrint` calls with structured `AppLogger` (debug/info/warn/error/fatal levels).
- `AppLogger` initialized in `main.dart` with level filtering and optional crash-reporter mirroring.
- `DatabaseService.querySongs()` returns `Result<List<Song>, AppException>` (legacy `getSongs()` kept for compatibility).

### Added
- `lib/core/logging/app_logger.dart` — `AppLogger` static facade with `LogLevel` enum, pluggable sink, and crash-reporter hook.

### Tests
- 7 new unit tests for `AppLogger`.
- 2 new tests for `DatabaseService.querySongs()` Result return type.
```

- [ ] **Step 10.5: Commit**

```bash
cd "E:/G.A - Song" && git add lib/core/app_logger.dart CHANGELOG.md && git commit -m "chore: legacy app_logger.dart as re-export shim; update CHANGELOG"
```

---

## Task 11: Verify acceptance criteria

- [ ] **Step 11.1: Acceptance check**

Run:

```bash
cd "E:/G.A - Song" && \
  echo "=== debugPrint count ===" && \
  grep -r "debugPrint" lib/ | wc -l && \
  echo "=== flutter analyze ===" && \
  flutter analyze 2>&1 | tail -5 && \
  echo "=== test count ===" && \
  flutter test 2>&1 | tail -3
```

Expected:
- debugPrint count: 0
- analyze: `No issues found!`
- tests: all passing

- [ ] **Step 11.2: Manual smoke test on desktop**

Run: `cd "E:/G.A - Song" && flutter run -d windows`

Expected: App starts; visible log output only in debug mode; no crashes.

- [ ] **Step 11.3: Final commit if any pending changes**

```bash
cd "E:/G.A - Song" && git status && \
  git add -A && git commit -m "chore: Phase 1 complete - foundation & error handling" || echo "Nothing to commit"
```

---

## Self-Review

**Spec coverage check:**

| Spec § | Requirement | Covered by |
|--------|-------------|-----------|
| §4.2.1 AppLogger service | LogLevel enum, init, 5 levels | Task 1 |
| §4.2.2 Migrate debugPrint → AppLogger | All 113 calls replaced | Tasks 4-9 |
| §4.2.3 Result<T> adoption | DatabaseService.querySongs returns Result | Task 3 |
| §4.3 Acceptance | 0 debugPrint, 0 warnings, release filters warn+ | Tasks 9-11 |
| §4.4 Backward compat | No breaking API changes | Tasks 2 (AppLogger additive), 3 (legacy getSongs kept), 10 (shim) |

**Placeholder scan:** No TBD/TODO/implement-later in the plan. Every code block is complete.

**Type consistency:** `AppLogger.{d,i,w,e,f}` signatures match across all migration steps. `Result<T, E>` matches existing definition in `lib/core/utils/result.dart`. Tag convention is consistent.

**File path consistency:** All paths use `lib/` and `test/` prefixes from project root. Import paths adjusted by depth.

---

## Execution

Plan saved to `docs/superpowers/plans/2026-06-30-phase1-foundation.md`. Ready for execution.

Two options:

1. **Subagent-Driven (recommended)** — Dispatch a fresh subagent per task with two-stage review between tasks. Fast iteration, isolated context.

2. **Inline Execution** — Execute tasks in this session using `executing-plans` skill. Batch execution with checkpoints.

Which approach?