# Hướng Dẫn Migration: ValueNotifier → Riverpod SettingsNotifier

## Tổng Quan

Thay vì sử dụng 40+ `ValueNotifier` trong `SettingsManager`, giờ đây bạn có thể sử dụng `SettingsNotifier` với Riverpod để quản lý settings một cách clean hơn.

## Cách Sử Dụng Mới (Riverpod)

### 1. Đọc giá trị trong widget

```dart
// Trước (ValueNotifier + ValueListenableBuilder):
final settings = ref.read(settingsManagerProvider);
return ValueListenableBuilder(
  valueListenable: settings.themeModeNotifier,
  builder: (context, themeMode, _) {
    return Text('Theme: $themeMode');
  },
);

// Sau (Riverpod ref.watch):
final themeMode = ref.watch(settingsNotifierProvider.select((s) => s.themeMode));
return Text('Theme: $themeMode');

// Hoặc đọc nhiều giá trị:
final settings = ref.watch(settingsNotifierProvider);
return Column(
  children: [
    Text('Theme: ${settings.themeMode}'),
    Text('Blur: ${settings.enableBlur}'),
    Text('EQ Preset: ${settings.eqPreset}'),
  ],
);
```

### 2. Cập nhật giá trị

```dart
// Trước:
final settings = ref.read(settingsManagerProvider);
await settings.setThemeMode(ThemeMode.dark);

// Sau:
final notifier = ref.read(settingsNotifierProvider.notifier);
await notifier.setThemeMode(ThemeMode.dark);
```

### 3. Sử dụng trong ConsumerWidget

```dart
class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch để rebuild khi settings thay đổi
    final settings = ref.watch(settingsNotifierProvider);
    
    return Switch(
      value: settings.enableBlur,
      onChanged: (value) {
        // Read notifier để gọi method
        ref.read(settingsNotifierProvider.notifier).setEnableBlur(value);
      },
    );
  }
}
```

### 4. Sử dụng select để tối ưu performance

```dart
// Chỉ rebuild khi blurLevel thay đổi
final blurLevel = ref.watch(
  settingsNotifierProvider.select((s) => s.blurLevel),
);

// Chỉ rebuild khi themeMode thay đổi
final themeMode = ref.watch(
  settingsNotifierProvider.select((s) => s.themeMode),
);
```

## Migration Checklist

Khi migrate một widget từ ValueNotifier sang SettingsNotifier:

- [ ] Thay `ValueListenableBuilder` bằng `ref.watch`
- [ ] Thay `settings.xxxNotifier.value` bằng `settings.xxx`
- [ ] Thay `settings.setXxx(value)` bằng `ref.read(settingsNotifierProvider.notifier).setXxx(value)`
- [ ] Sử dụng `select()` nếu chỉ cần một vài giá trị
- [ ] Verify: Widget vẫn hoạt động đúng
- [ ] Verify: Tests vẫn pass

## Ví Đụ Migration Thực Tế

### Trước:
```dart
class ThemeToggle extends ConsumerStatefulWidget {
  @override
  ConsumerState<ThemeToggle> createState() => _ThemeToggleState();
}

class _ThemeToggleState extends ConsumerState<ThemeToggle> {
  @override
  Widget build(BuildContext context) {
    final settings = ref.read(settingsManagerProvider);
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: settings.themeModeNotifier,
      builder: (context, themeMode, _) {
        return Switch(
          value: themeMode == ThemeMode.dark,
          onChanged: (isDark) {
            settings.setThemeMode(isDark ? ThemeMode.dark : ThemeMode.light);
          },
        );
      },
    );
  }
}
```

### Sau:
```dart
class ThemeToggle extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(
      settingsNotifierProvider.select((s) => s.themeMode),
    );
    return Switch(
      value: themeMode == ThemeMode.dark,
      onChanged: (isDark) {
        ref.read(settingsNotifierProvider.notifier)
            .setThemeMode(isDark ? ThemeMode.dark : ThemeMode.light);
      },
    );
  }
}
```

## Lưu Ý Quan Trọng

1. **Backward Compatibility**: `SettingsManager` vẫn hoạt động bình thường. Bạn có thể migrate từng widget một.

2. **Performance**: Sử dụng `select()` để chỉ rebuild khi cần thiết.

3. **Testing**: `SettingsNotifier` dễ test hơn vì nó là pure state.

4. **Incremental Migration**: Không cần migrate tất cả cùng lúc. Migrate dần dần theo nhu cầu.
