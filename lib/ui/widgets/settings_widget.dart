// ignore_for_file: deprecated_member_use
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/service_providers.dart';
import '../../core/theme/tokens.dart';
import '../../l10n/app_localizations.dart';
import 'desktop_title_bar.dart';
import 'sleep_timer_dialog.dart';
import 'audio_effects_dialog.dart';
import 'sort_filter_dialog.dart';
import 'custom_hotkeys_dialog.dart';

class SettingsWidget extends ConsumerWidget {
  const SettingsWidget({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final settings = ref.read(settingsManagerProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;

    return ColoredBox(
      // Solid background — transparent here lets wallpaper/acrylic show through
      // and makes text/icons hard to read on all devices.
      color: isDark ? AppColors.darkBackground : AppColors.lightSurface2,
      child: Column(
        children: <Widget>[
          // Q-3 fix: Use shared DesktopTitleBar widget
          DesktopTitleBar(iconColor: textColor),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(40, 10, 40, 140),
              children: <Widget>[
                Text(
                  'Cài đặt',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 30),
                _buildSectionHeader('Giao diện & Chủ đề', textColor),
                _buildSettingCard(
                  isDark: isDark,
                  child: ValueListenableBuilder<ThemeMode>(
                    valueListenable: settings.themeModeNotifier,
                    builder: (final context, final currentTheme, _) => Column(
                      children: <Widget>[
                        ListTile(
                          title: Text(
                            'Theo hệ thống (System Default)',
                            style: TextStyle(color: textColor),
                          ),
                          leading: Radio<ThemeMode>(
                            value: ThemeMode.system,
                            groupValue: currentTheme,
                            onChanged: (final value) {
                              if (value != null) settings.setThemeMode(value);
                            },
                            activeColor: Theme.of(context).primaryColor,
                          ),
                        ),
                        ListTile(
                          title: Text(
                            'Sáng (Light Mode)',
                            style: TextStyle(color: textColor),
                          ),
                          leading: Radio<ThemeMode>(
                            value: ThemeMode.light,
                            groupValue: currentTheme,
                            onChanged: (final value) {
                              if (value != null) settings.setThemeMode(value);
                            },
                            activeColor: Theme.of(context).primaryColor,
                          ),
                        ),
                        ListTile(
                          title: Text(
                            'Tối (Dark Mode)',
                            style: TextStyle(color: textColor),
                          ),
                          leading: Radio<ThemeMode>(
                            value: ThemeMode.dark,
                            groupValue: currentTheme,
                            onChanged: (final value) {
                              if (value != null) settings.setThemeMode(value);
                            },
                            activeColor: Theme.of(context).primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                _buildSettingCard(
                  isDark: isDark,
                  child: ValueListenableBuilder<Locale>(
                    valueListenable: settings.localeNotifier,
                    builder: (final context, final currentLocale, _) {
                      final l10n = AppLocalizations.of(context)!;
                      return ListTile(
                        leading: Icon(Icons.language, color: textColor),
                        title: Text(
                          l10n.language,
                          style: TextStyle(color: textColor),
                        ),
                        trailing: DropdownButton<String>(
                          value: currentLocale.languageCode,
                          dropdownColor: isDark
                              ? AppColors.darkSurface2
                              : AppColors.lightSurface,
                          underline: const SizedBox.shrink(),
                          items: [
                            DropdownMenuItem(
                              value: 'vi',
                              child: Text(l10n.languageVietnamese),
                            ),
                            DropdownMenuItem(
                              value: 'en',
                              child: Text(l10n.languageEnglish),
                            ),
                          ],
                          onChanged: (final value) {
                            if (value != null) {
                              settings.setLocale(Locale(value));
                            }
                          },
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 10),
                if (!kIsWeb &&
                    (defaultTargetPlatform == TargetPlatform.windows ||
                        defaultTargetPlatform == TargetPlatform.linux ||
                        defaultTargetPlatform == TargetPlatform.macOS))
                  _buildSettingCard(
                    isDark: isDark,
                    child: ValueListenableBuilder<bool>(
                      valueListenable: settings.useNativeWindowEffectNotifier,
                      builder: (final context, final useNative, _) => Column(
                        children: [
                          SwitchListTile(
                            title: Text(
                              'Hiệu ứng cửa sổ hệ thống (Xuyên màn hình)',
                              style: TextStyle(color: textColor),
                            ),
                            subtitle: Text(
                              'Sử dụng hiệu ứng trong suốt nguyên bản của hệ điều hành. Sẽ tắt hình nền mờ của ứng dụng.',
                              style: TextStyle(
                                color: textColor.withValues(alpha: 0.6),
                                fontSize: 13,
                              ),
                            ),
                            value: useNative,
                            activeThumbColor: Theme.of(context).primaryColor,
                            onChanged: settings.setUseNativeWindowEffect,
                          ),
                          if (useNative)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              child: ValueListenableBuilder<double>(
                                valueListenable: settings.windowOpacityNotifier,
                                builder: (final context, final opacity, _) =>
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Độ trong suốt: ${(opacity * 100).toInt()}%',
                                          style: TextStyle(
                                            color: textColor.withValues(
                                              alpha: 0.7,
                                            ),
                                            fontSize: 12,
                                          ),
                                        ),
                                        Slider(
                                          value: opacity,
                                          min: 0.1,
                                          divisions: 90,
                                          activeColor: Theme.of(
                                            context,
                                          ).primaryColor,
                                          onChanged: settings.setWindowOpacity,
                                        ),
                                      ],
                                    ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                // Phím tắt: chỉ hiện trên Desktop (không có phím tắt trên Android)
                if (!kIsWeb &&
                    defaultTargetPlatform != TargetPlatform.android &&
                    defaultTargetPlatform != TargetPlatform.iOS) ...[
                  const SizedBox(height: 20),
                  _buildSectionHeader(
                    'Phím tắt toàn cục (Global Hotkeys)',
                    textColor,
                  ),
                  _buildSettingCard(
                    isDark: isDark,
                    child: ListTile(
                      title: Text(
                        'Điều khiển nhạc mọi lúc mọi nơi',
                        style: TextStyle(color: textColor),
                      ),
                      subtitle: Text(
                        'Phím tắt toàn cục (hoạt động cả khi app ẩn):\n'
                        '• Alt + Space: Phát / Tạm dừng\n'
                        '• Alt + Mũi tên Phải: Bài tiếp theo\n'
                        '• Alt + Mũi tên Trái: Bài trước đó\n\n'
                        'Phím tắt trong app:\n'
                        '• Space: Phát / Tạm dừng (khi không nhập liệu)',
                        style: TextStyle(
                          color: textColor.withValues(alpha: 0.6),
                          height: 1.5,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                _buildSectionHeader('Hệ thống', textColor),
                // Giảm Lag: chỉ Android
                if (!kIsWeb &&
                    defaultTargetPlatform == TargetPlatform.android) ...[
                  _buildSettingCard(
                    isDark: isDark,
                    child: ValueListenableBuilder<bool>(
                      valueListenable: settings.reduceLagNotifier,
                      builder: (final context, final reduceLag, _) =>
                          SwitchListTile(
                            title: Text(
                              'Giảm Lag (Reduce Lag)',
                              style: TextStyle(color: textColor),
                            ),
                            subtitle: Text(
                              'Ép ứng dụng chạy ở mức tài nguyên thấp nhất: '
                              'tắt visualizer & hiệu ứng mờ, giảm cache ảnh, '
                              'hạn chế preload — giúp máy yếu mượt hơn',
                              style: TextStyle(
                                color: textColor.withValues(alpha: 0.6),
                                fontSize: 13,
                              ),
                            ),
                            value: reduceLag,
                            activeThumbColor: Theme.of(context).primaryColor,
                            onChanged: settings.setReduceLag,
                          ),
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                // Minimize to tray: chỉ desktop
                if (!kIsWeb &&
                    defaultTargetPlatform != TargetPlatform.android &&
                    defaultTargetPlatform != TargetPlatform.iOS) ...[
                  _buildSettingCard(
                    isDark: isDark,
                    child: ValueListenableBuilder<bool>(
                      valueListenable: settings.minimizeToTrayNotifier,
                      builder: (final context, final minimizeToTray, _) =>
                          SwitchListTile(
                            title: Text(
                              'Thu nhỏ xuống khay hệ thống khi đóng (Minimize to Tray)',
                              style: TextStyle(color: textColor),
                            ),
                            subtitle: Text(
                              'Ngăn ứng dụng bị tắt hoàn toàn khi ấn nút X',
                              style: TextStyle(
                                color: textColor.withValues(alpha: 0.6),
                                fontSize: 13,
                              ),
                            ),
                            value: minimizeToTray,
                            activeThumbColor: Theme.of(context).primaryColor,
                            onChanged: settings.setMinimizeToTray,
                          ),
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                _buildSettingCard(
                  isDark: isDark,
                  child: ValueListenableBuilder<int>(
                    valueListenable: settings.visualizerShapeNotifier,
                    builder: (final context, final shape, _) {
                      const shapeNames = <String>[
                        'Vòng tròn xoáy (Circular)',
                        'Cột đứng (Bars)',
                        'Lượn sóng (Wave)',
                        'Đường hầm Phổ (Tunnel)',
                        'Bầu trời Sao (Starfield)',
                        'Máy hiện sóng (Oscilloscope)',
                        'Tia Sáng (Radial Burst)',
                      ];
                      return ListTile(
                        title: Text(
                          'Hình dáng Hiệu ứng Âm thanh',
                          style: TextStyle(color: textColor),
                        ),
                        subtitle: Text(
                          shapeNames[shape.clamp(0, 6)],
                          style: TextStyle(
                            color: textColor.withValues(alpha: 0.6),
                            fontSize: 13,
                          ),
                        ),
                        trailing: DropdownButton<int>(
                          value: shape,
                          dropdownColor: isDark
                              ? AppColors.darkSurface2
                              : AppColors.lightSurface,
                          underline: const SizedBox.shrink(),
                          items: const <DropdownMenuItem<int>>[
                            DropdownMenuItem(value: 0, child: Text('Circle')),
                            DropdownMenuItem(value: 1, child: Text('Bars')),
                            DropdownMenuItem(value: 2, child: Text('Wave')),
                            DropdownMenuItem(value: 3, child: Text('Tunnel')),
                            DropdownMenuItem(
                              value: 4,
                              child: Text('Starfield'),
                            ),
                            DropdownMenuItem(
                              value: 5,
                              child: Text('Oscilloscope'),
                            ),
                            DropdownMenuItem(
                              value: 6,
                              child: Text('Radial Burst'),
                            ),
                          ],
                          onChanged: (final value) {
                            if (value != null) {
                              settings.setVisualizerShape(value);
                            }
                          },
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 10),
                _buildSettingCard(
                  isDark: isDark,
                  child: ValueListenableBuilder<bool>(
                    valueListenable: settings.visualizerEnabledNotifier,
                    builder: (final context, final visualizerEnabled, _) =>
                        SwitchListTile(
                          title: Text(
                            'Hiệu ứng Phân tích âm thanh (Visualizer)',
                            style: TextStyle(color: textColor),
                          ),
                          subtitle: Text(
                            'Bật để xem sóng nhạc chuyển động theo beat',
                            style: TextStyle(
                              color: textColor.withValues(alpha: 0.6),
                              fontSize: 13,
                            ),
                          ),
                          value: visualizerEnabled,
                          activeThumbColor: Theme.of(context).primaryColor,
                          onChanged: settings.setVisualizerEnabled,
                        ),
                  ),
                ),
                const SizedBox(height: 20),
                _buildSectionHeader('Sleep Timer & Audio Effects', textColor),
                _buildSettingCard(
                  isDark: isDark,
                  child: Column(
                    children: [
                      ListTile(
                        leading: Icon(Icons.timer_outlined, color: textColor),
                        title: Text(
                          'Sleep Timer (Hẹn giờ tắt)',
                          style: TextStyle(color: textColor),
                        ),
                        subtitle: Text(
                          'Tự động dừng nhạc sau một khoảng thời gian',
                          style: TextStyle(
                            color: textColor.withValues(alpha: 0.6),
                            fontSize: 13,
                          ),
                        ),
                        trailing: OutlinedButton(
                          onPressed: () => SleepTimerDialog.show(context),
                          child: const Text('Đặt'),
                        ),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: Icon(Icons.tune, color: textColor),
                        title: Text(
                          'Audio Effects (Hiệu ứng âm)',
                          style: TextStyle(color: textColor),
                        ),
                        subtitle: Text(
                          'Crossfade, Pitch, Reverb, Compression',
                          style: TextStyle(
                            color: textColor.withValues(alpha: 0.6),
                            fontSize: 13,
                          ),
                        ),
                        trailing: Icon(
                          Icons.chevron_right,
                          color: textColor.withValues(alpha: 0.5),
                        ),
                        onTap: () => AudioEffectsDialog.show(context),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                _buildSectionHeader('Sắp xếp & Lọc', textColor),
                _buildSettingCard(
                  isDark: isDark,
                  child: ValueListenableBuilder<int>(
                    valueListenable: settings.sortModeNotifier,
                    builder: (final context, final sortMode, _) {
                      const sortNames = [
                        'Tên bài hát',
                        'Nghệ sĩ',
                        'Ngày thêm',
                        'Thời lượng',
                      ];
                      return ListTile(
                        leading: Icon(Icons.sort, color: textColor),
                        title: Text(
                          'Sắp xếp theo',
                          style: TextStyle(color: textColor),
                        ),
                        subtitle: Text(
                          sortNames[sortMode],
                          style: TextStyle(
                            color: textColor.withValues(alpha: 0.6),
                            fontSize: 13,
                          ),
                        ),
                        // Compact trailing controls — full-size IconButtons
                        // overflow on narrow (mobile) screens.
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ValueListenableBuilder<bool>(
                              valueListenable: settings.sortAscendingNotifier,
                              builder: (final context, final ascending, _) =>
                                  IconButton(
                                    visualDensity: VisualDensity.compact,
                                    iconSize: 20,
                                    icon: Icon(
                                      ascending
                                          ? Icons.arrow_upward
                                          : Icons.arrow_downward,
                                      color: textColor,
                                    ),
                                    onPressed: () =>
                                        settings.setSortAscending(!ascending),
                                  ),
                            ),
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              iconSize: 20,
                              icon: Icon(Icons.tune, color: textColor),
                              onPressed: () => SortFilterDialog.show(context),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                // Phím tắt & Media Keys: chỉ desktop
                if (!kIsWeb &&
                    defaultTargetPlatform != TargetPlatform.android &&
                    defaultTargetPlatform != TargetPlatform.iOS) ...[
                  const SizedBox(height: 20),
                  _buildSectionHeader('Phím tắt & Media Keys', textColor),
                  _buildSettingCard(
                    isDark: isDark,
                    child: Column(
                      children: [
                        ValueListenableBuilder<bool>(
                          valueListenable: settings.mediaKeyEnabledNotifier,
                          builder: (final context, final mediaKeyEnabled, _) =>
                              SwitchListTile(
                                secondary: Icon(
                                  Icons.keyboard,
                                  color: textColor,
                                ),
                                title: Text(
                                  'Hỗ trợ Phím Media (Media Keys)',
                                  style: TextStyle(color: textColor),
                                ),
                                subtitle: Text(
                                  'Play/Pause, Next, Previous trên bàn phím',
                                  style: TextStyle(
                                    color: textColor.withValues(alpha: 0.6),
                                    fontSize: 13,
                                  ),
                                ),
                                value: mediaKeyEnabled,
                                activeThumbColor: Theme.of(
                                  context,
                                ).primaryColor,
                                onChanged: settings.setMediaKeyEnabled,
                              ),
                        ),
                        const Divider(height: 1),
                        ValueListenableBuilder<bool>(
                          valueListenable:
                              settings.soundFeedbackEnabledNotifier,
                          builder: (final context, final soundEnabled, _) =>
                              SwitchListTile(
                                secondary: Icon(
                                  Icons.volume_up_rounded,
                                  color: textColor,
                                ),
                                title: Text(
                                  'Phát âm thanh khi chuyển bài',
                                  style: TextStyle(color: textColor),
                                ),
                                subtitle: Text(
                                  'Chỉ áp dụng trên điện thoại (Android)',
                                  style: TextStyle(
                                    color: textColor.withValues(alpha: 0.6),
                                    fontSize: 13,
                                  ),
                                ),
                                value: soundEnabled,
                                activeThumbColor: Theme.of(
                                  context,
                                ).primaryColor,
                                onChanged: settings.setSoundFeedbackEnabled,
                              ),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: Icon(
                            Icons.settings_input_component,
                            color: textColor,
                          ),
                          title: Text(
                            'Tùy chỉnh Phím tắt (Custom Hotkeys)',
                            style: TextStyle(color: textColor),
                          ),
                          subtitle: Text(
                            'Đặt lại phím tắt theo ý bạn',
                            style: TextStyle(
                              color: textColor.withValues(alpha: 0.6),
                              fontSize: 13,
                            ),
                          ),
                          trailing: Icon(
                            Icons.chevron_right,
                            color: textColor.withValues(alpha: 0.5),
                          ),
                          onTap: () => CustomHotkeysDialog.show(context),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                _buildSectionHeader('Hiệu ứng mờ', textColor),
                _buildSettingCard(
                  isDark: isDark,
                  child: Column(
                    children: [
                      ValueListenableBuilder<bool>(
                        valueListenable: settings.enableBlurNotifier,
                        builder: (final context, final enableBlur, _) => Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ListTile(
                              title: Text(
                                'Hiệu ứng mờ (Blur)',
                                style: TextStyle(color: textColor),
                              ),
                              subtitle: Text(
                                enableBlur ? 'Đang bật' : 'Đang tắt',
                                style: TextStyle(
                                  color: textColor.withValues(alpha: 0.6),
                                  fontSize: 13,
                                ),
                              ),
                              trailing: Switch(
                                value: enableBlur,
                                onChanged: settings.setEnableBlur,
                                activeThumbColor: Theme.of(
                                  context,
                                ).primaryColor,
                              ),
                            ),
                            if (enableBlur)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                child: ValueListenableBuilder<double>(
                                  valueListenable: settings.blurLevelNotifier,
                                  builder:
                                      (
                                        final context,
                                        final blurLevel,
                                        _,
                                      ) => Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Mức độ mờ: ${blurLevel.toInt()}',
                                            style: TextStyle(
                                              color: textColor.withValues(
                                                alpha: 0.7,
                                              ),
                                              fontSize: 12,
                                            ),
                                          ),
                                          Slider(
                                            value: blurLevel,
                                            max: 100,
                                            divisions: 100,
                                            activeColor: Theme.of(
                                              context,
                                            ).primaryColor,
                                            onChanged: settings.setBlurLevel,
                                          ),
                                        ],
                                      ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(final String title, final Color textColor) =>
      Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
        child: Text(
          title,
          style: TextStyle(
            color: textColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      );

  Widget _buildSettingCard({
    required final bool isDark,
    required final Widget child,
  }) => RepaintBoundary(
    child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface2 : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(12),
        // Border so cards stay visible against the page background
        // (surface colors are close to the background in both themes).
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.10)
              : Colors.black.withValues(alpha: 0.10),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.25)
                : Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(type: MaterialType.transparency, child: child),
    ),
  );
}
