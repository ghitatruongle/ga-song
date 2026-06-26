# 🚀 Kế Hoạch Nâng Cấp Dự Án G.A - Song

**Ngày tạo:** 26/06/2026  
**Phiên bản hiện tại:** 1.0.0+1  
**Dart SDK:** ^3.11.4  
**Trạng thái tests:** ✅ 360/360 tests passed

---

## 📊 Tổng Quan Tình Trạng Hiện Tại

### ✅ Điểm mạnh
- Kiến trúc rõ ràng: MVVM-like với Riverpod
- Test coverage tốt: 360 tests, tất cả đều pass
- Hỗ trợ đa nền tảng: Android, Windows, Linux, macOS, iOS, Web
- Features phong phú: EQ, crossfade, normalization, lyrics, KTV mode
- Code organization tốt với separation of concerns

### ⚠️ Vấn đề cần cải thiện
1. **Dead code:** `service_locator.dart` không còn sử dụng
2. **State management inconsistency:** Mix giữa ValueNotifier và Riverpod
3. **Material Design:** Chưa migrate sang Material 3
4. **Database:** Sử dụng raw SQLite, không type-safe
5. **Dependencies:** Một số packages có thể outdated
6. **Platform support:** macOS/iOS/Web chưa đầy đủ features

---

## 🎯 Kế Hoạch Nâng Cấp (Ưu tiên theo Phase)

### **PHASE 1: Code Cleanup & Foundation (1-2 tuần)**

#### 1.1. Xóa Dead Code
```dart
// Xóa file: lib/core/service_locator.dart
// Xóa các import không sử dụng trong toàn bộ dự án
```

#### 1.2. Chuẩn hóa State Management
**Hiện tại:** Mix giữa ValueNotifier (40+ notifiers trong SettingsManager) và Riverpod providers

**Đề xuất:** Migrate sang Riverpod Notifier/AsyncNotifier

```dart
// Trước (ValueNotifier):
class SettingsManager {
  final ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier(ThemeMode.system);
  // ... 40+ notifiers
}

// Sau (Riverpod Notifier):
@riverpod
class ThemeMode extends _$ThemeMode {
  @override
  ThemeMode build() => ThemeMode.system;
  
  void setThemeMode(ThemeMode mode) {
    state = mode;
    _persistToSharedPreferences('themeMode', mode.name);
  }
}
```

**Lợi ích:**
- Loại bỏ boilerplate code
- Tích hợp tốt hơn với Riverpod ecosystem
- Dễ test hơn
- Type-safe hơn

#### 1.3. Cải thiện Error Handling
```dart
// Thêm Result type cho các operations
sealed class Result<T> {
  const Result();
}

final class Success<T> extends Result<T> {
  final T data;
  const Success(this.data);
}

final class Failure<T> extends Result<T> {
  final String message;
  final StackTrace? stackTrace;
  const Failure(this.message, [this.stackTrace]);
}
```

---

### **PHASE 2: Database & Performance (2-3 tuần)**

#### 2.1. Migrate sang Drift (Type-safe SQLite)
**Hiện tại:** Raw SQL queries trong `DatabaseService`

**Đề xuất:** Sử dụng Drift (trước đây là moor)

```dart
// Trước:
await db.execute('''
  CREATE TABLE songs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    artist TEXT,
    ...
  )
''');

// Sau (Drift):
@DataClassName('Song')
class Songs extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 255)();
  TextColumn get artist => text().nullable()();
  // ... type-safe columns
}

@DriftDatabase(tables: [Songs, Playlists, PlaylistSongs])
class AppDatabase extends _$AppDatabase {
  @override
  int get schemaVersion => 3;
  
  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async => m.createAll(),
    onUpgrade: (Migrator m, int from, int to) async {
      if (from < 2) {
        await m.addColumn(songs, songs.playCount);
        // ... migrations
      }
    },
  );
}
```

**Lợi ích:**
- Type-safe queries
- Auto-generated code
- Migration support tốt hơn
- Compile-time error checking

#### 2.2. Tối ưu hóa Cover Art Cache
**Hiện tại:** 3-tier cache (memory → disk → source)

**Cải thiện:**
- Implement LRU cache với size limit
- Thêm cache eviction policy
- Nén ảnh trước khi lưu vào DB
- Sử dụng `flutter_image_compress` để giảm kích thước

