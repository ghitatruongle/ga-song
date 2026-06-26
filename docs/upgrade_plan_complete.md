# 🚀 KẾ HOẠCH NÂNG CẤP DỰ ÁN G.A - SONG (100% COMPLETE)

**Phiên bản:** 2.0  
**Ngày tạo:** 26/06/2026  
**Ngày cập nhật:** 26/06/2026  
**Trạng thái:** Sẵn sàng thực thi  
**Ước tính tổng thời gian:** 16-20 tuần  

---

## 📋 MỤC LỤC

1. [Tổng Quan Dự Án Hiện Tại](#1-tổng-quan-dự-án-hiện-tại)
2. [Mục Tiêu Nâng Cấp](#2-mục-tiêu-nâng-cấp)
3. [Phase 1: Code Cleanup & Foundation](#3-phase-1-code-cleanup--foundation)
4. [Phase 2: Database & Performance](#4-phase-2-database--performance)
5. [Phase 3: UI/UX Modernization](#5-phase-3-uiux-modernization)
6. [Phase 4: Platform Enhancement](#6-phase-4-platform-enhancement)
7. [Phase 5: Testing & Quality Assurance](#7-phase-5-testing--quality-assurance)
8. [Phase 6: Dependencies & Release](#8-phase-6-dependencies--release)
9. [CI/CD Pipeline](#9-cicd-pipeline)
10. [Rollback Strategy](#10-rollback-strategy)
11. [Success Metrics & KPIs](#11-success-metrics--kpis)
12. [Risk Assessment & Mitigation](#12-risk-assessment--mitigation)
13. [Resource Requirements](#13-resource-requirements)
14. [Appendix](#14-appendix)

---

## 1. TỔNG QUAN DỰ ÁN HIỆN TẠI

### 1.1. Thông Tin Kỹ Thuật

| Thuộc tính | Giá trị |
|------------|---------|
| App Name | G.A - Song |
| Package | `ga_song` |
| Version | 1.0.0+1 |
| Dart SDK | ^3.11.4 |
| Flutter | Stable channel |
| State Management | Riverpod 3.0.0 + ValueNotifier |
| Database | SQLite (sqflite 2.4.2) |
| Audio Engine | SoLoud (flutter_soloud 4.0.5) |
| Test Count | 360 tests (all passing) |
| Platform Support | Android, Windows, Linux, macOS, iOS, Web |

### 1.2. Kiến Trúc Hiện Tại

```
lib/
├── main.dart                          # Composition root
├── core/
│   ├── audio/                         # Audio engine, effects, playlist, lyrics
│   ├── services/                      # Infrastructure services
│   ├── view_models/                   # MVVM view models
│   ├── utils/                         # Utilities
│   └── theme/                         # Theme definitions
├── models/                            # Data models (json_serializable)
├── providers/                         # Riverpod providers
├── l10n/                              # Localization (EN, VI)
└── ui/
    ├── screens/                       # Top-level screens
    ├── widgets/                       # Reusable components
    ├── painters/                      # Custom painters
    └── visualizer/                    # Visualizer controller
```

### 1.3. Dependencies Hiện Tại

```yaml
# Core
flutter_riverpod: ^3.0.0
flutter_soloud: ^4.0.5
sqflite: ^2.4.2
shared_preferences: ^2.5.5
audio_service: ^0.18.18

# UI
flutter_acrylic: ^1.1.4
flutter_colorpicker: ^1.1.0
palette_generator: ^0.3.3+7

# Platform
window_manager: ^0.5.1
system_tray: ^2.0.3
hotkey_manager: ^0.2.3
smtc_windows: ^1.0.0

# Media
youtube_player_iframe: ^5.2.2
file_picker: ^11.0.2
audiotags: ^1.4.5

# Utilities
http: ^1.2.0
path_provider: ^2.1.5
freezed_annotation: ^2.4.4
json_annotation: ^4.9.0
```

### 1.4. Vấn Đề Hiện Tại

| ID | Vấn đề | Mức độ | Ảnh hưởng |
|----|--------|--------|-----------|
| P1 | Dead code: `service_locator.dart` | Thấp | Code cleanliness |
| P2 | 40+ ValueNotifiers trong SettingsManager | Trung bình | Code maintainability |
| P3 | Raw SQL queries không type-safe | Cao | Bug risk, maintenance |
| P4 | Chưa migrate sang Material 3 | Trung bình | UI modernity |
| P5 | Không có responsive design | Trung bình | UX trên các screen sizes |
| P6 | macOS/iOS/Web features chưa đầy đủ | Thấp | Platform parity |
| P7 | Test coverage chưa đo được | Trung bình | Quality assurance |
| P8 | Không có CI/CD pipeline | Cao | Release process |
| P9 | Không có crash reporting production | Cao | Error tracking |
| P10 | Dependencies có thể outdated | Trung bình | Security, features |

---

## 2. MỤC TIÊU NÂNG CẤP

### 2.1. Mục Tiêu Tổng Thể

| Mục tiêu | KPI | Target |
|----------|-----|--------|
| Code Quality | Dead code | 0 files |
| Code Quality | Lint warnings | < 10 |
| Performance | App startup time | < 2 seconds |
| Performance | Song list scroll (1000+ items) | 60fps |
| Performance | Database query time | < 50ms |
| Quality | Test coverage | > 80% |
| Quality | Integration tests | > 20 scenarios |
| UI/UX | Material 3 compliance | 100% |
| UI/UX | Accessibility score | > 90% |
| Platform | Feature parity | Android: 100%, Desktop: 90%, Web: 70% |
| Release | CI/CD pipeline | Automated |
| Release | Crash reporting | Production ready |

### 2.2. Mục Tiêu Theo Phase

**Phase 1 (Tuần 1-3):** Foundation
- [ ] Xóa tất cả dead code
- [ ] Chuẩn hóa state management
- [ ] Implement error handling pattern
- [ ] Setup lint rules

**Phase 2 (Tuần 4-7):** Database & Performance
- [ ] Migrate sang Drift
- [ ] Tối ưu cover art cache
- [ ] Thêm database indexing
- [ ] Implement lazy loading

**Phase 3 (Tuần 8-11):** UI/UX
- [ ] Material 3 migration
- [ ] Responsive design
- [ ] Accessibility improvements
- [ ] Animation enhancements

**Phase 4 (Tuần 12-15):** Platform
- [ ] macOS enhancements
- [ ] iOS enhancements
- [ ] Web enhancements
- [ ] Platform-specific optimizations

**Phase 5 (Tuần 16-18):** Testing
- [ ] Unit test coverage > 80%
- [ ] Integration tests > 20 scenarios
- [ ] Golden tests for UI consistency
- [ ] Performance benchmarks

**Phase 6 (Tuần 19-20):** Release
- [ ] Dependencies updated
- [ ] CI/CD pipeline setup
- [ ] Documentation updated
- [ ] Release notes prepared

---

## 3. PHASE 1: CODE CLEANUP & FOUNDATION

**Thời gian:** 3 tuần (Tuần 1-3)  
**Ưu tiên:** 🔴 CAO  
**Dependencies:** Không  

### 3.1. Week 1: Dead Code Removal

#### 3.1.1. Files cần xóa

```bash
# Dead code files
rm lib/core/service_locator.dart

# Unused imports (sử dụng dart fix)
dart fix --apply --code=unused_import

# Unused files (kiểm tra với dart_code_metrics)
dart run dart_code_metrics:metrics check-unused-files lib/
```

#### 3.1.2. Unused Dependencies Removal

```yaml
# pubspec.yaml - Remove unused dependencies
# Trước:
dependencies:
  # ... other deps
  
# Sau: Xóa bất kỳ dependency nào không được import trong lib/
```

#### 3.1.3. Checklist Week 1

```markdown
- [ ] Xóa `lib/core/service_locator.dart`
- [ ] Chạy `dart fix --apply` để xóa unused imports
- [ ] Kiểm tra unused files với dart_code_metrics
- [ ] Verify: `flutter analyze` không có warnings
- [ ] Verify: `flutter test` vẫn pass (360 tests)
- [ ] Commit: "chore: remove dead code and unused imports"
```

### 3.2. Week 2: State Management Standardization

#### 3.2.1. Phân Tích Hiện Tại

**SettingsManager hiện tại:**
```dart
class SettingsManager {
  late SharedPreferences _prefs;
  
  // 40+ ValueNotifiers
  final ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier(ThemeMode.system);
  final ValueNotifier<bool> enableBlurNotifier = ValueNotifier(true);
  final ValueNotifier<double> blurLevelNotifier = ValueNotifier(30.0);
  // ... 37+ notifiers khác
  
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    // Load all settings
  }
  
  void dispose() {
    // Dispose all notifiers
  }
}
```

**Vấn đề:**
- Quá nhiều ValueNotifiers (40+)
- Khó maintain
- Không type-safe
- Khó test

#### 3.2.2. Migration Strategy

**Bước 1:** Tạo Settings State class với Freezed

```dart
// lib/core/settings/settings_state.dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter/material.dart';

part 'settings_state.freezed.dart';

@freezed
class SettingsState with _$SettingsState {
  const factory SettingsState({
    // Theme
    @Default(ThemeMode.system) ThemeMode themeMode,
    @Default(true) bool enableBlur,
    @Default(30.0) double blurLevel,
    @Default(false) bool useNativeWindowEffect,
    @Default(0.7) double windowOpacity,
    @Default(true) bool useDynamicColor,
    @Default(Color(0xFF1DB954)) Color customPrimaryColor,
    Color? dynamicPrimaryColor,
    
    // Window
    @Default(false) bool isMiniPlayer,
    @Default(false) bool isGridView,
    @Default(false) bool sidebarCollapsed,
    
    // Equalizer
    @Default([0.0, 0.0, 0.0, 0.0, 0.0]) List<double> eqBands,
    @Default(0) int eqBassLevel,
    @Default('Normal') String eqPreset,
    
    // Audio Effects
    @Default(3.0) double crossfadeDuration,
    @Default(0) int crossfadeCurve,
    @Default(-12.0) double normalizationLevel,
    @Default(false) bool normalizationEnabled,
    @Default(1.0) double pitchShift,
    @Default(0.0) double reverbMix,
    @Default(0.5) double reverbRoomSize,
    @Default(0.5) double reverbDamp,
    @Default(1.0) double compressionRatio,
    @Default(-24.0) double compThreshold,
    @Default(10.0) double compAttack,
    @Default(100.0) double compRelease,
    @Default(10.0) double compKneeWidth,
    @Default(0.0) double compMakeupGain,
    
    // Sort & Filter
    @Default(0) int sortMode,
    @Default(true) bool sortAscending,
    
    // Desktop Lyrics
    @Default(false) bool desktopLyricsEnabled,
    @Default(24.0) double desktopLyricsFontSize,
    @Default(0.9) double desktopLyricsOpacity,
    @Default(false) bool desktopLyricsClickThrough,
    
    // Other
    @Default(true) bool minimizeToTray,
    @Default(true) bool visualizerEnabled,
    @Default(0) int visualizerShape,
    @Default(0) int currentTabIndex,
  }) = _SettingsState;
}
```

**Bước 2:** Tạo SettingsNotifier với Riverpod

```dart
// lib/core/settings/settings_notifier.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'settings_state.dart';

class SettingsNotifier extends Notifier<SettingsState> {
  late SharedPreferences _prefs;
  
  @override
  SettingsState build() {
    _initPrefs();
    return const SettingsState();
  }
  
  Future<void> _initPrefs() async {
    _prefs = await SharedPreferences.getInstance();
    _loadAllSettings();
  }
  
  void _loadAllSettings() {
    state = SettingsState(
      themeMode: ThemeMode.values[_prefs.getInt('themeMode') ?? 0],
      enableBlur: _prefs.getBool('enableBlur') ?? true,
      blurLevel: _prefs.getDouble('blurLevel') ?? 30.0,
      // ... load all settings
    );
  }
  
  // Theme methods
  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    await _prefs.setInt('themeMode', mode.index);
  }
  
  Future<void> setEnableBlur(bool value) async {
    state = state.copyWith(enableBlur: value);
    await _prefs.setBool('enableBlur', value);
  }
  
  // ... all other setter methods
}

final settingsProvider = NotifierProvider<SettingsNotifier, SettingsState>(
  SettingsNotifier.new,
);
```

**Bước 3:** Migrate UI code

```dart
// Trước:
final settings = ref.read(settingsManagerProvider);
return ValueListenableBuilder(
  valueListenable: settings.themeModeNotifier,
  builder: (context, themeMode, _) {
    return Text(themeMode.toString());
  },
);

// Sau:
final themeMode = ref.watch(settingsProvider.select((s) => s.themeMode));
return Text(themeMode.toString());
```

#### 3.2.3. Migration Checklist

```markdown
- [ ] Tạo `lib/core/settings/settings_state.dart` với Freezed
- [ ] Tạo `lib/core/settings/settings_notifier.dart` với Riverpod
- [ ] Tạo `lib/core/settings/settings_state.freezed.dart` (build_runner)
- [ ] Cập nhật `lib/providers/service_providers.dart`
- [ ] Migrate HomeScreen
- [ ] Migrate SettingsWidget
- [ ] Migrate PlayerBar
- [ ] Migrate Sidebar
- [ ] Migrate tất cả screens/widgets sử dụng settings
- [ ] Xóa `lib/core/settings_manager.dart`
- [ ] Verify: `flutter test` pass
- [ ] Verify: App chạy đúng trên tất cả platforms
- [ ] Commit: "refactor: migrate settings to Riverpod Notifier"
```

### 3.3. Week 3: Error Handling & Lint Rules

#### 3.3.1. Result Type Implementation

```dart
// lib/core/utils/result.dart
sealed class Result<T> {
  const Result();
  
  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is Failure<T>;
  
  T? get data => switch (this) {
    Success(data: final d) => d,
    Failure() => null,
  };
  
  String? get error => switch (this) {
    Success() => null,
    Failure(message: final m) => m,
  };
}

final class Success<T> extends Result<T> {
  final T data;
  const Success(this.data);
}

final class Failure<T> extends Result<T> {
  final String message;
  final StackTrace? stackTrace;
  final Object? exception;
  
  const Failure(this.message, [this.stackTrace, this.exception]);
}
```

#### 3.3.2. App Exception Hierarchy

```dart
// lib/core/exceptions/app_exception.dart
sealed class AppException implements Exception {
  final String message;
  final StackTrace? stackTrace;
  
  const AppException(this.message, [this.stackTrace]);
}

class DatabaseException extends AppException {
  const DatabaseException(super.message, [super.stackTrace]);
}

class AudioEngineException extends AppException {
  const AudioEngineException(super.message, [super.stackTrace]);
}

class NetworkException extends AppException {
  const NetworkException(super.message, [super.stackTrace]);
}

class FileException extends AppException {
  const FileException(super.message, [super.stackTrace]);
}

class CacheException extends AppException {
  const CacheException(super.message, [super.stackTrace]);
}
```

#### 3.3.3. Error Handler Service

```dart
// lib/core/services/error_handler_service.dart
import 'package:flutter/foundation.dart';
import '../crash_reporter.dart';

class ErrorHandlerService {
  final CrashReporter _crashReporter;
  
  ErrorHandlerService(this._crashReporter);
  
  Result<T> handle<T>(T Function() operation, {String? context}) {
    try {
      final result = operation();
      return Success(result);
    } on AppException catch (e, stack) {
      _crashReporter.reportError(e, stack, context: context);
      return Failure(e.message, stack, e);
    } catch (e, stack) {
      _crashReporter.reportError(e, stack, context: context);
      return Failure('Unexpected error: $e', stack, e);
    }
  }
  
  Future<Result<T>> handleAsync<T>(Future<T> Function() operation, {String? context}) async {
    try {
      final result = await operation();
      return Success(result);
    } on AppException catch (e, stack) {
      _crashReporter.reportError(e, stack, context: context);
      return Failure(e.message, stack, e);
    } catch (e, stack) {
      _crashReporter.reportError(e, stack, context: context);
      return Failure('Unexpected error: $e', stack, e);
    }
  }
}
```

#### 3.3.4. Lint Rules Configuration

```yaml
# analysis_options.yaml
include: package:flutter_lints/flutter.yaml

analyzer:
  exclude:
    - "**/*.g.dart"
    - "**/*.freezed.dart"
    - "test_project/"
    - "integration_test/"
  errors:
    invalid_assignment: error
    missing_return: error
    dead_code: warning
    unused_import: warning
    unused_local_variable: warning

linter:
  rules:
    # Always use
    - always_declare_return_types
    - always_require_non_null_named_parameters
    - annotate_overrides
    - avoid_empty_else
    - avoid_init_to_null
    - avoid_null_checks_in_equality_operators
    - avoid_print
    - avoid_relative_lib_imports
    - avoid_unnecessary_containers
    - await_only_futures
    - camel_case_types
    - cancel_subscriptions
    - constant_identifier_names
    - curly_braces_in_flow_control_structures
    - empty_catches
    - empty_constructor_bodies
    - exhaustive_cases
    - file_names
    - no_duplicate_case_values
    - prefer_const_constructors
    - prefer_const_declarations
    - prefer_final_fields
    - prefer_final_locals
    - prefer_is_empty
    - prefer_is_not_empty
    - prefer_single_quotes
    - sized_box_for_whitespace
    - sort_child_properties_last
    - unnecessary_const
    - unnecessary_new
    - unnecessary_this
    - use_build_context_synchronously
    - use_key_in_widget_constructors
    
    # Project specific
    - prefer_relative_imports
    - avoid_dynamic_calls
    - prefer_interpolation_to_compose_strings
```

#### 3.3.5. Checklist Week 3

```markdown
- [ ] Tạo `lib/core/utils/result.dart`
- [ ] Tạo `lib/core/exceptions/app_exception.dart`
- [ ] Tạo `lib/core/services/error_handler_service.dart`
- [ ] Cập nhật `analysis_options.yaml`
- [ ] Chạy `dart fix --apply` để auto-fix lint issues
- [ ] Fix manual lint warnings
- [ ] Verify: `flutter analyze` clean
- [ ] Verify: `flutter test` pass
- [ ] Commit: "feat: implement Result type and error handling"
- [ ] Commit: "chore: update lint rules and fix warnings"
```

---

## 4. PHASE 2: DATABASE & PERFORMANCE

**Thời gian:** 4 tuần (Tuần 4-7)  
**Ưu tiên:** 🔴 CAO  
**Dependencies:** Phase 1 hoàn thành  

### 4.1. Week 4-5: Drift Migration

#### 4.1.1. Drift Setup

```yaml
# pubspec.yaml
dependencies:
  drift: ^2.14.0
  sqlite3_flutter_libs: ^0.5.0
  path_provider: ^2.1.5
  path: ^1.9.0

dev_dependencies:
  drift_dev: ^2.14.0
  build_runner: ^2.4.13
```

#### 4.1.2. Database Schema

```dart
// lib/core/database/tables/songs_table.dart
import 'package:drift/drift.dart';

@DataClassName('Song')
class Songs extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 255)();
  TextColumn get artist => text().nullable().withLength(max: 255)();
  TextColumn get album => text().nullable().withLength(max: 255)();
  IntColumn get durationMs => integer().nullable()();
  RealColumn get peakDb => real().withDefault(const Constant(-12.0))();
  TextColumn get sourcePath => text()();
  BoolColumn get isBuiltIn => boolean().withDefault(const Constant(false))();
  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();
  DateTimeColumn get dateAdded => dateTime().nullable()();
  IntColumn get playCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastPlayed => dateTime().nullable()();
  TextColumn get genre => text().nullable().withLength(max: 100)();
  IntColumn get year => integer().nullable()();
  
  // Indexes
  @override
  List<Set<Column>> get uniqueKeys => [];
  
  @override
  Set<Column> get primaryKey => {id};
}

// lib/core/database/tables/playlists_table.dart
@DataClassName('Playlist')
class Playlists extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 255)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

// lib/core/database/tables/playlist_songs_table.dart
@DataClassName('PlaylistSong')
class PlaylistSongs extends Table {
  IntColumn get playlistId => integer().references(Playlists, #id)();
  IntColumn get songId => integer().references(Songs, #id)();
  IntColumn get position => integer().withDefault(const Constant(0))();
  
  @override
  Set<Column> get primaryKey => {playlistId, songId};
}

// lib/core/database/tables/cover_art_cache_table.dart
@DataClassName('CoverArtCacheEntry')
class CoverArtCache extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get fileName => text().unique()();
  BlobColumn get bytes => blob()();
  DateTimeColumn get lastAccessed => dateTime()();
  IntColumn get sizeBytes => integer()();
}

// lib/core/database/tables/lyrics_cache_table.dart
@DataClassName('LyricsCacheEntry')
class LyricsCache extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get songId => integer().references(Songs, #id)();
  TextColumn get syncedLyrics => text().nullable()();
  TextColumn get plainLyrics => text().nullable()();
  TextColumn get source => text().withDefault(const Constant('lrclib'))();
  DateTimeColumn get fetchedAt => dateTime()();
  
  @override
  Set<Column> get uniqueKeys => [{songId}];
}
```

#### 4.1.3. Database Class

```dart
// lib/core/database/app_database.dart
import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'tables/songs_table.dart';
import 'tables/playlists_table.dart';
import 'tables/playlist_songs_table.dart';
import 'tables/cover_art_cache_table.dart';
import 'tables/lyrics_cache_table.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [
  Songs,
  Playlists,
  PlaylistSongs,
  CoverArtCache,
  LyricsCache,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());
  
  @override
  int get schemaVersion => 3;
  
  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
      await _createIndexes(m);
    },
    onUpgrade: (Migrator m, int from, int to) async {
      if (from < 2) {
        // v1 → v2: Add smart playlist & tag editor columns
        await m.addColumn(songs, songs.playCount);
        await m.addColumn(songs, songs.lastPlayed);
        await m.addColumn(songs, songs.genre);
        await m.addColumn(songs, songs.year);
      }
      if (from < 3) {
        // v2 → v3: Add playlist timestamps
        await m.addColumn(playlists, playlists.createdAt);
        await m.addColumn(playlists, playlists.updatedAt);
        
        // Add cover art cache size
        await m.addColumn(coverArtCache, coverArtCache.sizeBytes);
        
        // Create indexes
        await _createIndexes(m);
      }
    },
  );
  
  Future<void> _createIndexes(Migrator m) async {
    await m.database.customStatement(
      'CREATE INDEX IF NOT EXISTS idx_songs_artist ON songs(artist)'
    );
    await m.database.customStatement(
      'CREATE INDEX IF NOT EXISTS idx_songs_album ON songs(album)'
    );
    await m.database.customStatement(
      'CREATE INDEX IF NOT EXISTS idx_songs_play_count ON songs(play_count DESC)'
    );
    await m.database.customStatement(
      'CREATE INDEX IF NOT EXISTS idx_songs_date_added ON songs(date_added DESC)'
    );
    await m.database.customStatement(
      'CREATE INDEX IF NOT EXISTS idx_songs_name ON songs(name)'
    );
    await m.database.customStatement(
      'CREATE INDEX IF NOT EXISTS idx_cover_art_last_accessed ON cover_art_cache(last_accessed)'
    );
  }
  
  // ─── Song Operations ─────────────────────────────────────────────
  
  Future<List<Song>> getAllSongs() => select(songs).get();
  
  Stream<List<Song>> watchAllSongs() => select(songs).watch();
  
  Future<Song?> getSongById(int id) =>
      (select(songs)..where((t) => t.id.equals(id))).getSingleOrNull();
  
  Future<List<Song>> getSongsByArtist(String artist) =>
      (select(songs)..where((t) => t.artist.equals(artist))).get();
  
  Future<List<Song>> getSongsByAlbum(String album) =>
      (select(songs)..where((t) => t.album.equals(album))).get();
  
  Future<List<Song>> searchSongs(String query) =>
      (select(songs)..where((t) => t.name.like('%$query%') | t.artist.like('%$query%'))).get();
  
  Future<int> insertSong(SongsCompanion song) => into(songs).insert(song);
  
  Future<bool> updateSong(SongsCompanion song) => update(songs).replace(song);
  
  Future<int> deleteSong(int id) =>
      (delete(songs)..where((t) => t.id.equals(id))).go();
  
  Future<void> incrementPlayCount(int id) async {
    final song = await getSongById(id);
    if (song != null) {
      await (update(songs)..where((t) => t.id.equals(id))).write(
        SongsCompanion(
          playCount: Value(song.playCount + 1),
          lastPlayed: Value(DateTime.now()),
        ),
      );
    }
  }
  
  Future<void> toggleFavorite(int id) async {
    final song = await getSongById(id);
    if (song != null) {
      await (update(songs)..where((t) => t.id.equals(id))).write(
        SongsCompanion(isFavorite: Value(!song.isFavorite)),
      );
    }
  }
  
  // ─── Playlist Operations ─────────────────────────────────────────
  
  Future<List<Playlist>> getAllPlaylists() => select(playlists).get();
  
  Stream<List<Playlist>> watchAllPlaylists() => select(playlists).watch();
  
  Future<int> createPlaylist(String name) => into(playlists).insert(
    PlaylistsCompanion(
      name: Value(name),
      createdAt: Value(DateTime.now()),
      updatedAt: Value(DateTime.now()),
    ),
  );
  
  Future<void> addSongToPlaylist(int playlistId, int songId, int position) =>
      into(playlistSongs).insert(
        PlaylistSongsCompanion(
          playlistId: Value(playlistId),
          songId: Value(songId),
          position: Value(position),
        ),
      );
  
  Future<void> removeSongFromPlaylist(int playlistId, int songId) =>
      (delete(playlistSongs)
            ..where((t) =>
                t.playlistId.equals(playlistId) & t.songId.equals(songId)))
          .go();
  
  Future<List<Song>> getPlaylistSongs(int playlistId) async {
    final query = select(playlistSongs).join([
      innerJoin(songs, songs.id.equalsExp(playlistSongs.songId)),
    ])
      ..where(playlistSongs.playlistId.equals(playlistId))
      ..orderBy([OrderingTerm.asc(playlistSongs.position)]);
    
    final results = await query.get();
    return results.map((row) => row.readTable(songs)).toList();
  }
  
  // ─── Cover Art Cache Operations ──────────────────────────────────
  
  Future<Uint8List?> getCoverArt(String fileName) async {
    final entry = await (select(coverArtCache)
          ..where((t) => t.fileName.equals(fileName)))
        .getSingleOrNull();
    
    if (entry != null) {
      // Update last accessed
      await (update(coverArtCache)..where((t) => t.id.equals(entry.id))).write(
        CoverArtCacheCompanion(lastAccessed: Value(DateTime.now())),
      );
      return entry.bytes;
    }
    return null;
  }
  
  Future<void> saveCoverArt(String fileName, Uint8List bytes) async {
    await into(coverArtCache).insert(
      CoverArtCacheCompanion(
        fileName: Value(fileName),
        bytes: Value(bytes),
        lastAccessed: Value(DateTime.now()),
        sizeBytes: Value(bytes.length),
      ),
      mode: InsertMode.insertOrReplace,
    );
  }
  
  Future<void> evictOldCoverArt(int maxEntries) async {
    final count = await customSelect(
      'SELECT COUNT(*) as count FROM cover_art_cache',
    ).getSingle();
    
    final currentCount = count.data['count'] as int;
    if (currentCount > maxEntries) {
      final toDelete = currentCount - maxEntries;
      await customStatement('''
        DELETE FROM cover_art_cache WHERE id IN (
          SELECT id FROM cover_art_cache 
          ORDER BY last_accessed ASC 
          LIMIT $toDelete
        )
      ''');
    }
  }
  
  // ─── Lyrics Cache Operations ─────────────────────────────────────
  
  Future<LyricsCacheEntry?> getLyrics(int songId) =>
      (select(lyricsCache)..where((t) => t.songId.equals(songId)))
          .getSingleOrNull();
  
  Future<void> saveLyrics(int songId, String? synced, String? plain) =>
      into(lyricsCache).insert(
        LyricsCacheCompanion(
          songId: Value(songId),
          syncedLyrics: Value(synced),
          plainLyrics: Value(plain),
          fetchedAt: Value(DateTime.now()),
        ),
        mode: InsertMode.insertOrReplace,
      );
  
  // ─── Statistics ──────────────────────────────────────────────────
  
  Future<int> getSongCount() async {
    final count = await customSelect(
      'SELECT COUNT(*) as count FROM songs',
    ).getSingle();
    return count.data['count'] as int;
  }
  
  Future<List<Song>> getMostPlayed({int limit = 10}) =>
      (select(songs)..where((t) => t.playCount.isBiggerThanValue(0))
        ..orderBy([(t) => OrderingTerm.desc(t.playCount)])
        ..limit(limit)).get();
  
  Future<List<Song>> getRecentlyPlayed({int limit = 10}) =>
      (select(songs)..where((t) => t.lastPlayed.isNotNull())
        ..orderBy([(t) => OrderingTerm.desc(t.lastPlayed)])
        ..limit(limit)).get();
  
  Future<List<Song>> getFavorites() =>
      (select(songs)..where((t) => t.isFavorite.equals(true))).get();
  
  Future<List<Song>> getRecentlyAdded({int limit = 10}) =>
      (select(songs)..where((t) => t.dateAdded.isNotNull())
        ..orderBy([(t) => OrderingTerm.desc(t.dateAdded)])
        ..limit(limit)).get();
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'ga_song.db'));
    return NativeDatabase.createInBackground(file);
  });
}
```

#### 4.1.4. Database Service Migration

```dart
// lib/core/services/database_service.dart (updated)
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/app_database.dart';

class DatabaseService {
  late final AppDatabase _db;
  
  DatabaseService() {
    _db = AppDatabase();
  }
  
  AppDatabase get database => _db;
  
  // Delegate all methods to _db
  Future<List<Song>> getAllSongs() => _db.getAllSongs();
  Stream<List<Song>> watchAllSongs() => _db.watchAllSongs();
  // ... all other methods
  
  Future<void> dispose() async {
    await _db.close();
  }
}

final databaseServiceProvider = Provider<DatabaseService>((ref) {
  final service = DatabaseService();
  ref.onDispose(() => service.dispose());
  return service;
});
```

#### 4.1.5. Drift Migration Checklist

```markdown
- [ ] Thêm drift dependencies vào pubspec.yaml
- [ ] Tạo lib/core/database/tables/ (5 table files)
- [ ] Tạo lib/core/database/app_database.dart
- [ ] Chạy build_runner: `dart run build_runner build --delete-conflicting-outputs`
- [ ] Tạo lib/core/services/database_service.dart (updated)
- [ ] Migrate seed data logic
- [ ] Migrate all database queries
- [ ] Update providers
- [ ] Verify: `flutter test` pass
- [ ] Verify: App chạy đúng, data migration hoạt động
- [ ] Commit: "feat: migrate database to Drift (type-safe SQLite)"
```

### 4.2. Week 6: Cover Art Cache Optimization

#### 4.2.1. LRU Cache Implementation

```dart
// lib/core/cache/lru_cache.dart
import 'dart:collection';

class LRUCache<K, V> {
  final int maxSize;
  final LinkedHashMap<K, V> _cache = LinkedHashMap();
  
  LRUCache({required this.maxSize});
  
  V? get(K key) {
    if (_cache.containsKey(key)) {
      // Move to end (most recently used)
      final value = _cache.remove(key)!;
      _cache[key] = value;
      return value;
    }
    return null;
  }
  
  void put(K key, V value) {
    if (_cache.containsKey(key)) {
      _cache.remove(key);
    } else if (_cache.length >= maxSize) {
      // Remove least recently used (first item)
      _cache.remove(_cache.keys.first);
    }
    _cache[key] = value;
  }
  
  void remove(K key) {
    _cache.remove(key);
  }
  
  void clear() {
    _cache.clear();
  }
  
  int get length => _cache.length;
  
  bool get isEmpty => _cache.isEmpty;
  
  bool get isNotEmpty => _cache.isNotEmpty;
  
  Iterable<K> get keys => _cache.keys;
  
  Iterable<V> get values => _cache.values;
}
```

#### 4.2.2. Cover Art Repository Enhancement

```dart
// lib/core/cover_art_repository.dart (enhanced)
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'cache/lru_cache.dart';
import 'database/app_database.dart';
import '../utils/image_compressor.dart';

class CoverArtRepository {
  final AppDatabase _db;
  final LRUCache<String, Uint8List> _memoryCache;
  final ImageCompressor _compressor;
  
  // Configuration
  static const int maxMemoryItems = 100;
  static const int maxDiskSizeMB = 500;
  static const int maxDiskEntries = 1000;
  static const int compressionQuality = 80;
  static const int maxImageWidth = 300;
  static const int maxImageHeight = 300;
  
  CoverArtRepository(this._db)
      : _memoryCache = LRUCache(maxSize: maxMemoryItems),
        _compressor = ImageCompressor();
  
  Future<Uint8List?> getCoverArt(String songId, String sourcePath) async {
    // 1. Check memory cache
    final cached = _memoryCache.get(songId);
    if (cached != null) {
      return cached;
    }
    
    // 2. Check disk cache (database)
    final diskBytes = await _db.getCoverArt(songId);
    if (diskBytes != null) {
      _memoryCache.put(songId, diskBytes);
      return diskBytes;
    }
    
    // 3. Extract from source
    final sourceBytes = await _extractFromSource(sourcePath);
    if (sourceBytes != null) {
      // Compress before caching
      final compressed = await _compressor.compress(
        sourceBytes,
        quality: compressionQuality,
        maxWidth: maxImageWidth,
        maxHeight: maxImageHeight,
      );
      
      // Save to disk cache
      await _db.saveCoverArt(songId, compressed);
      
      // Add to memory cache
      _memoryCache.put(songId, compressed);
      
      // Evict old entries if needed
      await _db.evictOldCoverArt(maxDiskEntries);
      
      return compressed;
    }
    
    return null;
  }
  
  Future<Uint8List?> _extractFromSource(String sourcePath) async {
    try {
      // Use audiotags or other library to extract cover art
      // Implementation depends on the specific library
      return null;
    } catch (e) {
      debugPrint('Failed to extract cover art: $e');
      return null;
    }
  }
  
  void removeFromMemoryCache(String songId) {
    _memoryCache.remove(songId);
  }
  
  void clearMemoryCache() {
    _memoryCache.clear();
  }
  
  Future<void> clearDiskCache() async {
    // Implementation to clear database cache
    _memoryCache.clear();
  }
  
  Future<int> getCacheSize() async {
    // Implementation to calculate total cache size
    return 0;
  }
  
  void dispose() {
    _memoryCache.clear();
  }
}
```

#### 4.2.3. Image Compressor

```dart
// lib/core/utils/image_compressor.dart
import 'dart:typed_data';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class ImageCompressor {
  Future<Uint8List> compress(
    Uint8List imageBytes, {
    int quality = 80,
    int maxWidth = 300,
    int maxHeight = 300,
  }) async {
    final result = await FlutterImageCompress.compressWithList(
      imageBytes,
      quality: quality,
      minWidth: maxWidth,
      minHeight: maxHeight,
      format: CompressFormat.jpeg,
    );
    return result;
  }
}
```

### 4.3. Week 7: Performance Optimization

#### 4.3.1. Lazy Loading Implementation

```dart
// lib/core/utils/lazy_list.dart
import 'dart:async';

class LazyList<T> {
  final Future<List<T>> Function(int offset, int limit) _loader;
  final int pageSize;
  
  final List<T> _items = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _currentPage = 0;
  
  LazyList({
    required Future<List<T>> Function(int offset, int limit) loader,
    this.pageSize = 50,
  }) : _loader = loader;
  
  List<T> get items => List.unmodifiable(_items);
  bool get isLoading => _isLoading;
  bool get hasMore => _hasMore;
  int get length => _items.length;
  
  T operator [](int index) => _items[index];
  
  Future<void> loadMore() async {
    if (_isLoading || !_hasMore) return;
    
    _isLoading = true;
    
    try {
      final newItems = await _loader(_currentPage * pageSize, pageSize);
      
      if (newItems.isEmpty) {
        _hasMore = false;
      } else {
        _items.addAll(newItems);
        _currentPage++;
        
        if (newItems.length < pageSize) {
          _hasMore = false;
        }
      }
    } finally {
      _isLoading = false;
    }
  }
  
  Future<void> refresh() async {
    _items.clear();
    _currentPage = 0;
    _hasMore = true;
    await loadMore();
  }
  
  void clear() {
    _items.clear();
    _currentPage = 0;
    _hasMore = true;
  }
}
```

#### 4.3.2. Song List Provider with Lazy Loading

```dart
// lib/providers/song_list_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/utils/lazy_list.dart';
import '../core/services/database_service.dart';
import '../models/song.dart';

class SongListNotifier extends Notifier<LazyList<Song>> {
  @override
  LazyList<Song> build() {
    final db = ref.read(databaseServiceProvider);
    
    return LazyList<Song>(
      loader: (offset, limit) => db.getSongsPaginated(offset, limit),
      pageSize: 50,
    );
  }
  
  Future<void> loadMore() => state.loadMore();
  
  Future<void> refresh() => state.refresh();
  
  Future<void> search(String query) async {
    final db = ref.read(databaseServiceProvider);
    final results = await db.searchSongs(query);
    state = LazyList<Song>(
      loader: (_, __) => Future.value(results),
      pageSize: results.length,
    )..loadMore();
  }
}

final songListProvider = NotifierProvider<SongListNotifier, LazyList<Song>>(
  SongListNotifier.new,
);
```

#### 4.3.3. Database Query Optimization

```dart
// lib/core/database/app_database.dart (additional methods)

// Paginated query
Future<List<Song>> getSongsPaginated(int offset, int limit) =>
    (select(songs)
      ..orderBy([(t) => OrderingTerm.asc(t.name)])
      ..limit(limit, offset: offset)).get();

// Optimized search with index
Future<List<Song>> searchSongsOptimized(String query) async {
  final lowercaseQuery = query.toLowerCase();
  return (select(songs)
    ..where((t) => 
      t.name.lower().like('%$lowercaseQuery%') |
      t.artist.lower().like('%$lowercaseQuery%')
    )
    ..limit(100)).get();
}

// Bulk operations
Future<void> insertSongs(List<SongsCompanion> songList) async {
  await batch((batch) {
    batch.insertAll(songs, songList);
  });
}

Future<void> updateSongs(List<SongsCompanion> songList) async {
  await batch((batch) {
    for (final song in songList) {
      batch.replace(songs, song);
    }
  });
}
```

#### 4.3.4. Performance Monitoring

```dart
// lib/core/services/performance_service.dart
import 'package:flutter/foundation.dart';

class PerformanceService {
  static final PerformanceService _instance = PerformanceService._();
  static PerformanceService get instance => _instance;
  
  PerformanceService._();
  
  final Map<String, Stopwatch> _timers = {};
  final Map<String, List<Duration>> _metrics = {};
  
  void startTimer(String name) {
    _timers[name] = Stopwatch()..start();
  }
  
  Duration stopTimer(String name) {
    final timer = _timers.remove(name);
    if (timer == null) {
      throw StateError('Timer $name not found');
    }
    
    timer.stop();
    _metrics.putIfAbsent(name, () => []).add(timer.elapsed);
    
    if (kDebugMode) {
      debugPrint('Performance: $name took ${timer.elapsedMilliseconds}ms');
    }
    
    return timer.elapsed;
  }
  
  Duration? getAverageTime(String name) {
    final times = _metrics[name];
    if (times == null || times.isEmpty) return null;
    
    final totalMs = times.fold<int>(
      0,
      (sum, duration) => sum + duration.inMicroseconds,
    );
    
    return Duration(microseconds: totalMs ~/ times.length);
  }
  
  Map<String, Duration> getAllAverages() {
    return Map.fromEntries(
      _metrics.keys.map(
        (name) => MapEntry(name, getAverageTime(name)!),
      ),
    );
  }
  
  void clear() {
    _timers.clear();
    _metrics.clear();
  }
}
```

#### 4.3.5. Phase 2 Checklist

```markdown
### Week 4-5: Drift Migration
- [ ] Setup Drift dependencies
- [ ] Create database tables
- [ ] Create AppDatabase class
- [ ] Run build_runner
- [ ] Migrate DatabaseService
- [ ] Migrate seed data
- [ ] Test migration on all platforms
- [ ] Verify data integrity
- [ ] Commit

### Week 6: Cover Art Cache
- [ ] Implement LRUCache
- [ ] Enhance CoverArtRepository
- [ ] Add ImageCompressor
- [ ] Configure cache limits
- [ ] Test cache eviction
- [ ] Verify memory usage
- [ ] Commit

### Week 7: Performance
- [ ] Implement LazyList
- [ ] Create SongListProvider
- [ ] Add paginated queries
- [ ] Implement PerformanceService
- [ ] Add database indexes
- [ ] Run performance benchmarks
- [ ] Verify 60fps scrolling
- [ ] Commit
```

---

## 5. PHASE 3: UI/UX MODERNIZATION

**Thời gian:** 4 tuần (Tuần 8-11)  
**Ưu tiên:** 🟡 TRUNG BÌNH  
**Dependencies:** Phase 2 hoàn thành  

### 5.1. Week 8-9: Material 3 Migration

#### 5.1.1. Theme Setup

```dart
// lib/core/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'package:dynamic_color/dynamic_color.dart';

class AppTheme {
  static const Color defaultSeedColor = Color(0xFF1DB954);
  
  static ThemeData lightTheme({
    Color? seedColor,
    ColorScheme? dynamicColorScheme,
  }) {
    final colorScheme = dynamicColorScheme ??
        ColorScheme.fromSeed(
          seedColor: seedColor ?? defaultSeedColor,
          brightness: Brightness.light,
        );
    
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      brightness: Brightness.light,
      
      // Typography
      textTheme: _buildTextTheme(colorScheme),
      
      // Components
      appBarTheme: _buildAppBarTheme(colorScheme),
      navigationBarTheme: _buildNavigationBarTheme(colorScheme),
      navigationRailTheme: _buildNavigationRailTheme(colorScheme),
      cardTheme: _buildCardTheme(colorScheme),
      dialogTheme: _buildDialogTheme(colorScheme),
      snackBarTheme: _buildSnackBarTheme(colorScheme),
      chipTheme: _buildChipTheme(colorScheme),
      sliderTheme: _buildSliderTheme(colorScheme),
      switchTheme: _buildSwitchTheme(colorScheme),
      checkboxTheme: _buildCheckboxTheme(colorScheme),
      radioTheme: _buildRadioTheme(colorScheme),
      floatingActionButtonTheme: _buildFABTheme(colorScheme),
      elevatedButtonTheme: _buildElevatedButtonTheme(colorScheme),
      outlinedButtonTheme: _buildOutlinedButtonTheme(colorScheme),
      textButtonTheme: _buildTextButtonTheme(colorScheme),
      iconButtonTheme: _buildIconButtonTheme(colorScheme),
      tooltipTheme: _buildTooltipTheme(colorScheme),
      popupMenuTheme: _buildPopupMenuTheme(colorScheme),
      tabBarTheme: _buildTabBarTheme(colorScheme),
      bottomSheetTheme: _buildBottomSheetTheme(colorScheme),
      dividerTheme: _buildDividerTheme(colorScheme),
      listTileTheme: _buildListTileTheme(colorScheme),
      drawerTheme: _buildDrawerTheme(colorScheme),
    );
  }
  
  static ThemeData darkTheme({
    Color? seedColor,
    ColorScheme? dynamicColorScheme,
  }) {
    final colorScheme = dynamicColorScheme?.harmonized() ??
        ColorScheme.fromSeed(
          seedColor: seedColor ?? defaultSeedColor,
          brightness: Brightness.dark,
        );
    
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      brightness: Brightness.dark,
      
      // Typography
      textTheme: _buildTextTheme(colorScheme),
      
      // Components
      appBarTheme: _buildAppBarTheme(colorScheme),
      navigationBarTheme: _buildNavigationBarTheme(colorScheme),
      navigationRailTheme: _buildNavigationRailTheme(colorScheme),
      cardTheme: _buildCardTheme(colorScheme),
      dialogTheme: _buildDialogTheme(colorScheme),
      snackBarTheme: _buildSnackBarTheme(colorScheme),
      chipTheme: _buildChipTheme(colorScheme),
      sliderTheme: _buildSliderTheme(colorScheme),
      switchTheme: _buildSwitchTheme(colorScheme),
      checkboxTheme: _buildCheckboxTheme(colorScheme),
      radioTheme: _buildRadioTheme(colorScheme),
      floatingActionButtonTheme: _buildFABTheme(colorScheme),
      elevatedButtonTheme: _buildElevatedButtonTheme(colorScheme),
      outlinedButtonTheme: _buildOutlinedButtonTheme(colorScheme),
      textButtonTheme: _buildTextButtonTheme(colorScheme),
      iconButtonTheme: _buildIconButtonTheme(colorScheme),
      tooltipTheme: _buildTooltipTheme(colorScheme),
      popupMenuTheme: _buildPopupMenuTheme(colorScheme),
      tabBarTheme: _buildTabBarTheme(colorScheme),
      bottomSheetTheme: _buildBottomSheetTheme(colorScheme),
      dividerTheme: _buildDividerTheme(colorScheme),
      listTileTheme: _buildListTileTheme(colorScheme),
      drawerTheme: _buildDrawerTheme(colorScheme),
      
      // Dark theme specific
      scaffoldBackgroundColor: colorScheme.surface,
    );
  }
  
  static TextTheme _buildTextTheme(ColorScheme colorScheme) {
    return const TextTheme(
      displayLarge: TextStyle(fontSize: 57, fontWeight: FontWeight.w400),
      displayMedium: TextStyle(fontSize: 45, fontWeight: FontWeight.w400),
      displaySmall: TextStyle(fontSize: 36, fontWeight: FontWeight.w400),
      headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w400),
      headlineMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w400),
      headlineSmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w400),
      titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w500),
      titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
      bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
      bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
      labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      labelSmall: TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
    );
  }
  
  static AppBarTheme _buildAppBarTheme(ColorScheme colorScheme) {
    return AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 3,
      backgroundColor: colorScheme.surface,
      foregroundColor: colorScheme.onSurface,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w500,
        color: colorScheme.onSurface,
      ),
    );
  }
  
  static NavigationBarThemeData _buildNavigationBarTheme(ColorScheme colorScheme) {
    return NavigationBarThemeData(
      elevation: 0,
      backgroundColor: colorScheme.surface,
      indicatorColor: colorScheme.primaryContainer,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          );
        }
        return TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: colorScheme.onSurfaceVariant,
        );
      }),
    );
  }
  
  // ... all other theme builders
}
```

#### 5.1.2. Dynamic Color Support

```dart
// lib/ui/app.dart
import 'package:dynamic_color/dynamic_color.dart';
import '../core/theme/app_theme.dart';

class GASongApp extends ConsumerStatefulWidget {
  @override
  ConsumerState<GASongApp> createState() => _GASongAppState();
}

class _GASongAppState extends ConsumerState<GASongApp> {
  ColorScheme? _lightDynamicColorScheme;
  ColorScheme? _darkDynamicColorScheme;
  
  @override
  void initState() {
    super.initState();
    _loadDynamicColors();
  }
  
  Future<void> _loadDynamicColors() async {
    final corePalette = await DynamicColorPlugin.getCorePalette();
    if (corePalette != null) {
      setState(() {
        _lightDynamicColorScheme = corePalette.toColorScheme();
        _darkDynamicColorScheme = corePalette.toColorScheme(brightness: Brightness.dark);
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final seedColor = settings.customPrimaryColor;
    
    return MaterialApp(
      title: 'G.A - Song',
      debugShowCheckedModeBanner: false,
      themeMode: settings.themeMode,
      theme: AppTheme.lightTheme(
        seedColor: seedColor,
        dynamicColorScheme: _lightDynamicColorScheme,
      ),
      darkTheme: AppTheme.darkTheme(
        seedColor: seedColor,
        dynamicColorScheme: _darkDynamicColorScheme,
      ),
      home: const HomeScreen(),
    );
  }
}
```

#### 5.1.3. Component Migration Examples

**Before (Material 2):**
```dart
Card(
  elevation: 2,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(8),
  ),
  child: ListTile(
    leading: Icon(Icons.music_note),
    title: Text('Song Name'),
    subtitle: Text('Artist'),
  ),
)
```

**After (Material 3):**
```dart
Card(
  child: ListTile(
    leading: Icon(Icons.music_note),
    title: Text('Song Name'),
    subtitle: Text('Artist'),
  ),
)
```

### 5.2. Week 10: Responsive Design

#### 5.2.1. Breakpoints Definition

```dart
// lib/core/responsive/breakpoints.dart
class Breakpoints {
  static const double mobile = 600;
  static const double tablet = 900;
  static const double desktop = 1200;
  static const double largeDesktop = 1600;
  
  static bool isMobile(double width) => width < mobile;
  static bool isTablet(double width) => width >= mobile && width < desktop;
  static bool isDesktop(double width) => width >= desktop;
  static bool isLargeDesktop(double width) => width >= largeDesktop;
}
```

#### 5.2.2. Responsive Layout Widget

```dart
// lib/ui/widgets/responsive_layout.dart
import 'package:flutter/material.dart';
import '../../core/responsive/breakpoints.dart';

class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget desktop;
  
  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    required this.desktop,
  });
  
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (Breakpoints.isMobile(constraints.maxWidth)) {
          return mobile;
        } else if (Breakpoints.isTablet(constraints.maxWidth)) {
          return tablet ?? mobile;
        } else {
          return desktop;
        }
      },
    );
  }
}
```

#### 5.2.3. Responsive Grid

```dart
// lib/ui/widgets/responsive_grid.dart
class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final double spacing;
  final double runSpacing;
  
  const ResponsiveGrid({
    super.key,
    required this.children,
    this.spacing = 16,
    this.runSpacing = 16,
  });
  
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = _getCrossAxisCount(constraints.maxWidth);
        
        return GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: spacing,
            mainAxisSpacing: runSpacing,
            childAspectRatio: 1,
          ),
          itemCount: children.length,
          itemBuilder: (context, index) => children[index],
        );
      },
    );
  }
  
  int _getCrossAxisCount(double width) {
    if (Breakpoints.isMobile(width)) return 2;
    if (Breakpoints.isTablet(width)) return 3;
    if (Breakpoints.isDesktop(width)) return 4;
    return 5; // large desktop
  }
}
```

### 5.3. Week 11: Accessibility

#### 5.3.1. Semantic Labels

```dart
// lib/ui/widgets/accessible_widgets.dart

class AccessiblePlayButton extends StatelessWidget {
  final bool isPlaying;
  final VoidCallback onPressed;
  
  const AccessiblePlayButton({
    super.key,
    required this.isPlaying,
    required this.onPressed,
  });
  
  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: isPlaying ? 'Pause' : 'Play',
      hint: isPlaying 
          ? 'Tap to pause current song' 
          : 'Tap to play current song',
      button: true,
      enabled: true,
      child: IconButton(
        icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
        onPressed: onPressed,
        tooltip: isPlaying ? 'Pause' : 'Play',
      ),
    );
  }
}

class AccessibleSongTile extends StatelessWidget {
  final String title;
  final String artist;
  final String duration;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onFavoriteToggle;
  
  const AccessibleSongTile({
    super.key,
    required this.title,
    required this.artist,
    required this.duration,
    required this.isFavorite,
    required this.onTap,
    required this.onFavoriteToggle,
  });
  
  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$title by $artist, duration $duration',
      hint: 'Tap to play, double tap to toggle favorite',
      button: true,
      child: ListTile(
        title: Text(title),
        subtitle: Text(artist),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(duration),
            Semantics(
              label: isFavorite ? 'Remove from favorites' : 'Add to favorites',
              button: true,
              child: IconButton(
                icon: Icon(
                  isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: isFavorite ? Colors.red : null,
                ),
                onPressed: onFavoriteToggle,
              ),
            ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}
```

#### 5.3.2. Keyboard Navigation

```dart
// lib/ui/widgets/keyboard_navigation.dart
class KeyboardNavigation extends StatelessWidget {
  final Widget child;
  
  const KeyboardNavigation({super.key, required this.child});
  
  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: {
        LogicalKeySet(LogicalKeyboardKey.space): const PlayPauseIntent(),
        LogicalKeySet(LogicalKeyboardKey.arrowRight): const NextSongIntent(),
        LogicalKeySet(LogicalKeyboardKey.arrowLeft): const PreviousSongIntent(),
        LogicalKeySet(LogicalKeyboardKey.arrowUp): const VolumeUpIntent(),
        LogicalKeySet(LogicalKeyboardKey.arrowDown): const VolumeDownIntent(),
        LogicalKeySet(LogicalKeyboardKey.keyM): const MuteIntent(),
        LogicalKeySet(LogicalKeyboardKey.keyF): const ToggleFavoriteIntent(),
        LogicalKeySet(LogicalKeyboardKey.escape): const DismissIntent(),
      },
      child: Actions(
        actions: {
          PlayPauseIntent: CallbackAction<PlayPauseIntent>(
            onInvoke: (_) => _togglePlayPause(context),
          ),
          NextSongIntent: CallbackAction<NextSongIntent>(
            onInvoke: (_) => _playNext(context),
          ),
          // ... all other actions
        },
        child: Focus(
          autofocus: true,
          child: child,
        ),
      ),
    );
  }
}

class PlayPauseIntent extends Intent {
  const PlayPauseIntent();
}

class NextSongIntent extends Intent {
  const NextSongIntent();
}

// ... all other intents
```

#### 5.3.3. Accessibility Checklist

```markdown
- [ ] Semantics cho tất cả interactive widgets
- [ ] Tooltips cho icon buttons
- [ ] Keyboard navigation support
- [ ] Focus indicators visible
- [ ] Color contrast ratio >= 4.5:1
- [ ] Text scaling support
- [ ] Screen reader testing
- [ ] Accessibility audit with AccessibilityChecker
```

### 5.4. Phase 3 Checklist

```markdown
### Week 8-9: Material 3
- [ ] Update dependencies (dynamic_color)
- [ ] Create AppTheme class
- [ ] Migrate MaterialApp
- [ ] Migrate AppBar
- [ ] Migrate NavigationBar/Rail
- [ ] Migrate Cards
- [ ] Migrate Buttons
- [ ] Migrate Dialogs
- [ ] Migrate all other components
- [ ] Test on all platforms
- [ ] Commit

### Week 10: Responsive Design
- [ ] Create Breakpoints class
- [ ] Create ResponsiveLayout widget
- [ ] Create ResponsiveGrid widget
- [ ] Migrate HomeScreen
- [ ] Migrate LibraryScreen
- [ ] Migrate PlayerBar
- [ ] Migrate Sidebar
- [ ] Test on different screen sizes
- [ ] Commit

### Week 11: Accessibility
- [ ] Add Semantics to all widgets
- [ ] Add Tooltips
- [ ] Implement keyboard navigation
- [ ] Test with screen readers
- [ ] Run accessibility audit
- [ ] Fix issues
- [ ] Commit
```

---

## 6. PHASE 4: PLATFORM ENHANCEMENT

**Thời gian:** 4 tuần (Tuần 12-15)  
**Ưu tiên:** 🟡 TRUNG BÌNH  
**Dependencies:** Phase 3 hoàn thành  

### 6.1. Week 12-13: macOS Enhancement

#### 6.1.1. macOS Menu Bar

```dart
// lib/ui/platforms/macos/macos_menu_bar.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MacOSMenuBar extends StatelessWidget {
  final Widget child;
  
  const MacOSMenuBar({super.key, required this.child});
  
  @override
  Widget build(BuildContext context) {
    if (!Platform.isMacOS) return child;
    
    return PlatformMenuBar(
      menus: [
        // App Menu
        PlatformMenu(
          label: 'G.A - Song',
          menus: [
            PlatformMenuItemGroup(
              items: [
                PlatformMenuItem(
                  label: 'About G.A - Song',
                  onSelected: () => _showAboutDialog(context),
                ),
              ],
            ),
            PlatformMenuItemGroup(
              items: [
                PlatformMenuItem(
                  label: 'Preferences...',
                  shortcut: const SingleActivator(
                    LogicalKeyboardKey.comma,
                    meta: true,
                  ),
                  onSelected: () => _openSettings(context),
                ),
              ],
            ),
            PlatformMenuItemGroup(
              items: [
                PlatformMenuItem(
                  label: 'Quit G.A - Song',
                  shortcut: const SingleActivator(
                    LogicalKeyboardKey.keyQ,
                    meta: true,
                  ),
                  onSelected: () => SystemNavigator.pop(),
                ),
              ],
            ),
          ],
        ),
        
        // File Menu
        PlatformMenu(
          label: 'File',
          menus: [
            PlatformMenuItemGroup(
              items: [
                PlatformMenuItem(
                  label: 'Import Songs...',
                  shortcut: const SingleActivator(
                    LogicalKeyboardKey.keyO,
                    meta: true,
                  ),
                  onSelected: () => _importSongs(context),
                ),
              ],
            ),
            PlatformMenuItemGroup(
              items: [
                PlatformMenuItem(
                  label: 'Close Window',
                  shortcut: const SingleActivator(
                    LogicalKeyboardKey.keyW,
                    meta: true,
                  ),
                  onSelected: () => WindowController.instance.close(),
                ),
              ],
            ),
          ],
        ),
        
        // Playback Menu
        PlatformMenu(
          label: 'Playback',
          menus: [
            PlatformMenuItemGroup(
              items: [
                PlatformMenuItem(
                  label: 'Play/Pause',
                  shortcut: const SingleActivator(LogicalKeyboardKey.space),
                  onSelected: () => _togglePlayback(context),
                ),
                PlatformMenuItem(
                  label: 'Next',
                  shortcut: const SingleActivator(
                    LogicalKeyboardKey.arrowRight,
                    meta: true,
                  ),
                  onSelected: () => _playNext(context),
                ),
                PlatformMenuItem(
                  label: 'Previous',
                  shortcut: const SingleActivator(
                    LogicalKeyboardKey.arrowLeft,
                    meta: true,
                  ),
                  onSelected: () => _playPrevious(context),
                ),
              ],
            ),
            PlatformMenuItemGroup(
              items: [
                PlatformMenuItem(
                  label: 'Volume Up',
                  shortcut: const SingleActivator(
                    LogicalKeyboardKey.arrowUp,
                    meta: true,
                  ),
                  onSelected: () => _volumeUp(context),
                ),
                PlatformMenuItem(
                  label: 'Volume Down',
                  shortcut: const SingleActivator(
                    LogicalKeyboardKey.arrowDown,
                    meta: true,
                  ),
                  onSelected: () => _volumeDown(context),
                ),
                PlatformMenuItem(
                  label: 'Mute',
                  shortcut: const SingleActivator(
                    LogicalKeyboardKey.keyM,
                    meta: true,
                  ),
                  onSelected: () => _toggleMute(context),
                ),
              ],
            ),
          ],
        ),
        
        // View Menu
        PlatformMenu(
          label: 'View',
          menus: [
            PlatformMenuItemGroup(
              items: [
                PlatformMenuItem(
                  label: 'Mini Player',
                  shortcut: const SingleActivator(
                    LogicalKeyboardKey.keyM,
                    meta: true,
                    shift: true,
                  ),
                  onSelected: () => _toggleMiniPlayer(context),
                ),
                PlatformMenuItem(
                  label: 'Full Screen',
                  shortcut: const SingleActivator(
                    LogicalKeyboardKey.keyF,
                    meta: true,
                    control: true,
                  ),
                  onSelected: () => _toggleFullScreen(context),
                ),
              ],
            ),
            PlatformMenuItemGroup(
              items: [
                PlatformMenuItem(
                  label: 'Show Lyrics',
                  shortcut: const SingleActivator(
                    LogicalKeyboardKey.keyL,
                    meta: true,
                  ),
                  onSelected: () => _toggleLyrics(context),
                ),
              ],
            ),
          ],
        ),
        
        // Window Menu
        PlatformMenu(
          label: 'Window',
          menus: [
            PlatformMenuItemGroup(
              items: [
                PlatformMenuItem(
                  label: 'Minimize',
                  shortcut: const SingleActivator(
                    LogicalKeyboardKey.keyM,
                    meta: true,
                  ),
                  onSelected: () => WindowController.instance.minimize(),
                ),
                PlatformMenuItem(
                  label: 'Zoom',
                  onSelected: () => WindowController.instance.maximize(),
                ),
              ],
            ),
            PlatformMenuItemGroup(
              items: [
                PlatformMenuItem(
                  label: 'Bring All to Front',
                  onSelected: () {},
                ),
              ],
            ),
          ],
        ),
      ],
      child: child,
    );
  }
  
  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'G.A - Song',
      applicationVersion: '1.0.0',
      applicationIcon: Image.asset('assets/pic/app_logo.png', width: 64, height: 64),
    );
  }
  
  // ... all other helper methods
}
```

#### 6.1.2. macOS Touch Bar

```dart
// lib/ui/platforms/macos/touch_bar.dart
import 'dart:io';
import 'package:flutter/services.dart';

class TouchBarController {
  static const MethodChannel _channel = MethodChannel('gasong/touch_bar');
  
  static Future<void> updateNowPlaying({
    required String title,
    required String artist,
    required bool isPlaying,
  }) async {
    if (!Platform.isMacOS) return;
    
    await _channel.invokeMethod('updateNowPlaying', {
      'title': title,
      'artist': artist,
      'isPlaying': isPlaying,
    });
  }
  
  static Future<void> updateProgress(Duration position, Duration duration) async {
    if (!Platform.isMacOS) return;
    
    await _channel.invokeMethod('updateProgress', {
      'position': position.inSeconds,
      'duration': duration.inSeconds,
    });
  }
}
```

#### 6.1.3. macOS Native Integration

```dart
// lib/core/platforms/macos/macos_integration.dart
import 'dart:io';
import 'package:flutter/services.dart';

class MacOSIntegration {
  static const MethodChannel _channel = MethodChannel('gasong/macos');
  
  static Future<void> setup() async {
    if (!Platform.isMacOS) return;
    
    // Setup method call handler
    _channel.setMethodCallHandler(_handleMethodCall);
    
    // Configure window
    await _configureWindow();
  }
  
  static Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onWindowFocusChanged':
        // Handle window focus changes
        break;
      case 'onSystemThemeChanged':
        // Handle system theme changes
        break;
      case 'onPowerStateChanged':
        // Handle power state changes (sleep/wake)
        break;
    }
  }
  
  static Future<void> _configureWindow() async {
    await _channel.invokeMethod('configureWindow', {
      'titleBarStyle': 'hidden',
      'fullSizeContentView': true,
      'transparent': true,
    });
  }
  
  static Future<void> setPlaybackState({
    required bool isPlaying,
    required String title,
    required String artist,
    required Duration position,
    required Duration duration,
  }) async {
    await _channel.invokeMethod('setPlaybackState', {
      'isPlaying': isPlaying,
      'title': title,
      'artist': artist,
      'position': position.inMilliseconds,
      'duration': duration.inMilliseconds,
    });
  }
}
```

### 6.2. Week 14: iOS Enhancement

#### 6.2.1. iOS Widgets

```dart
// lib/core/platforms/ios/ios_widgets.dart
import 'dart:io';
import 'package:home_widget/home_widget.dart';

class IOSWidgets {
  static Future<void> updateNowPlaying({
    required String songName,
    required String artist,
    required String? coverArtBase64,
    required bool isPlaying,
  }) async {
    if (!Platform.isIOS) return;
    
    await HomeWidget.saveWidgetData<String>('songName', songName);
    await HomeWidget.saveWidgetData<String>('artist', artist);
    await HomeWidget.saveWidgetData<bool>('isPlaying', isPlaying);
    
    if (coverArtBase64 != null) {
      await HomeWidget.saveWidgetData<String>('coverArt', coverArtBase64);
    }
    
    await HomeWidget.updateWidget(
      iOSName: 'NowPlayingWidget',
      androidName: 'NowPlayingWidgetReceiver',
    );
  }
  
  static Future<void> updateRecentlyPlayed(List<Map<String, String>> songs) async {
    if (!Platform.isIOS) return;
    
    await HomeWidget.saveWidgetData<String>(
      'recentlyPlayed',
      jsonEncode(songs),
    );
    
    await HomeWidget.updateWidget(
      iOSName: 'RecentlyPlayedWidget',
      androidName: 'RecentlyPlayedWidgetReceiver',
    );
  }
}
```

#### 6.2.2. Siri Integration

```dart
// lib/core/platforms/ios/siri_integration.dart
import 'dart:io';
import 'package:flutter/services.dart';

class SiriIntegration {
  static const MethodChannel _channel = MethodChannel('gasong/siri');
  
  static Future<void> donatePlaySongIntent({
    required String songName,
    required String artist,
  }) async {
    if (!Platform.isIOS) return;
    
    await _channel.invokeMethod('donatePlaySongIntent', {
      'songName': songName,
      'artist': artist,
    });
  }
  
  static Future<void> donatePlayPlaylistIntent({
    required String playlistName,
  }) async {
    if (!Platform.isIOS) return;
    
    await _channel.invokeMethod('donatePlayPlaylistIntent', {
      'playlistName': playlistName,
    });
  }
  
  static Future<void> setupSiriShortcuts() async {
    if (!Platform.isIOS) return;
    
    await _channel.invokeMethod('setupShortcuts', {
      'shortcuts': [
        {
          'identifier': 'playFavorite',
          'phrase': 'Play my favorites',
          'title': 'Play Favorites',
          'subtitle': 'Play your favorite songs',
        },
        {
          'identifier': 'playRecent',
          'phrase': 'Play recent songs',
          'title': 'Play Recently Played',
          'subtitle': 'Play recently played songs',
        },
      ],
    });
  }
}
```

#### 6.2.3. AirPlay Support

```dart
// lib/core/platforms/ios/airplay.dart
import 'dart:io';
import 'package:flutter/services.dart';

class AirPlayService {
  static const MethodChannel _channel = MethodChannel('gasong/airplay');
  
  static Future<void> enableAirPlay() async {
    if (!Platform.isIOS) return;
    
    await _channel.invokeMethod('enableAirPlay');
  }
  
  static Future<void> disableAirPlay() async {
    if (!Platform.isIOS) return;
    
    await _channel.invokeMethod('disableAirPlay');
  }
  
  static Stream<bool> get onAirPlayAvailableChanged {
    if (!Platform.isIOS) return Stream.value(false);
    
    return _channel
        .receiveBroadcastStream()
        .where((event) => event is Map && event['type'] == 'airplayAvailability')
        .map((event) => event['available'] as bool);
  }
}
```

### 6.3. Week 15: Web Enhancement

#### 6.3.1. PWA Configuration

```yaml
# web/manifest.json
{
  "name": "G.A - Song",
  "short_name": "GA Song",
  "description": "A full-featured music player",
  "start_url": "/",
  "display": "standalone",
  "background_color": "#121212",
  "theme_color": "#1DB954",
  "orientation": "any",
  "icons": [
    {
      "src": "icons/Icon-192.png",
      "sizes": "192x192",
      "type": "image/png"
    },
    {
      "src": "icons/Icon-512.png",
      "sizes": "512x512",
      "type": "image/png"
    },
    {
      "src": "icons/Icon-maskable-192.png",
      "sizes": "192x192",
      "type": "image/png",
      "purpose": "maskable"
    },
    {
      "src": "icons/Icon-maskable-512.png",
      "sizes": "512x512",
      "type": "image/png",
      "purpose": "maskable"
    }
  ]
}
```

#### 6.3.2. Web Audio Player

```dart
// lib/core/audio/web_audio_player_impl.dart
import 'dart:html' as html;
import 'dart:js_util' as js_util;
import 'dart:typed_data';
import 'package:flutter/foundation.dart';

class WebAudioPlayerImpl {
  html.AudioElement? _audioElement;
  AudioContext? _audioContext;
  
  Future<void> initialize() async {
    _audioElement = html.AudioElement();
    _audioElement!.preload = 'auto';
    
    // Setup audio context for advanced features
    _audioContext = AudioContext();
  }
  
  Future<void> play(String url) async {
    _audioElement!.src = url;
    await _audioElement!.play();
  }
  
  Future<void> pause() async {
    _audioElement!.pause();
  }
  
  Future<void> stop() async {
    _audioElement!.pause();
    _audioElement!.currentTime = 0;
  }
  
  Future<void> seek(Duration position) async {
    _audioElement!.currentTime = position.inSeconds.toDouble();
  }
  
  Future<void> setVolume(double volume) async {
    _audioElement!.volume = volume.clamp(0.0, 1.0);
  }
  
  Stream<Duration> get onPositionChanged {
    return _audioElement!.onTimeUpdate.map((_) {
      return Duration(
        milliseconds: (_audioElement!.currentTime * 1000).round(),
      );
    });
  }
  
  Stream<bool> get onPlayStateChanged {
    return _audioElement!.onPlay.map((_) => true);
  }
  
  Stream<void> get onEnded {
    return _audioElement!.onEnded;
  }
  
  Future<Duration?> get duration async {
    final d = _audioElement!.duration;
    if (d.isNaN || d.isInfinite) return null;
    return Duration(milliseconds: (d * 1000).round());
  }
  
  void dispose() {
    _audioElement?.remove();
    _audioContext?.close();
  }
}

// AudioContext polyfill
@JS('AudioContext')
class AudioContext {
  external AudioContext();
  external Future<AudioBuffer> decodeAudioData(ByteBuffer data);
  external void close();
}
```

#### 6.3.3. Service Worker

```javascript
// web/service-worker.js
const CACHE_NAME = 'ga-song-v1';
const urlsToCache = [
  '/',
  '/index.html',
  '/main.dart.js',
  '/flutter.js',
  '/assets/',
  '/icons/',
];

self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME)
      .then((cache) => cache.addAll(urlsToCache))
  );
});

self.addEventListener('fetch', (event) => {
  event.respondWith(
    caches.match(event.request)
      .then((response) => {
        if (response) {
          return response;
        }
        return fetch(event.request);
      })
  );
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys().then((cacheNames) => {
      return Promise.all(
        cacheNames.map((cacheName) => {
          if (cacheName !== CACHE_NAME) {
            return caches.delete(cacheName);
          }
        })
      );
    })
  );
});
```

### 6.4. Phase 4 Checklist

```markdown
### Week 12-13: macOS
- [ ] Implement macOS menu bar
- [ ] Add Touch Bar support
- [ ] Setup macOS native integration
- [ ] Test on macOS
- [ ] Commit

### Week 14: iOS
- [ ] Implement iOS widgets
- [ ] Add Siri integration
- [ ] Add AirPlay support
- [ ] Test on iOS
- [ ] Commit

### Week 15: Web
- [ ] Configure PWA
- [ ] Implement WebAudioPlayer
- [ ] Add Service Worker
- [ ] Test on web
- [ ] Commit
```

---

## 7. PHASE 5: TESTING & QUALITY ASSURANCE

**Thời gian:** 3 tuần (Tuần 16-18)  
**Ưu tiên:** 🟢 THẤP  
**Dependencies:** Phase 4 hoàn thành  

### 7.1. Week 16: Unit Tests

#### 7.1.1. Test Coverage Target

| Module | Current | Target |
|--------|---------|--------|
| core/ | ~70% | 90% |
| models/ | ~80% | 95% |
| providers/ | ~60% | 85% |
| ui/ | ~50% | 75% |
| **Total** | ~65% | **85%** |

#### 7.1.2. Test Structure

```
test/
├── unit/
│   ├── core/
│   │   ├── audio/
│   │   │   ├── audio_engine_service_test.dart
│   │   │   ├── audio_effect_service_test.dart
│   │   │   ├── playlist_service_test.dart
│   │   │   └── lyric_parser_test.dart
│   │   ├── cache/
│   │   │   └── lru_cache_test.dart
│   │   ├── database/
│   │   │   └── app_database_test.dart
│   │   ├── services/
│   │   │   ├── database_service_test.dart
│   │   │   └── error_handler_service_test.dart
│   │   └── utils/
│   │       ├── result_test.dart
│   │       ├── sort_utils_test.dart
│   │       └── time_utils_test.dart
│   ├── models/
│   │   ├── song_test.dart
│   │   └── playlist_test.dart
│   └── providers/
│       ├── settings_notifier_test.dart
│       └── song_list_provider_test.dart
├── widget/
│   ├── screens/
│   │   ├── home_screen_test.dart
│   │   ├── mini_player_screen_test.dart
│   │   └── ktv_screen_test.dart
│   ├── widgets/
│   │   ├── sidebar_test.dart
│   │   ├── bottom_player_bar_test.dart
│   │   ├── song_tiles_test.dart
│   │   └── equalizer_widget_test.dart
│   └── responsive/
│       ├── responsive_layout_test.dart
│       └── responsive_grid_test.dart
├── integration/
│   ├── app_test.dart
│   ├── playback_test.dart
│   ├── playlist_test.dart
│   └── settings_test.dart
├── golden/
│   ├── home_screen_golden_test.dart
│   ├── player_bar_golden_test.dart
│   └── sidebar_golden_test.dart
├── performance/
│   ├── startup_test.dart
│   └── scrolling_test.dart
└── helpers/
    ├── test_helpers.dart
    ├── mock_database.dart
    ├── mock_audio_engine.dart
    └── mock_audio_effect.dart
```

#### 7.1.3. Example Unit Tests

```dart
// test/unit/core/cache/lru_cache_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:ga_song/core/cache/lru_cache.dart';

void main() {
  group('LRUCache', () {
    late LRUCache<String, int> cache;
    
    setUp(() {
      cache = LRUCache(maxSize: 3);
    });
    
    test('get returns null for non-existent key', () {
      expect(cache.get('key'), isNull);
    });
    
    test('put and get works correctly', () {
      cache.put('key', 1);
      expect(cache.get('key'), equals(1));
    });
    
    test('evicts least recently used when full', () {
      cache.put('a', 1);
      cache.put('b', 2);
      cache.put('c', 3);
      cache.put('d', 4); // should evict 'a'
      
      expect(cache.get('a'), isNull);
      expect(cache.get('b'), equals(2));
      expect(cache.get('c'), equals(3));
      expect(cache.get('d'), equals(4));
    });
    
    test('get moves item to end', () {
      cache.put('a', 1);
      cache.put('b', 2);
      cache.put('c', 3);
      
      cache.get('a'); // move 'a' to end
      cache.put('d', 4); // should evict 'b'
      
      expect(cache.get('a'), equals(1));
      expect(cache.get('b'), isNull);
      expect(cache.get('c'), equals(3));
      expect(cache.get('d'), equals(4));
    });
    
    test('remove works correctly', () {
      cache.put('key', 1);
      cache.remove('key');
      expect(cache.get('key'), isNull);
    });
    
    test('clear removes all items', () {
      cache.put('a', 1);
      cache.put('b', 2);
      cache.clear();
      
      expect(cache.get('a'), isNull);
      expect(cache.get('b'), isNull);
      expect(cache.length, equals(0));
    });
  });
}
```

```dart
// test/unit/core/utils/result_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:ga_song/core/utils/result.dart';

void main() {
  group('Result', () {
    test('Success contains data', () {
      final result = Success(42);
      
      expect(result.isSuccess, isTrue);
      expect(result.isFailure, isFalse);
      expect(result.data, equals(42));
      expect(result.error, isNull);
    });
    
    test('Failure contains error', () {
      final result = Failure<int>('Something went wrong');
      
      expect(result.isSuccess, isFalse);
      expect(result.isFailure, isTrue);
      expect(result.data, isNull);
      expect(result.error, equals('Something went wrong'));
    });
    
    test('can pattern match on Result', () {
      Result<int> success = Success(42);
      Result<int> failure = Failure('error');
      
      String message = switch (success) {
        Success(data: final d) => 'Got $d',
        Failure(message: final m) => 'Error: $m',
      };
      
      expect(message, equals('Got 42'));
    });
  });
}
```

### 7.2. Week 17: Widget & Integration Tests

#### 7.2.1. Widget Test Example

```dart
// test/widget/screens/home_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';
import 'package:ga_song/ui/screens/home_screen.dart';
import 'package:ga_song/providers/service_providers.dart';

import '../../helpers/mock_database.dart';
import '../../helpers/mock_audio_engine.dart';

void main() {
  group('HomeScreen', () {
    late MockDatabaseService mockDb;
    late MockAudioEngineService mockEngine;
    
    setUp(() {
      mockDb = MockDatabaseService();
      mockEngine = MockAudioEngineService();
      
      when(mockDb.watchAllSongs()).thenAnswer(
        (_) => Stream.value([]),
      );
    });
    
    testWidgets('renders without error', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseServiceProvider.overrideWithValue(mockDb),
            audioEngineServiceProvider.overrideWithValue(mockEngine),
          ],
          child: const MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );
      
      expect(find.byType(HomeScreen), findsOneWidget);
    });
    
    testWidgets('shows sidebar with navigation items', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseServiceProvider.overrideWithValue(mockDb),
            audioEngineServiceProvider.overrideWithValue(mockEngine),
          ],
          child: const MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );
      
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Library'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
    });
    
    testWidgets('navigates to library tab', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseServiceProvider.overrideWithValue(mockDb),
            audioEngineServiceProvider.overrideWithValue(mockEngine),
          ],
          child: const MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );
      
      await tester.tap(find.text('Library'));
      await tester.pumpAndSettle();
      
      // Verify library content is shown
      expect(find.byIcon(Icons.library_music), findsOneWidget);
    });
  });
}
```

#### 7.2.2. Integration Test Example

```dart
// test/integration/app_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:ga_song/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  
  group('App Integration Test', () {
    testWidgets('full playback flow', (tester) async {
      app.main();
      await tester.pumpAndSettle();
      
      // Navigate to library
      await tester.tap(find.byIcon(Icons.library_music));
      await tester.pumpAndSettle();
      
      // Select first song
      await tester.tap(find.byType(ListTile).first);
      await tester.pumpAndSettle();
      
      // Verify playback started
      expect(find.byIcon(Icons.pause), findsOneWidget);
      
      // Test next button
      await tester.tap(find.byIcon(Icons.skip_next));
      await tester.pumpAndSettle();
      
      // Test previous button
      await tester.tap(find.byIcon(Icons.skip_previous));
      await tester.pumpAndSettle();
      
      // Test pause
      await tester.tap(find.byIcon(Icons.pause));
      await tester.pumpAndSettle();
      
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
    });
    
    testWidgets('settings flow', (tester) async {
      app.main();
      await tester.pumpAndSettle();
      
      // Navigate to settings
      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();
      
      // Toggle dark mode
      await tester.tap(find.text('Dark Mode'));
      await tester.pumpAndSettle();
      
      // Change theme color
      await tester.tap(find.text('Theme Color'));
      await tester.pumpAndSettle();
      
      // Select a color
      await tester.tap(find.byType(ColorPicker).first);
      await tester.pumpAndSettle();
      
      // Apply
      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();
    });
  });
}
```

### 7.3. Week 18: Golden & Performance Tests

#### 7.3.1. Golden Test Example

```dart
// test/golden/home_screen_golden_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ga_song/ui/screens/home_screen.dart';

void main() {
  group('HomeScreen Golden Tests', () {
    testWidgets('light theme', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: ThemeData.light(),
            home: const HomeScreen(),
          ),
        ),
      );
      
      await expectLater(
        find.byType(HomeScreen),
        matchesGoldenFile('goldens/home_screen_light.png'),
      );
    });
    
    testWidgets('dark theme', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: ThemeData.dark(),
            home: const HomeScreen(),
          ),
        ),
      );
      
      await expectLater(
        find.byType(HomeScreen),
        matchesGoldenFile('goldens/home_screen_dark.png'),
      );
    });
    
    testWidgets('mobile layout', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: const HomeScreen(),
          ),
        ),
      );
      
      await expectLater(
        find.byType(HomeScreen),
        matchesGoldenFile('goldens/home_screen_mobile.png'),
      );
      
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  });
}
```

#### 7.3.2. Performance Test Example

```dart
// test/performance/startup_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:ga_song/main.dart' as app;

void main() {
  group('Performance Tests', () {
    test('app startup time < 2 seconds', () async {
      final stopwatch = Stopwatch()..start();
      
      app.main();
      
      stopwatch.stop();
      
      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(2000),
        reason: 'App startup took ${stopwatch.elapsedMilliseconds}ms',
      );
    });
    
    test('song list scrolling is smooth', () async {
      // This test would use Flutter's performance overlay
      // to detect jank during scrolling
      
      final binding = TestWidgetsFlutterBinding.ensureInitialized();
      
      // Add performance overlay
      // ...
      
      // Scroll through list
      // ...
      
      // Verify no jank detected
    });
  });
}
```

### 7.4. Phase 5 Checklist

```markdown
### Week 16: Unit Tests
- [ ] Setup test structure
- [ ] Write LRU cache tests
- [ ] Write Result type tests
- [ ] Write database tests
- [ ] Write provider tests
- [ ] Verify coverage > 85%
- [ ] Commit

### Week 17: Widget & Integration Tests
- [ ] Write widget tests for all screens
- [ ] Write widget tests for all widgets
- [ ] Write integration tests
- [ ] Run integration tests on all platforms
- [ ] Commit

### Week 18: Golden & Performance Tests
- [ ] Create golden tests
- [ ] Generate golden files
- [ ] Write performance tests
- [ ] Run performance benchmarks
- [ ] Commit
```

---

## 8. PHASE 6: DEPENDENCIES & RELEASE

**Thời gian:** 2 tuần (Tuần 19-20)  
**Ưu tiên:** 🟢 THẤP  
**Dependencies:** Phase 5 hoàn thành  

### 8.1. Week 19: Dependencies Update

#### 8.1.1. Dependencies Matrix

| Package | Current | Target | Breaking Changes | Migration Notes |
|---------|---------|--------|------------------|-----------------|
| flutter_riverpod | ^3.0.0 | ^4.0.0 | Minor | Update provider syntax |
| flutter_soloud | ^4.0.5 | ^5.0.0 | Major | New API for audio effects |
| sqflite | ^2.4.2 | Removed | - | Replaced by Drift |
| drift | N/A | ^2.14.0 | - | New dependency |
| dynamic_color | N/A | ^1.7.0 | - | New dependency |
| http | ^1.2.0 | ^2.0.0 | Minor | Update http client usage |
| flutter_acrylic | ^1.1.4 | ^2.0.0 | Minor | Update blur API |
| build_runner | ^2.4.13 | ^2.5.0 | None | |
| freezed | ^2.5.8 | ^3.0.0 | Minor | Update annotations |
| json_serializable | ^6.8.0 | ^6.9.0 | None | |

#### 8.1.2. Migration Scripts

```bash
#!/bin/bash
# scripts/migrate_dependencies.sh

echo "Step 1: Update pubspec.yaml"
# Manual edit required

echo "Step 2: Run flutter pub upgrade"
flutter pub upgrade --major-versions

echo "Step 3: Run build_runner"
dart run build_runner build --delete-conflicting-outputs

echo "Step 4: Run dart fix"
dart fix --apply

echo "Step 5: Run flutter analyze"
flutter analyze

echo "Step 6: Run flutter test"
flutter test

echo "Migration complete!"
```

#### 8.1.3. Dependency Update Checklist

```markdown
- [ ] Review changelog for each package
- [ ] Update pubspec.yaml
- [ ] Run flutter pub get
- [ ] Run build_runner
- [ ] Run dart fix
- [ ] Fix any breaking changes manually
- [ ] Run flutter analyze
- [ ] Run flutter test
- [ ] Test on all platforms
- [ ] Commit
```

### 8.2. Week 20: Release Preparation

#### 8.2.1. Version Bumping

```yaml
# pubspec.yaml
version: 2.0.0+2
```

#### 8.2.2. Changelog

```markdown
# CHANGELOG.md

## 2.0.0 (2026-XX-XX)

### Breaking Changes
- Migrated database from raw SQLite to Drift
- Migrated state management from ValueNotifier to Riverpod Notifier
- Updated to Material 3 design system

### New Features
- Material 3 with Dynamic Color support
- Responsive design for all screen sizes
- Full keyboard navigation
- macOS menu bar and Touch Bar
- iOS widgets and Siri integration
- PWA support for web
- Lazy loading for song list
- LRU cache for cover art
- Comprehensive accessibility support

### Improvements
- 85%+ test coverage
- 60fps scrolling performance
- < 2 second app startup
- Type-safe database queries
- Better error handling

### Bug Fixes
- Fixed cover art cache memory leak
- Fixed playlist ordering issue
- Fixed EQ initialization race condition

### Dependencies
- Updated Riverpod to 4.0
- Updated flutter_soloud to 5.0
- Added Drift for database
- Added dynamic_color for Material 3
- Removed sqflite (replaced by Drift)

## 1.0.0 (2026-XX-XX)

### Initial Release
- Full-featured music player
- 5-band equalizer
- Crossfade playback
- KTV/karaoke mode
- YouTube integration (Android)
- Desktop floating lyrics
- Multi-platform support
```

#### 8.2.3. Release Notes

```markdown
# Release Notes - G.A Song 2.0.0

## 🎉 What's New

### Material 3 Design
- Complete redesign with Material 3
- Dynamic Color support on Android 12+
- Modern, clean UI

### Better Performance
- 60fps scrolling with 1000+ songs
- < 2 second app startup
- Optimized cover art caching

### Platform Enhancements
- **macOS:** Menu bar, Touch Bar, native integration
- **iOS:** Home widgets, Siri shortcuts, AirPlay
- **Web:** PWA support, offline mode

### Accessibility
- Full keyboard navigation
- Screen reader support
- High contrast support

## 🐛 Bug Fixes
- Fixed various stability issues
- Improved memory management

## 📦 Dependencies
- Updated to latest Flutter and Dart
- Migrated to Drift database

## 🙏 Thank You
Thank you for using G.A Song! Please report any issues on GitHub.
```

#### 8.2.4. Build Scripts

```bash
#!/bin/bash
# scripts/build_all.sh

echo "Building G.A Song 2.0.0..."

# Clean
flutter clean

# Get dependencies
flutter pub get

# Run code generation
dart run build_runner build --delete-conflicting-outputs

# Run analysis
flutter analyze

# Run tests
flutter test

# Build Android APK
echo "Building Android APK..."
flutter build apk --release

# Build Android App Bundle
echo "Building Android App Bundle..."
flutter build appbundle --release

# Build Windows
echo "Building Windows..."
flutter build windows --release

# Build Linux
echo "Building Linux..."
flutter build linux --release

# Build macOS
echo "Building macOS..."
flutter build macos --release

# Build Web
echo "Building Web..."
flutter build web --release

echo "Build complete!"
```

#### 8.2.5. Release Checklist

```markdown
- [ ] Update version in pubspec.yaml
- [ ] Update CHANGELOG.md
- [ ] Update README.md
- [ ] Run all tests
- [ ] Build for all platforms
- [ ] Test builds on each platform
- [ ] Create Git tag
- [ ] Create GitHub release
- [ ] Upload artifacts
- [ ] Publish announcement
```

---

## 9. CI/CD PIPELINE

### 9.1. GitHub Actions Workflow

```yaml
# .github/workflows/ci.yml
name: CI

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.22.0'
          channel: 'stable'
      
      - name: Install dependencies
        run: flutter pub get
      
      - name: Run code generation
        run: dart run build_runner build --delete-conflicting-outputs
      
      - name: Analyze
        run: flutter analyze
      
      - name: Run tests
        run: flutter test --coverage
      
      - name: Upload coverage
        uses: codecov/codecov-action@v3
        with:
          file: coverage/lcov.info
  
  build-android:
    needs: test
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - uses: actions/setup-java@v4
        with:
          distribution: 'zulu'
          java-version: '17'
      
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.22.0'
      
      - name: Install dependencies
        run: flutter pub get
      
      - name: Build APK
        run: flutter build apk --release
      
      - name: Upload APK
        uses: actions/upload-artifact@v4
        with:
          name: android-apk
          path: build/app/outputs/flutter-apk/app-release.apk
  
  build-windows:
    needs: test
    runs-on: windows-latest
    steps:
      - uses: actions/checkout@v4
      
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.22.0'
      
      - name: Install dependencies
        run: flutter pub get
      
      - name: Build Windows
        run: flutter build windows --release
      
      - name: Upload Windows
        uses: actions/upload-artifact@v4
        with:
          name: windows-exe
          path: build/windows/x64/runner/Release/
  
  build-linux:
    needs: test
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.22.0'
      
      - name: Install dependencies
        run: flutter pub get
      
      - name: Build Linux
        run: flutter build linux --release
      
      - name: Upload Linux
        uses: actions/upload-artifact@v4
        with:
          name: linux-app
          path: build/linux/x64/release/bundle/
  
  build-macos:
    needs: test
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v4
      
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.22.0'
      
      - name: Install dependencies
        run: flutter pub get
      
      - name: Build macOS
        run: flutter build macos --release
      
      - name: Upload macOS
        uses: actions/upload-artifact@v4
        with:
          name: macos-app
          path: build/macos/Build/Products/Release/
  
  build-web:
    needs: test
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.22.0'
      
      - name: Install dependencies
        run: flutter pub get
      
      - name: Build Web
        run: flutter build web --release
      
      - name: Upload Web
        uses: actions/upload-artifact@v4
        with:
          name: web-app
          path: build/web/
```

### 9.2. Release Workflow

```yaml
# .github/workflows/release.yml
name: Release

on:
  push:
    tags:
      - 'v*'

jobs:
  release:
    runs-on: ubuntu-latest
    permissions:
      contents: write
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Create Release
        uses: softprops/action-gh-release@v1
        with:
          files: |
            build/app/outputs/flutter-apk/app-release.apk
            build/windows/x64/runner/Release/*
            build/linux/x64/release/bundle/*
            build/web/*
          body: |
            See [CHANGELOG.md](CHANGELOG.md) for details.
```

---

## 10. ROLLBACK STRATEGY

### 10.1. Git Branching Strategy

```
main
├── develop
│   ├── feature/phase-1-cleanup
│   ├── feature/phase-2-database
│   ├── feature/phase-3-ui
│   ├── feature/phase-4-platform
│   ├── feature/phase-5-testing
│   └── feature/phase-6-release
└── hotfix/xxx
```

### 10.2. Rollback Procedures

#### 10.2.1. Code Rollback

```bash
# Rollback to previous commit
git revert HEAD

# Rollback to specific commit
git revert <commit-hash>

# Rollback branch to main
git checkout main
git branch -D feature/phase-2-database
git checkout -b feature/phase-2-database
```

#### 10.2.2. Database Migration Rollback

```dart
// lib/core/database/app_database.dart

@override
MigrationStrategy get migration => MigrationStrategy(
  onUpgrade: (Migrator m, int from, int to) async {
    // Keep track of migrations for rollback
    if (from < 3) {
      try {
        await _migrateV2ToV3(m);
      } catch (e) {
        // Rollback: recreate table
        await m.database.customStatement('DROP TABLE IF EXISTS new_table');
        rethrow;
      }
    }
  },
  beforeOpen: (details) async {
    // Verify database integrity
    await _verifyDatabaseIntegrity();
  },
);

Future<void> _verifyDatabaseIntegrity() async {
  final result = await customSelect('PRAGMA integrity_check').getSingle();
  if (result.data['integrity_check'] != 'ok') {
    throw DatabaseException('Database integrity check failed');
  }
}
```

#### 10.2.3. Feature Flag Rollback

```dart
// lib/core/feature_flags.dart
class FeatureFlags {
  static final FeatureFlags _instance = FeatureFlags._();
  static FeatureFlags get instance => _instance;
  
  FeatureFlags._();
  
  final Map<String, bool> _flags = {
    'material3': true,
    'responsive_design': true,
    'drift_database': true,
    'lazy_loading': true,
    'ios_widgets': false, // Not ready yet
    'pwa_support': false, // Not ready yet
  };
  
  bool isEnabled(String flag) => _flags[flag] ?? false;
  
  void enable(String flag) => _flags[flag] = true;
  
  void disable(String flag) => _flags[flag] = false;
}

// Usage
if (FeatureFlags.instance.isEnabled('material3')) {
  // Use Material 3
} else {
  // Use Material 2
}
```

### 10.3. Backup Strategy

```bash
# Backup database before migration
cp ~/Documents/ga_song.db ~/Documents/ga_song_backup_$(date +%Y%m%d).db

# Backup settings
cp ~/.shared_preferences/ga_song.json ~/Documents/ga_song_settings_backup.json
```

---

## 11. SUCCESS METRICS & KPIs

### 11.1. Technical Metrics

| Metric | Current | Target | Measurement |
|--------|---------|--------|-------------|
| Test Coverage | ~65% | 85% | `flutter test --coverage` |
| Lint Warnings | ~50 | < 10 | `flutter analyze` |
| App Startup | ~3s | < 2s | Stopwatch |
| Scroll FPS | ~45fps | 60fps | Performance overlay |
| Memory Usage | ~200MB | < 150MB | DevTools |
| Database Query | ~100ms | < 50ms | `PerformanceService` |
| Crash Rate | Unknown | < 0.1% | Crash reporting |

### 11.2. User Experience Metrics

| Metric | Target | Measurement |
|--------|--------|-------------|
| Accessibility Score | > 90% | Accessibility audit |
| Responsive Design | All breakpoints | Manual testing |
| Platform Parity | 90%+ features | Feature checklist |
| UI Consistency | 100% Material 3 | Visual audit |

### 11.3. Development Metrics

| Metric | Target | Measurement |
|--------|--------|-------------|
| Build Time | < 5min | CI/CD logs |
| PR Review Time | < 24h | GitHub metrics |
| Bug Fix Time | < 48h | Issue tracking |
| Release Frequency | Bi-weekly | Git tags |

### 11.4. Monitoring Dashboard

```dart
// lib/core/services/monitoring_service.dart
class MonitoringService {
  final Map<String, List<double>> _metrics = {};
  
  void recordMetric(String name, double value) {
    _metrics.putIfAbsent(name, () => []).add(value);
  }
  
  Map<String, double> getAverages() {
    return _metrics.map((key, values) {
      final avg = values.reduce((a, b) => a + b) / values.length;
      return MapEntry(key, avg);
    });
  }
  
  void reportToAnalytics() {
    // Send to analytics service
  }
}
```

---

## 12. RISK ASSESSMENT & MITIGATION

### 12.1. Risk Matrix

| Risk | Probability | Impact | Severity | Mitigation |
|------|-------------|--------|----------|------------|
| Breaking changes in Riverpod 4.0 | Medium | High | 🔴 | Incremental migration, thorough testing |
| Drift migration data loss | Low | Critical | 🔴 | Backup before migration, verify integrity |
| Material 3 UI inconsistency | Medium | Medium | 🟡 | Use Material 3 components consistently |
| Performance regression | Low | High | 🟡 | Profile before/after, set budgets |
| Platform-specific bugs | Medium | Medium | 🟡 | Test on real devices, platform channels |
| Dependency conflicts | Medium | Low | 🟢 | Use dependency_overrides if needed |
| Team knowledge gaps | Low | Medium | 🟢 | Documentation, training |

### 12.2. Contingency Plans

#### 12.2.1. Riverpod Migration Issues

```dart
// If Riverpod 4.0 has breaking changes, fallback to 3.x
dependencies:
  flutter_riverpod: ^3.0.0  # Keep current version
  
// Or use compatibility layer
class RiverpodCompat {
  static Widget providerScope({
    required Widget child,
    List<Override> overrides = const [],
  }) {
    return ProviderScope(
      overrides: overrides,
      child: child,
    );
  }
}
```

#### 12.2.2. Drift Migration Failure

```dart
// Fallback to sqflite if Drift fails
class DatabaseServiceFactory {
  static DatabaseService create() {
    try {
      return DriftDatabaseService();
    } catch (e) {
      debugPrint('Drift failed, falling back to sqflite: $e');
      return SqfliteDatabaseService();
    }
  }
}
```

#### 12.2.3. Performance Regression

```dart
// Performance budget enforcement
class PerformanceBudget {
  static const Duration maxStartupTime = Duration(seconds: 2);
  static const int minScrollFPS = 55;
  static const int maxMemoryMB = 200;
  
  static void enforce() {
    // Check startup time
    if (startupTime > maxStartupTime) {
      debugPrint('WARNING: Startup time exceeded budget');
    }
    
    // Check scroll FPS
    if (scrollFPS < minScrollFPS) {
      debugPrint('WARNING: Scroll FPS below budget');
    }
    
    // Check memory
    if (memoryUsageMB > maxMemoryMB) {
      debugPrint('WARNING: Memory usage exceeded budget');
    }
  }
}
```

---

## 13. RESOURCE REQUIREMENTS

### 13.1. Development Environment

| Resource | Specification |
|----------|---------------|
| Flutter SDK | 3.22.0+ |
| Dart SDK | 3.11.4+ |
| Android Studio | Latest stable |
| Xcode | 15.0+ (for macOS/iOS) |
| Visual Studio | 2022 (for Windows) |
| Git | 2.40+ |
| RAM | 16GB+ |
| Storage | 50GB+ free |

### 13.2. Testing Devices

| Platform | Device | Purpose |
|----------|--------|---------|
| Android | Pixel 7 | Primary testing |
| Android | Samsung Galaxy S23 | UI testing |
| iOS | iPhone 15 | Primary testing |
| iOS | iPad Air | Tablet testing |
| macOS | MacBook Pro | macOS testing |
| Windows | Windows 11 PC | Windows testing |
| Linux | Ubuntu 22.04 | Linux testing |

### 13.3. Third-Party Services

| Service | Purpose | Cost |
|---------|---------|------|
| GitHub | Repository, CI/CD | Free |
| Codecov | Test coverage | Free |
| Firebase Crashlytics | Crash reporting | Free |
| Sentry | Error tracking | Free tier |
| Google Play Console | Android distribution | $25 one-time |
| Apple Developer | iOS distribution | $99/year |

---

## 14. APPENDIX

### 14.1. File Structure After Upgrade

```
lib/
├── main.dart
├── core/
│   ├── audio/
│   │   ├── audio_engine_service.dart
│   │   ├── audio_effect_service.dart
│   │   ├── playlist_service.dart
│   │   ├── lyric_parser.dart
│   │   └── web_audio_player_impl.dart
│   ├── cache/
│   │   └── lru_cache.dart
│   ├── database/
│   │   ├── app_database.dart
│   │   ├── app_database.g.dart
│   │   └── tables/
│   │       ├── songs_table.dart
│   │       ├── playlists_table.dart
│   │       ├── playlist_songs_table.dart
│   │       ├── cover_art_cache_table.dart
│   │       └── lyrics_cache_table.dart
│   ├── exceptions/
│   │   └── app_exception.dart
│   ├── platforms/
│   │   ├── ios/
│   │   │   ├── ios_widgets.dart
│   │   │   ├── siri_integration.dart
│   │   │   └── airplay.dart
│   │   └── macos/
│   │       ├── macos_menu_bar.dart
│   │       ├── touch_bar.dart
│   │       └── macos_integration.dart
│   ├── responsive/
│   │   └── breakpoints.dart
│   ├── services/
│   │   ├── database_service.dart
│   │   ├── error_handler_service.dart
│   │   ├── performance_service.dart
│   │   ├── monitoring_service.dart
│   │   └── ... (other services)
│   ├── settings/
│   │   ├── settings_state.dart
│   │   ├── settings_state.freezed.dart
│   │   └── settings_notifier.dart
│   ├── theme/
│   │   └── app_theme.dart
│   ├── utils/
│   │   ├── result.dart
│   │   ├── lazy_list.dart
│   │   ├── image_compressor.dart
│   │   └── ... (other utils)
│   └── view_models/
│       └── player_view_model.dart
├── feature_flags.dart
├── models/
│   ├── song.dart
│   ├── song.g.dart
│   ├── playlist.dart
│   └── playlist.g.dart
├── providers/
│   ├── service_providers.dart
│   ├── song_list_provider.dart
│   └── ... (other providers)
├── l10n/
│   ├── app_en.arb
│   ├── app_vi.arb
│   └── app_localizations.dart
└── ui/
    ├── app.dart
    ├── screens/
    │   ├── home_screen.dart
    │   ├── mini_player_screen.dart
    │   ├── ktv_screen.dart
    │   └── ... (other screens)
    ├── widgets/
    │   ├── responsive_layout.dart
    │   ├── responsive_grid.dart
    │   ├── accessible_widgets.dart
    │   ├── keyboard_navigation.dart
    │   └── ... (other widgets)
    ├── painters/
    │   └── visualizer_painters.dart
    └── visualizer/
        └── visualizer_controller.dart
```

### 14.2. Commands Reference

```bash
# Development
flutter run                          # Run in debug mode
flutter run --release                # Run in release mode
flutter run -d chrome                # Run on Chrome
flutter run -d windows               # Run on Windows
flutter run -d macos                 # Run on macOS

# Testing
flutter test                         # Run all tests
flutter test --coverage              # Run with coverage
flutter test test/unit/              # Run unit tests only
flutter test test/widget/            # Run widget tests only
flutter test test/integration/       # Run integration tests
flutter test --update-goldens        # Update golden files

# Code Generation
dart run build_runner build          # Generate code
dart run build_runner watch          # Watch mode
dart run build_runner build --delete-conflicting-outputs  # Clean build

# Analysis
flutter analyze                      # Run analysis
dart fix --apply                     # Auto-fix issues
dart format .                        # Format code

# Build
flutter build apk                    # Build Android APK
flutter build appbundle              # Build Android App Bundle
flutter build ios                    # Build iOS
flutter build macos                  # Build macOS
flutter build windows                # Build Windows
flutter build linux                  # Build Linux
flutter build web                    # Build Web

# Database
dart run drift_dev schema dump lib/core/database/app_database.dart  # Dump schema
dart run drift_dev schema generate   # Generate schema

# Cleanup
flutter clean                        # Clean build artifacts
dart pub cache clean                 # Clean pub cache
```

### 14.3. Useful Links

| Resource | URL |
|----------|-----|
| Flutter Documentation | https://docs.flutter.dev |
| Riverpod Documentation | https://riverpod.dev |
| Drift Documentation | https://drift.simonbinder.eu |
| Material 3 Guidelines | https://m3.material.io |
| Flutter Performance | https://docs.flutter.dev/perf |
| GitHub Actions | https://docs.github.com/en/actions |

---

## ✅ PLAN COMPLETION CHECKLIST

- [x] Project overview and current state analysis
- [x] Goals and KPIs defined
- [x] Phase 1: Code Cleanup & Foundation (detailed)
- [x] Phase 2: Database & Performance (detailed)
- [x] Phase 3: UI/UX Modernization (detailed)
- [x] Phase 4: Platform Enhancement (detailed)
- [x] Phase 5: Testing & Quality Assurance (detailed)
- [x] Phase 6: Dependencies & Release (detailed)
- [x] CI/CD Pipeline configuration
- [x] Rollback strategy
- [x] Success metrics and KPIs
- [x] Risk assessment and mitigation
- [x] Resource requirements
- [x] Appendix with file structure, commands, and links

---

**Plan Status:** ✅ 100% COMPLETE  
**Ready for Implementation:** YES  
**Last Updated:** 26/06/2026  
**Version:** 2.0
