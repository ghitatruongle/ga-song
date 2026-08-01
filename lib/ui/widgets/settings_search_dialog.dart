/// Settings Search Dialog for G.A - Song
///
/// Provides a searchable interface for all settings, accessible via Ctrl+K.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import '../../core/settings_manager.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme_utils.dart';
import '../../providers/service_providers.dart';
import '../../l10n/app_localizations.dart';
import '../utils/haptic_helper.dart';

/// Settings search entry with category and action
class _SettingsSearchEntry {
  final String category;
  final String title;
  final String? subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final String searchText;

  const _SettingsSearchEntry({
    required this.category,
    required this.title,
    this.subtitle,
    required this.icon,
    required this.onTap,
    required this.searchText,
  });
}

/// Settings Search Dialog
class SettingsSearchDialog extends ConsumerStatefulWidget {
  const SettingsSearchDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) => const SettingsSearchDialog(),
    );
  }

  @override
  ConsumerState<SettingsSearchDialog> createState() => _SettingsSearchDialogState();
}

class _SettingsSearchDialogState extends ConsumerState<SettingsSearchDialog> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  List<_SettingsSearchEntry> _allEntries = [];
  List<_SettingsSearchEntry> _filteredEntries = [];
  String _query = '';

  @override
  void initState() {
    super.initState();
    // Deferred: _buildAllEntries reads AppLocalizations.of(context),
    // which is not allowed during initState.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _buildAllEntries();
      _filteredEntries = _allEntries;
    });

    // Focus the search field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });

    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _buildAllEntries() {
    final settings = ref.read(settingsManagerProvider);
    final l10n = AppLocalizations.of(context)!;
    final isDark = context.isDark;
    final accentColor = Theme.of(context).colorScheme.primary;

    _allEntries = [
      // Theme & Appearance
      _SettingsSearchEntry(
        category: l10n.categoryAppearance,
        title: l10n.themeMode,
        subtitle: _getThemeModeSubtitle(settings.themeModeNotifier.value),
        icon: Icons.palette_outlined,
        searchText: '${l10n.categoryAppearance} ${l10n.themeMode} ${_getThemeModeSubtitle(settings.themeModeNotifier.value)}',
        onTap: () => _navigateToSettingsPage('appearance', 'theme'),
      ),
      _SettingsSearchEntry(
        category: l10n.categoryAppearance,
        title: l10n.useDynamicColor,
        subtitle: settings.useDynamicColorNotifier.value ? l10n.enabled : l10n.disabled,
        icon: Icons.color_lens_outlined,
        searchText: '${l10n.categoryAppearance} ${l10n.useDynamicColor}',
        onTap: () => _navigateToSettingsPage('appearance', 'dynamic_color'),
      ),
      _SettingsSearchEntry(
        category: l10n.categoryAppearance,
        title: l10n.customPrimaryColor,
        subtitle: settings.customPrimaryColorNotifier.value != null ? l10n.set : l10n.notSet,
        icon: Icons.format_paint_outlined,
        searchText: '${l10n.categoryAppearance} ${l10n.customPrimaryColor}',
        onTap: () => _navigateToSettingsPage('appearance', 'custom_color'),
      ),
      _SettingsSearchEntry(
        category: l10n.categoryAppearance,
        title: l10n.enableBlur,
        subtitle: settings.enableBlurNotifier.value ? l10n.enabled : l10n.disabled,
        icon: Icons.blur_on_outlined,
        searchText: '${l10n.categoryAppearance} ${l10n.enableBlur}',
        onTap: () => _navigateToSettingsPage('appearance', 'blur'),
      ),
      _SettingsSearchEntry(
        category: l10n.categoryAppearance,
        title: l10n.blurLevel,
        subtitle: '${settings.blurLevelNotifier.value.round()}%',
        icon: Icons.tune_outlined,
        searchText: '${l10n.categoryAppearance} ${l10n.blurLevel}',
        onTap: () => _navigateToSettingsPage('appearance', 'blur_level'),
      ),
      _SettingsSearchEntry(
        category: l10n.categoryAppearance,
        title: l10n.useNativeWindowEffect,
        subtitle: settings.useNativeWindowEffectNotifier.value ? l10n.enabled : l10n.disabled,
        icon: Icons.desktop_windows_outlined,
        searchText: '${l10n.categoryAppearance} ${l10n.useNativeWindowEffect}',
        onTap: () => _navigateToSettingsPage('appearance', 'native_window_effect'),
      ),
      _SettingsSearchEntry(
        category: l10n.categoryAppearance,
        title: l10n.windowOpacity,
        subtitle: '${(settings.windowOpacityNotifier.value * 100).round()}%',
        icon: Icons.opacity_outlined,
        searchText: '${l10n.categoryAppearance} ${l10n.windowOpacity}',
        onTap: () => _navigateToSettingsPage('appearance', 'window_opacity'),
      ),
      _SettingsSearchEntry(
        category: l10n.categoryAppearance,
        title: l10n.isGridView,
        subtitle: settings.isGridViewNotifier.value ? l10n.enabled : l10n.disabled,
        icon: Icons.grid_view_outlined,
        searchText: '${l10n.categoryAppearance} ${l10n.isGridView}',
        onTap: () => _navigateToSettingsPage('appearance', 'grid_view'),
      ),
      _SettingsSearchEntry(
        category: l10n.categoryAppearance,
        title: l10n.customBackgroundImage,
        subtitle: settings.customBackgroundImageNotifier.value != null ? l10n.set : l10n.none,
        icon: Icons.image_outlined,
        searchText: '${l10n.categoryAppearance} ${l10n.customBackgroundImage}',
        onTap: () => _navigateToSettingsPage('appearance', 'custom_background'),
      ),

      // Playback
      _SettingsSearchEntry(
        category: l10n.categoryPlayback,
        title: l10n.crossfadeDuration,
        subtitle: '${settings.crossfadeDurationNotifier.value}s',
        icon: Icons.av_timer_outlined,
        searchText: '${l10n.categoryPlayback} ${l10n.crossfadeDuration}',
        onTap: () => _navigateToSettingsPage('playback', 'crossfade'),
      ),
      _SettingsSearchEntry(
        category: l10n.categoryPlayback,
        title: l10n.crossfadeCurve,
        subtitle: _getCrossfadeCurveLabel(settings.crossfadeCurveNotifier.value),
        icon: Icons.show_chart_outlined,
        searchText: '${l10n.categoryPlayback} ${l10n.crossfadeCurve}',
        onTap: () => _navigateToSettingsPage('playback', 'crossfade_curve'),
      ),
      _SettingsSearchEntry(
        category: l10n.categoryPlayback,
        title: l10n.normalization,
        subtitle: settings.normalizationEnabledNotifier.value ? l10n.enabled : l10n.disabled,
        icon: Icons.auto_fix_high_outlined,
        searchText: '${l10n.categoryPlayback} ${l10n.normalization}',
        onTap: () => _navigateToSettingsPage('playback', 'normalization'),
      ),
      _SettingsSearchEntry(
        category: l10n.categoryPlayback,
        title: l10n.normalizationLevel,
        subtitle: '${settings.normalizationLevelNotifier.value.toStringAsFixed(1)} dB',
        icon: Icons.volume_up_outlined,
        searchText: '${l10n.categoryPlayback} ${l10n.normalizationLevel}',
        onTap: () => _navigateToSettingsPage('playback', 'normalization_level'),
      ),
      _SettingsSearchEntry(
        category: l10n.categoryPlayback,
        title: l10n.equalizer,
        subtitle: settings.eqPresetNotifier.value,
        icon: Icons.equalizer_outlined,
        searchText: '${l10n.categoryPlayback} ${l10n.equalizer}',
        onTap: () => _navigateToSettingsPage('playback', 'equalizer'),
      ),
      _SettingsSearchEntry(
        category: l10n.categoryPlayback,
        title: l10n.eqBass,
        subtitle: '${settings.eqBassNotifier.value}',
        icon: Icons.speaker_outlined,
        searchText: '${l10n.categoryPlayback} ${l10n.eqBass}',
        onTap: () => _navigateToSettingsPage('playback', 'eq_bass'),
      ),
      _SettingsSearchEntry(
        category: l10n.categoryPlayback,
        title: l10n.reverb,
        subtitle: settings.reverbMixNotifier.value > 0 ? '${(settings.reverbMixNotifier.value * 100).round()}%' : l10n.off,
        icon: Icons.music_note_outlined,
        searchText: '${l10n.categoryPlayback} ${l10n.reverb}',
        onTap: () => _navigateToSettingsPage('playback', 'reverb'),
      ),
      _SettingsSearchEntry(
        category: l10n.categoryPlayback,
        title: l10n.compressor,
        subtitle: settings.compressionRatioNotifier.value > 1 ? '${settings.compressionRatioNotifier.value.toStringAsFixed(1)}:1' : l10n.off,
        icon: Icons.compress_outlined,
        searchText: '${l10n.categoryPlayback} ${l10n.compressor}',
        onTap: () => _navigateToSettingsPage('playback', 'compressor'),
      ),
      _SettingsSearchEntry(
        category: l10n.categoryPlayback,
        title: l10n.pitchShift,
        subtitle: '${settings.pitchShiftNotifier.value.toStringAsFixed(2)}x',
        icon: Icons.tune_outlined,
        searchText: '${l10n.categoryPlayback} ${l10n.pitchShift}',
        onTap: () => _navigateToSettingsPage('playback', 'pitch_shift'),
      ),

      // Visualizer
      _SettingsSearchEntry(
        category: l10n.categoryVisualizer,
        title: l10n.visualizerEnabled,
        subtitle: settings.visualizerEnabledNotifier.value ? l10n.enabled : l10n.disabled,
        icon: Icons.waves_outlined,
        searchText: '${l10n.categoryVisualizer} ${l10n.visualizerEnabled}',
        onTap: () => _navigateToSettingsPage('visualizer', 'enabled'),
      ),
      _SettingsSearchEntry(
        category: l10n.categoryVisualizer,
        title: l10n.visualizerShape,
        subtitle: _getVisualizerShapeLabel(settings.visualizerShapeNotifier.value),
        icon: Icons.category_outlined,
        searchText: '${l10n.categoryVisualizer} ${l10n.visualizerShape}',
        onTap: () => _navigateToSettingsPage('visualizer', 'shape'),
      ),
      _SettingsSearchEntry(
        category: l10n.categoryVisualizer,
        title: l10n.sensitivity,
        subtitle: '${settings.sensitivityNotifier.value.toStringAsFixed(1)}x',
        icon: Icons.tune_outlined,
        searchText: '${l10n.categoryVisualizer} ${l10n.sensitivity}',
        onTap: () => _navigateToSettingsPage('visualizer', 'sensitivity'),
      ),

      // Lyrics
      _SettingsSearchEntry(
        category: l10n.categoryLyrics,
        title: l10n.lyricsFontSize,
        subtitle: '${settings.lyricFontSizeNotifier.value.toStringAsFixed(1)}x',
        icon: Icons.format_size_outlined,
        searchText: '${l10n.categoryLyrics} ${l10n.lyricsFontSize}',
        onTap: () => _navigateToSettingsPage('lyrics', 'font_size'),
      ),
      _SettingsSearchEntry(
        category: l10n.categoryLyrics,
        title: l10n.showLyricsInMiniPlayer,
        subtitle: settings.showLyricsInMiniPlayerNotifier.value ? l10n.enabled : l10n.disabled,
        icon: Icons.lyrics_outlined,
        searchText: '${l10n.categoryLyrics} ${l10n.showLyricsInMiniPlayer}',
        onTap: () => _navigateToSettingsPage('lyrics', 'mini_player'),
      ),
      _SettingsSearchEntry(
        category: l10n.categoryLyrics,
        title: l10n.autoFetchLyrics,
        subtitle: l10n.enabled,
        icon: Icons.download_outlined,
        searchText: '${l10n.categoryLyrics} ${l10n.autoFetchLyrics}',
        onTap: () => _navigateToSettingsPage('lyrics', 'auto_fetch'),
      ),

      // Window & System
      _SettingsSearchEntry(
        category: l10n.categoryWindowSystem,
        title: l10n.minimizeToTray,
        subtitle: settings.minimizeToTrayNotifier.value ? l10n.enabled : l10n.disabled,
        icon: Icons.minimize_outlined,
        searchText: '${l10n.categoryWindowSystem} ${l10n.minimizeToTray}',
        onTap: () => _navigateToSettingsPage('window', 'minimize_to_tray'),
      ),
      _SettingsSearchEntry(
        category: l10n.categoryWindowSystem,
        title: l10n.autoHidePlayerBar,
        subtitle: settings.autoHidePlayerBarNotifier.value ? l10n.enabled : l10n.disabled,
        icon: Icons.auto_mode_outlined,
        searchText: '${l10n.categoryWindowSystem} ${l10n.autoHidePlayerBar}',
        onTap: () => _navigateToSettingsPage('window', 'auto_hide_player_bar'),
      ),
      _SettingsSearchEntry(
        category: l10n.categoryWindowSystem,
        title: l10n.language,
        subtitle: settings.localeNotifier.value.languageCode == 'en' ? 'English' : 'Tiếng Việt',
        icon: Icons.language_outlined,
        searchText: '${l10n.categoryWindowSystem} ${l10n.language}',
        onTap: () => _navigateToSettingsPage('window', 'language'),
      ),

      // Hotkeys
      _SettingsSearchEntry(
        category: l10n.categoryHotkeys,
        title: l10n.customHotkeys,
        subtitle: l10n.manageHotkeys,
        icon: Icons.keyboard_outlined,
        searchText: '${l10n.categoryHotkeys} ${l10n.customHotkeys}',
        onTap: () => _navigateToSettingsPage('hotkeys', 'custom'),
      ),
      _SettingsSearchEntry(
        category: l10n.categoryHotkeys,
        title: l10n.mediaKeyEnabled,
        subtitle: settings.mediaKeyEnabledNotifier.value ? l10n.enabled : l10n.disabled,
        icon: Icons.play_circle_outline,
        searchText: '${l10n.categoryHotkeys} ${l10n.mediaKeyEnabled}',
        onTap: () => _navigateToSettingsPage('hotkeys', 'media_keys'),
      ),

      // Sleep Timer
      _SettingsSearchEntry(
        category: l10n.categorySleepTimer,
        title: l10n.sleepTimer,
        subtitle: _getSleepTimerSubtitle(),
        icon: Icons.timer_outlined,
        searchText: '${l10n.categorySleepTimer} ${l10n.sleepTimer}',
        onTap: () => _navigateToSettingsPage('sleep_timer', 'main'),
      ),
      _SettingsSearchEntry(
        category: l10n.categorySleepTimer,
        title: l10n.sleepTimerDuration,
        subtitle: _getSleepTimerDurationSubtitle(),
        icon: Icons.schedule_outlined,
        searchText: '${l10n.categorySleepTimer} ${l10n.sleepTimerDuration}',
        onTap: () => _navigateToSettingsPage('sleep_timer', 'duration'),
      ),
      _SettingsSearchEntry(
        category: l10n.categorySleepTimer,
        title: l10n.sleepTimerFadeOut,
        subtitle: _getSleepTimerFadeOutSubtitle(),
        icon: Icons.volume_up_outlined,
        searchText: '${l10n.categorySleepTimer} ${l10n.sleepTimerFadeOut}',
        onTap: () => _navigateToSettingsPage('sleep_timer', 'fade_out'),
      ),
      _SettingsSearchEntry(
        category: l10n.categorySleepTimer,
        title: l10n.stopAtEndOfSong,
        subtitle: settings.sleepTimerStopAtEndOfSongNotifier.value ? l10n.enabled : l10n.disabled,
        icon: Icons.skip_next_outlined,
        searchText: '${l10n.categorySleepTimer} ${l10n.stopAtEndOfSong}',
        onTap: () => _navigateToSettingsPage('sleep_timer', 'stop_at_end'),
      ),

      // Advanced
      _SettingsSearchEntry(
        category: l10n.categoryAdvanced,
        title: l10n.reverbRoomSize,
        subtitle: '${(settings.reverbRoomSizeNotifier.value * 100).round()}%',
        icon: Icons.meeting_room_outlined,
        searchText: '${l10n.categoryAdvanced} ${l10n.reverbRoomSize}',
        onTap: () => _navigateToSettingsPage('advanced', 'reverb_room'),
      ),
      _SettingsSearchEntry(
        category: l10n.categoryAdvanced,
        title: l10n.compressorThreshold,
        subtitle: '${settings.compThresholdNotifier.value.toStringAsFixed(1)} dB',
        icon: Icons.compress_outlined,
        searchText: '${l10n.categoryAdvanced} ${l10n.compressorThreshold}',
        onTap: () => _navigateToSettingsPage('advanced', 'compressor_threshold'),
      ),
      _SettingsSearchEntry(
        category: l10n.categoryAdvanced,
        title: l10n.compressorAttack,
        subtitle: '${settings.compAttackNotifier.value.toStringAsFixed(1)} ms',
        icon: Icons.flash_on_outlined,
        searchText: '${l10n.categoryAdvanced} ${l10n.compressorAttack}',
        onTap: () => _navigateToSettingsPage('advanced', 'compressor_attack'),
      ),
      _SettingsSearchEntry(
        category: l10n.categoryAdvanced,
        title: l10n.compressorRelease,
        subtitle: '${settings.compReleaseNotifier.value.toStringAsFixed(1)} ms',
        icon: Icons.timer_outlined,
        searchText: '${l10n.categoryAdvanced} ${l10n.compressorRelease}',
        onTap: () => _navigateToSettingsPage('advanced', 'compressor_release'),
      ),
      _SettingsSearchEntry(
        category: l10n.categoryAdvanced,
        title: l10n.compressorKneeWidth,
        subtitle: '${settings.compKneeWidthNotifier.value.toStringAsFixed(1)} dB',
        icon: Icons.show_chart_outlined,
        searchText: '${l10n.categoryAdvanced} ${l10n.compressorKneeWidth}',
        onTap: () => _navigateToSettingsPage('advanced', 'compressor_knee'),
      ),
      _SettingsSearchEntry(
        category: l10n.categoryAdvanced,
        title: l10n.compressorMakeupGain,
        subtitle: '${settings.compMakeupGainNotifier.value.toStringAsFixed(1)} dB',
        icon: Icons.trending_up_outlined,
        searchText: '${l10n.categoryAdvanced} ${l10n.compressorMakeupGain}',
        onTap: () => _navigateToSettingsPage('advanced', 'compressor_makeup'),
      ),
      _SettingsSearchEntry(
        category: l10n.categoryAdvanced,
        title: l10n.reverbDamp,
        subtitle: '${(settings.reverbDampNotifier.value * 100).round()}%',
        icon: Icons.water_drop_outlined,
        searchText: '${l10n.categoryAdvanced} ${l10n.reverbDamp}',
        onTap: () => _navigateToSettingsPage('advanced', 'reverb_damp'),
      ),

      // Feedback
      _SettingsSearchEntry(
        category: l10n.categoryFeedback,
        title: l10n.soundFeedbackEnabled,
        subtitle: settings.soundFeedbackEnabledNotifier.value ? l10n.enabled : l10n.disabled,
        icon: Icons.volume_up_outlined,
        searchText: '${l10n.categoryFeedback} ${l10n.soundFeedbackEnabled}',
        onTap: () => _navigateToSettingsPage('feedback', 'sound'),
      ),
      _SettingsSearchEntry(
        category: l10n.categoryFeedback,
        title: l10n.hapticFeedbackEnabled,
        subtitle: settings.hapticFeedbackEnabledNotifier.value ? l10n.enabled : l10n.disabled,
        icon: Icons.vibration_outlined,
        searchText: '${l10n.categoryFeedback} ${l10n.hapticFeedbackEnabled}',
        onTap: () => _navigateToSettingsPage('feedback', 'haptic'),
      ),
    ];

    _filteredEntries = _allEntries;
  }

  String _getThemeModeSubtitle(ThemeMode mode) {
    final l10n = AppLocalizations.of(context)!;
    switch (mode) {
      case ThemeMode.light:
        return l10n.light;
      case ThemeMode.dark:
        return l10n.dark;
      case ThemeMode.system:
      default:
        return l10n.system;
    }
  }

  String _getCrossfadeCurveLabel(int value) {
    switch (value) {
      case 0:
        return AppLocalizations.of(context)!.linear;
      case 1:
        return AppLocalizations.of(context)!.exponential;
      case 2:
        return AppLocalizations.of(context)!.sCurve;
      default:
        return '';
    }
  }

  String _getVisualizerShapeLabel(int value) {
    final l10n = AppLocalizations.of(context)!;
    switch (value) {
      case 0:
        return l10n.visualizerShapeCircle;
      case 1:
        return l10n.visualizerShapeBars;
      case 2:
        return l10n.visualizerShapeWave;
      case 3:
        return l10n.visualizerShapeTunnel;
      case 4:
        return l10n.visualizerShapeStarfield;
      case 5:
        return l10n.visualizerShapeOscilloscope;
      case 6:
        return l10n.visualizerShapeRadial;
      default:
        return '';
    }
  }

  String _getSleepTimerSubtitle() {
    final settings = ref.read(settingsManagerProvider);
    final l10n = AppLocalizations.of(context)!;
    final preset = settings.sleepTimerDurationPresetNotifier.value;
    switch (preset) {
      case 1:
        return '15 ${AppLocalizations.of(context)!.minutes}';
      case 2:
        return '30 ${AppLocalizations.of(context)!.minutes}';
      case 3:
        return '45 ${AppLocalizations.of(context)!.minutes}';
      case 4:
        return '60 ${AppLocalizations.of(context)!.minutes}';
      case 5:
        return AppLocalizations.of(context)!.endOfSong;
      case 0:
      default:
        final duration = settings.sleepTimerCustomDurationNotifier.value;
        return '${duration.inMinutes} ${AppLocalizations.of(context)!.minutes}';
    }
  }

  String _getSleepTimerDurationSubtitle() {
    final settings = ref.read(settingsManagerProvider);
    final l10n = AppLocalizations.of(context)!;
    final duration = settings.sleepTimerCustomDurationNotifier.value;
    return '${duration.inMinutes} ${l10n.minutes}';
  }

  String _getSleepTimerFadeOutSubtitle() {
    final settings = ref.read(settingsManagerProvider);
    final l10n = AppLocalizations.of(context)!;
    final enabled = settings.sleepTimerFadeOutEnabledNotifier.value;
    if (!enabled) return AppLocalizations.of(context)!.disabled;
    return '${settings.sleepTimerFadeOutDurationNotifier.value} ${AppLocalizations.of(context)!.seconds}';
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _query = _searchController.text;
      if (query.isEmpty) {
        _filteredEntries = _allEntries;
      } else {
        _filteredEntries = _allEntries.where((entry) {
          return entry.searchText.toLowerCase().contains(query) ||
                 entry.category.toLowerCase().contains(query) ||
                 entry.title.toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  void _navigateToSettingsPage(String category, String setting) {
    // Close dialog first
    Navigator.of(context).pop();
    
    // Navigate to settings page
    // This would typically involve navigating to the settings page and scrolling to the setting
    // For now, we'll just show a snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Navigate to $category > $setting'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final accentColor = Theme.of(context).colorScheme.primary;
    final l10n = AppLocalizations.of(context)!;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: 600,
        constraints: const BoxConstraints(maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface2 : AppColors.lightSurface2,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                border: Border(
                  bottom: BorderSide(
                    color: context.adaptive.withValues(alpha: 0.1),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.search,
                    color: context.adaptive.withValues(alpha: 0.6),
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      focusNode: _focusNode,
                      autofocus: true,
                      style: TextStyle(
                        fontSize: 16,
                        color: context.adaptive,
                      ),
                      decoration: InputDecoration(
                        hintText: AppLocalizations.of(context)!.searchSettings,
                        hintStyle: TextStyle(
                          color: context.adaptive.withValues(alpha: 0.4),
                          fontSize: 16,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      onChanged: (_) => _onSearchChanged(),
                    onSubmitted: (_) {
                      if (_filteredEntries.isNotEmpty) {
                        _filteredEntries.first.onTap();
                      }
                    },
                  ),
                ),
                  if (_query.isNotEmpty)
                    IconButton(
                      icon: Icon(
                        Icons.clear,
                        color: context.adaptive.withValues(alpha: 0.6),
                      ),
                      onPressed: () {
                        _searchController.clear();
                        _onSearchChanged();
                        _focusNode.requestFocus();
                      },
                    ),
                ],
              ),
            ),

            // Results
            Flexible(
              child: _filteredEntries.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(40),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 48,
                              color: context.adaptive.withValues(alpha: 0.3),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              AppLocalizations.of(context)!.noSettingsFound,
                              style: TextStyle(
                                color: context.adaptive.withValues(alpha: 0.5),
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.all(16),
                      itemCount: _filteredEntries.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final entry = _filteredEntries[index];
                        final isFirstInCategory = index == 0 || 
                            _filteredEntries[index - 1].category != entry.category;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (isFirstInCategory) ...[
                              Padding(
                                padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                                child: Text(
                                  entry.category,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: context.adaptive.withValues(alpha: 0.5),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(10),
                                onTap: () {
                                  safeHaptic(HapticType.light);
                                  entry.onTap();
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: context.adaptive.withValues(alpha: 0.1),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 36,
                                        height: 36,
                                        decoration: BoxDecoration(
                                          color: context.adaptive.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Icon(
                                          entry.icon,
                                          size: 20,
                                          color: context.adaptive.withValues(alpha: 0.7),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              entry.title,
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                                color: context.adaptive,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            if (entry.subtitle != null) ...[
                                              const SizedBox(height: 2),
                                              Text(
                                                entry.subtitle!,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: context.adaptive.withValues(alpha: 0.5),
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Icon(
                                        Icons.chevron_right,
                                        size: 20,
                                        color: context.adaptive.withValues(alpha: 0.4),
                                      ),
                                    ],
                                  ),
                              ),
                            ),
                          ),
                        ],
                        ],
                      );
                    },
                  ),
                ),

            // Footer with shortcut hint
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface2 : AppColors.lightSurface2,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                border: Border(
                  top: BorderSide(
                    color: context.adaptive.withValues(alpha: 0.1),
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.keyboard,
                    size: 16,
                    color: context.adaptive.withValues(alpha: 0.5),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    AppLocalizations.of(context)!.pressCtrlKToSearch,
                    style: TextStyle(
                      fontSize: 12,
                      color: context.adaptive.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Helper to show the settings search dialog
Future<void> showSettingsSearch(BuildContext context) {
  return SettingsSearchDialog.show(context);
}