```dart
class CoverArtCache {
  final int maxMemoryItems = 100;
  final int maxDiskSizeMB = 500;
  
  // LRU cache với automatic eviction
  final LinkedHashMap<String, Uint8List> _memoryCache = LinkedHashMap();
  
  Future<Uint8List?> getCoverArt(String songId) async {
    // 1. Check memory cache
    if (_memoryCache.containsKey(songId)) {
      _memoryCache.moveToEnd(songId);
      return _memoryCache[songId];
    }
    
    // 2. Check disk cache
    final diskBytes = await _loadFromDisk(songId);
    if (diskBytes != null) {
      _addToMemoryCache(songId, diskBytes);
      return diskBytes;
    }
    
    // 3. Extract from source
    final sourceBytes = await _extractFromSource(songId);
    if (sourceBytes != null) {
      final compressed = await _compressImage(sourceBytes);
      await _saveToDisk(songId, compressed);
      _addToMemoryCache(songId, compressed);
      return compressed;
    }
    
    return null;
  }
}
```

#### 2.3. Database Indexing
```dart
// Thêm indexes cho các queries thường dùng
await db.execute('CREATE INDEX idx_songs_artist ON songs(artist)');
await db.execute('CREATE INDEX idx_songs_album ON songs(album)');
await db.execute('CREATE INDEX idx_songs_play_count ON songs(playCount DESC)');
await db.execute('CREATE INDEX idx_songs_date_added ON songs(dateAdded DESC)');
```

---

### **PHASE 3: UI/UX Modernization (3-4 tuần)**

#### 3.1. Migrate sang Material 3
**Hiện tại:** Sử dụng `ThemeData.light()` và `ThemeData.dark()` cơ bản

**Đề xuất:** Material 3 với Dynamic Color

```dart
// Trước:
theme: ThemeData.light().copyWith(
  scaffoldBackgroundColor: useNative ? Colors.transparent : const Color(0xFFF5F5F5),
  primaryColor: primaryColor,
  colorScheme: ColorScheme.light(
    primary: primaryColor,
    secondary: primaryColor,
    surface: const Color(0xFFFFFFFF),
  ),
);

// Sau:
theme: ThemeData(
  useMaterial3: true,
  colorSchemeSeed: primaryColor,
  brightness: Brightness.light,
  scaffoldBackgroundColor: useNative ? Colors.transparent : null,
  // Material 3 sẽ tự động generate color scheme
);

// Sử dụng Dynamic Color (Android 12+)
final dynamicColorScheme = await DynamicColorPlugin.getColorScheme();
theme: ThemeData(
  useMaterial3: true,
  colorScheme: dynamicColorScheme ?? ColorScheme.fromSeed(
    seedColor: primaryColor,
    brightness: Brightness.light,
  ),
);
```

**Lợi ích:**
- Modern UI design
- Better accessibility
- Dynamic color support
- Consistent with platform guidelines

#### 3.2. Responsive Design
**Hiện tại:** Layout cố định, không responsive

**Đề xuất:** Sử dụng LayoutBuilder và Breakpoints

```dart
class ResponsiveLayout extends StatelessWidget {
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;
  static const double desktopBreakpoint = 1200;
  
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < mobileBreakpoint) {
          return _buildMobileLayout();
        } else if (constraints.maxWidth < tabletBreakpoint) {
          return _buildTabletLayout();
        } else {
          return _buildDesktopLayout();
        }
      },
    );
  }
}
```

#### 3.3. Accessibility Improvements
```dart
// Thêm Semantics cho tất cả interactive widgets
Semantics(
  label: 'Play button',
  hint: 'Tap to play current song',
  button: true,
  child: IconButton(
    icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
    onPressed: togglePlayback,
  ),
);

// Thêm support cho screen readers
Tooltip(
  message: 'Next song',
  child: IconButton(
    icon: Icon(Icons.skip_next),
    onPressed: playNext,
  ),
);
```

---

### **PHASE 4: Platform Enhancement (4-5 tuần)**

#### 4.1. macOS Enhancement
**Hiện tại:** Basic Flutter runner, không có macOS-specific features

**Thêm:**
- macOS menu bar integration
- Touch Bar support
- Handoff support
- macOS-specific gestures (trackpad)
- Native macOS notifications

```dart
// macOS menu bar
class MacosMenuBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return PlatformMenuBar(
      menus: [
        PlatformMenu(
          label: 'G.A - Song',
          menus: [
            PlatformMenuItemGroup(
              items: [
                PlatformMenuItem(
                  label: 'About G.A - Song',
                  onSelected: () => showAboutDialog(context: context),
                ),
              ],
            ),
            PlatformMenuItemGroup(
              items: [
                PlatformMenuItem(
                  label: 'Quit',
                  shortcut: const SingleActivator(LogicalKeyboardKey.keyQ, meta: true),
                  onSelected: () => SystemNavigator.pop(),
                ),
              ],
            ),
          ],
        ),
        PlatformMenu(
          label: 'Playback',
          menus: [
            PlatformMenuItem(
              label: 'Play/Pause',
              shortcut: const SingleActivator(LogicalKeyboardKey.space),
              onSelected: () => togglePlayback(),
            ),
            // ... more menu items
          ],
        ),
      ],
    );
  }
}
```

#### 4.2. iOS Enhancement
**Hiện tại:** Basic Flutter runner

**Thêm:**
- iOS widgets (home screen widgets)
- Siri integration
- AirPlay support
- iOS-specific gestures
- Background audio improvements

```dart
// iOS Home Screen Widget (sử dụng home_widget package)
class SongWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return HomeWidget(
      name: 'CurrentSongWidget',
      androidName: 'CurrentSongWidgetReceiver',
      iOSName: 'CurrentSongWidget',
      data: {
        'songName': currentSong.name,
        'artist': currentSong.artist,
        'coverArt': coverArtBase64,
      },
    );
  }
}
```

#### 4.3. Web Enhancement
**Hiện tại:** Web audio player abstraction tồn tại nhưng chưa đầy đủ

**Thêm:**
- Progressive Web App (PWA) support
- Web Audio API integration
- Web-specific optimizations
- Offline support với Service Worker

```dart
// Web Audio Player implementation
class WebAudioPlayerImpl implements WebAudioPlayer {
  late AudioContext _audioContext;
  late AudioBufferSourceNode _sourceNode;
  
  @override
  Future<void> play(String url) async {
    _audioContext = AudioContext();
    final response = await http.get(Uri.parse(url));
    final audioBuffer = await _audioContext.decodeAudioData(response.bodyBytes);
    _sourceNode = _audioContext.createBufferSource();
    _sourceNode.buffer = audioBuffer;
    _sourceNode.connectNode(_audioContext.destination);
    _sourceNode.start();
  }
}
```

---

### **PHASE 5: Testing & Quality (2-3 tuần)**

#### 5.1. Tăng Test Coverage
**Hiện tại:** 360 tests, coverage chưa đo được

**Mục tiêu:** >80% code coverage

```dart
// Thêm tests cho các edge cases
group('Edge Cases', () {
  test('handles empty playlist gracefully', () async {
    when(mockDatabase.getSongs()).thenAnswer((_) => Stream.value([]));
    await tester.pumpWidget(buildApp());
    expect(find.text('No songs'), findsOneWidget);
  });
  
  test('handles network error for online lyrics', () async {
    when(mockHttp.get(any)).thenThrow(SocketException('No internet'));
    final result = await onlineLyricsService.fetchLyrics('test song');
    expect(result, isNull);
  });
});

// Thêm golden tests cho UI consistency
testWidgets('Golden test - Home Screen', (tester) async {
  await tester.pumpWidget(buildApp());
  await expectLater(
    find.byType(HomeScreen),
    matchesGoldenFile('goldens/home_screen.png'),
  );
});
```

#### 5.2. Integration Tests
```dart
// integration_test/full_flow_test.dart
testWidgets('Full playback flow', (tester) async {
  await tester.pumpWidget(MyApp());
  
  // Navigate to library
  await tester.tap(find.byIcon(Icons.library_music));
  await tester.pumpAndSettle();
  
  // Select a song
  await tester.tap(find.text('First Song'));
  await tester.pumpAndSettle();
  
  // Verify playback starts
  expect(find.byIcon(Icons.pause), findsOneWidget);
  
  // Test next/previous
  await tester.tap(find.byIcon(Icons.skip_next));
  await tester.pumpAndSettle();
  
  // Test EQ
  await tester.tap(find.byIcon(Icons.equalizer));
  await tester.pumpAndSettle();
  expect(find.byType(EqualizerWidget), findsOneWidget);
});
```

#### 5.3. Performance Tests
```dart
// test/performance/startup_test.dart
test('App startup time < 2 seconds', () async {
  final stopwatch = Stopwatch()..start();
  await tester.pumpWidget(MyApp());
  stopwatch.stop();
  
  expect(stopwatch.elapsedMilliseconds, lessThan(2000));
});

test('Smooth scrolling with 1000+ songs', () async {
  // Generate 1000 songs
  final songs = List.generate(1000, (i) => Song(id: i, name: 'Song $i'));
  
  await tester.pumpWidget(buildSongList(songs));
  
  // Scroll to bottom
  await tester.scrollUntilVisible(
    find.text('Song 999'),
    500,
    scrollable: find.byType(Scrollable),
  );
  
  // Should be smooth (no jank)
});
```

---

### **PHASE 6: Dependencies Update (1 tuần)**

#### 6.1. Critical Updates
```yaml
dependencies:
  # State management
  flutter_riverpod: ^3.0.0 → ^4.0.0  # Check for breaking changes
  
  # Audio
  flutter_soloud: ^4.0.5 → ^5.0.0  # New features, bug fixes
  
  # Database
  sqflite: ^2.4.2 → ^3.0.0  # OR migrate to drift
  
  # UI
  flutter_acrylic: ^1.1.4 → ^2.0.0  # New blur effects
  
  # Utilities
  http: ^1.2.0 → ^2.0.0  # Better performance
  path_provider: ^2.1.5 → ^2.2.0
  
dev_dependencies:
  # Code generation
  build_runner: ^2.4.13 → ^2.5.0
  freezed: ^2.5.8 → ^3.0.0  # New features
  
  # Testing
  flutter_test: sdk: flutter  # Already latest
  integration_test: sdk: flutter
```

#### 6.2. Deprecated Packages
```yaml
# Replace deprecated packages
# Trước:
audiotags: ^1.4.5

# Sau (nếu audiotags không còn maintain):
flutter_media_metadata: ^1.0.0
# Hoặc:
id3tag: ^2.0.0
```

#### 6.3. New Packages to Add
```yaml
dependencies:
  # For Material 3 dynamic color
  dynamic_color: ^1.7.0
  
  # For better state management
  flutter_hooks: ^0.20.0  # Optional, for hooks pattern
  
  # For iOS widgets
  home_widget: ^0.5.0
  
  # For better image handling
  flutter_image_compress: ^2.1.0
  
  # For animations
  lottie: ^3.0.0
  
  # For better error handling
  sentry_flutter: ^8.0.0  # Optional, for crash reporting
```

---

## 📅 Timeline Tổng Thể

| Phase | Thời gian | Ưu tiên | Mô tả |
|-------|-----------|---------|-------|
| 1 | 1-2 tuần | 🔴 Cao | Code cleanup, state management standardization |
| 2 | 2-3 tuần | 🔴 Cao | Database migration, performance optimization |
| 3 | 3-4 tuần | 🟡 Trung bình | Material 3, responsive design, accessibility |
| 4 | 4-5 tuần | 🟡 Trung bình | Platform-specific enhancements |
| 5 | 2-3 tuần | 🟢 Thấp | Test coverage, integration tests |
| 6 | 1 tuần | 🟢 Thấp | Dependencies update |

**Tổng thời gian ước tính:** 13-18 tuần (3-4.5 tháng)

---

## 🎯 Milestones

### Milestone 1: Foundation (Tuần 2)
- [ ] Xóa dead code
- [ ] Chuẩn hóa state management
- [ ] Cải thiện error handling

### Milestone 2: Performance (Tuần 5)
- [ ] Migrate database sang Drift
- [ ] Tối ưu cover art cache
- [ ] Thêm database indexing

### Milestone 3: Modern UI (Tuần 9)
- [ ] Material 3 migration
- [ ] Responsive design
- [ ] Accessibility improvements

### Milestone 4: Platform Excellence (Tuần 14)
- [ ] macOS enhancements
- [ ] iOS enhancements
- [ ] Web enhancements

### Milestone 5: Quality Assurance (Tuần 17)
- [ ] 80%+ test coverage
- [ ] Integration tests
- [ ] Performance tests

### Milestone 6: Release Ready (Tuần 18)
- [ ] Dependencies updated
- [ ] Documentation updated
- [ ] Release notes prepared

---

## 🚨 Risks & Mitigation

| Risk | Impact | Mitigation |
|------|--------|------------|
| Breaking changes trong Riverpod 4.0 | Cao | Test thoroughly, migrate incrementally |
| Drift migration complexity | Trung bình | Start with new features, migrate old code gradually |
| Material 3 UI inconsistencies | Thung bình | Use Material 3 components consistently |
| Platform-specific bugs | Trung bình | Test on real devices, use platform channels carefully |
| Performance regression | Cao | Profile before/after, set performance budgets |

---

## 📚 Resources

### Documentation
- [Riverpod Documentation](https://riverpod.dev/)
- [Drift Documentation](https://drift.simonbinder.eu/)
- [Material 3 Guidelines](https://m3.material.io/)
- [Flutter Performance Best Practices](https://docs.flutter.dev/perf)

### Tools
- `flutter test --coverage` - Check test coverage
- `flutter analyze` - Static analysis
- `dart fix` - Auto-fix lint issues
- `devtools` - Performance profiling

---

## ✅ Kết Luận

Dự án G.A - Song hiện tại có foundation tốt với kiến trúc rõ ràng và test coverage khá. Việc nâng cấp theo kế hoạch trên sẽ:

1. **Cải thiện code quality:** Loại bỏ dead code, chuẩn hóa patterns
2. **Tăng performance:** Tối ưu database, caching
3. **Modern UI:** Material 3, responsive design
4. **Better platform support:** macOS, iOS, Web enhancements
5. **Higher quality:** Tăng test coverage, integration tests

**Ưu tiên cao nhất:** Phase 1 (Code Cleanup) và Phase 2 (Database) vì chúng ảnh hưởng đến toàn bộ codebase và performance.

---

*Kế hoạch này có thể điều chỉnh dựa trên feedback và ưu tiên mới.*
