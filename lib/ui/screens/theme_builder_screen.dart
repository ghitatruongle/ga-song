/// Theme Builder Screen for G.A - Song
///
/// Provides a live theme customization interface with real-time preview.
///
/// Features:
/// - Seed color picker with hex input
/// - Dynamic color (Material You) toggle
/// - Advanced color customization
/// - Live preview with sample UI elements
/// - Theme mode switching (light/dark/system)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/settings_manager.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme_utils.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/service_providers.dart';
import '../utils/haptic_helper.dart';

/// Theme Builder Screen
class ThemeBuilderScreen extends ConsumerStatefulWidget {
  const ThemeBuilderScreen({super.key});

  @override
  ConsumerState<ThemeBuilderScreen> createState() => _ThemeBuilderScreenState();
}

class _ThemeBuilderScreenState extends ConsumerState<ThemeBuilderScreen> {
  final TextEditingController _seedColorController = TextEditingController();
  bool _showAdvanced = false;

  Color _previewPrimary = const Color(0xFF1DB954);
  Color _previewSecondary = const Color(0xFF7C4DFF);
  Color _previewSurface = Colors.white;
  Color _previewBackground = const Color(0xFFF5F5F5);
  Color _previewOnPrimary = Colors.white;
  Color _previewOnSurface = Colors.black;

  @override
  void initState() {
    super.initState();
    // Deferred: _updatePreviewColors reads Theme.of(context) via context.isDark,
    // which is not allowed during initState.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _updatePreviewColors();
    });
    _seedColorController.text = '#1DB954';
  }

  @override
  void dispose() {
    _seedColorController.dispose();
    super.dispose();
  }

  void _updatePreviewColors() {
    final settings = ref.read(settingsManagerProvider);
    Color seedColor;
    if (settings.useDynamicColorNotifier.value &&
        settings.dynamicPrimaryColorNotifier.value != null) {
      seedColor = settings.dynamicPrimaryColorNotifier.value!;
    } else if (settings.customPrimaryColorNotifier.value != null) {
      seedColor = settings.customPrimaryColorNotifier.value!;
    } else {
      seedColor = const Color(0xFF1DB954);
    }

    final lightScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.light,
    );
    final darkScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.dark,
    );

    final isDark = context.isDark;
    final scheme = isDark ? darkScheme : lightScheme;

    setState(() {
      _previewPrimary = scheme.primary;
      _previewSecondary = scheme.secondary;
      _previewSurface = scheme.surface;
      _previewBackground = scheme.background;
      _previewOnPrimary = scheme.onPrimary;
      _previewOnSurface = scheme.onSurface;
    });

    _seedColorController.text =
        '#${seedColor.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}';
  }

  Future<void> _pickSeedColor() async {
    final color = await showDialog<Color>(
      context: context,
      builder: (context) => _ColorPickerDialog(initialColor: _previewPrimary),
    );
    if (color != null) {
      await ref.read(settingsManagerProvider).setCustomPrimaryColor(color);
      _updatePreviewColors();
    }
  }

  void _resetToDefaults() {
    ref.read(settingsManagerProvider).setCustomPrimaryColor(
      const Color(0xFF1DB954),
    );
    ref.read(settingsManagerProvider).setUseDynamicColor(true);
    _updatePreviewColors();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsManagerProvider);
    final isDark = context.isDark;
    final l10n = AppLocalizations.of(context)!;

    // Keep preview in sync with settings changes
    ref.listen(settingsManagerProvider, (_, __) {
      _updatePreviewColors();
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.themeMode),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _resetToDefaults,
            tooltip: l10n.retry,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Row(
          children: [
            // ─── Controls Sidebar ──────────────────────────────────────────
            Container(
              width: 380,
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkSurface
                    : AppColors.lightSurface,
                border: Border(
                  right: BorderSide(color: Theme.of(context).dividerColor),
                ),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Seed Color
                    Text(
                      l10n.customPrimaryColor,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _seedColorController,
                            decoration: InputDecoration(
                              labelText: 'Hex',
                              hintText: '#1DB954',
                              prefixIcon: const Icon(Icons.color_lens),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                            ),
                            onChanged: (value) {
                              if (value.length == 7 && value.startsWith('#')) {
                                try {
                                  final color = Color(
                                    int.parse(
                                      'FF${value.substring(1)}',
                                      radix: 16,
                                    ),
                                  );
                                  ref
                                      .read(settingsManagerProvider)
                                      .setCustomPrimaryColor(color);
                                  _updatePreviewColors();
                                } catch (_) {}
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        IconButton.filled(
                          icon: const Icon(Icons.color_lens),
                          onPressed: _pickSeedColor,
                          tooltip: l10n.customPrimaryColor,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Dynamic Color Toggle
                    Material(
                      color: Colors.transparent,
                      child: SwitchListTile(
                        title: Text(l10n.useDynamicColor),
                        subtitle: Text(l10n.useDynamicColor),
                        value: settings.useDynamicColorNotifier.value,
                        onChanged: (value) {
                          ref
                              .read(settingsManagerProvider)
                              .setUseDynamicColor(value);
                          _updatePreviewColors();
                        },
                        secondary: Icon(
                          Icons.auto_awesome,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Theme Mode
                    Text(
                      l10n.themeMode,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    SegmentedButton<ThemeMode>(
                      segments: [
                        ButtonSegment(
                          value: ThemeMode.light,
                          label: Text(l10n.light),
                          icon: const Icon(Icons.light_mode),
                        ),
                        ButtonSegment(
                          value: ThemeMode.dark,
                          label: Text(l10n.dark),
                          icon: const Icon(Icons.dark_mode),
                        ),
                        ButtonSegment(
                          value: ThemeMode.system,
                          label: Text(l10n.system),
                          icon: const Icon(Icons.settings_system_daydream),
                        ),
                      ],
                      selected: {settings.themeModeNotifier.value},
                      onSelectionChanged: (v) {
                        ref
                            .read(settingsManagerProvider)
                            .setThemeMode(v.first);
                      },
                    ),
                    const SizedBox(height: 24),

                    // Advanced Colors
                    Material(
                      color: Colors.transparent,
                      child: ExpansionTile(
                        title: Text(l10n.advanced),
                        leading: Icon(
                          Icons.tune,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        initiallyExpanded: _showAdvanced,
                        onExpansionChanged: (v) =>
                            setState(() => _showAdvanced = v),
                        children: [
                          _buildColorPreviewRow(
                            l10n.customPrimaryColor,
                            _previewPrimary,
                          ),
                          _buildColorPreviewRow(
                            l10n.categoryAppearance,
                            _previewSecondary,
                          ),
                          _buildColorPreviewRow(
                            l10n.enableBlur,
                            _previewSurface,
                          ),
                          _buildColorPreviewRow(
                            l10n.windowOpacity,
                            _previewBackground,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Actions
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.refresh),
                            label: Text(l10n.retry),
                            onPressed: _resetToDefaults,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton.icon(
                            icon: const Icon(Icons.save),
                            label: Text(l10n.save),
                            onPressed: () {
                              Navigator.of(context).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(l10n.importSuccess)),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // ─── Preview Pane ─────────────────────────────────────────────
            Expanded(
              child: Container(
                color: isDark
                    ? AppColors.darkBackground
                    : AppColors.lightBackground,
                child: Column(
                  children: [
                    // Preview Toolbar
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkSurface
                            : AppColors.lightSurface,
                        border: Border(
                          bottom: BorderSide(
                            color: Theme.of(context).dividerColor,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(
                            'Preview',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const Spacer(),
                          Icon(
                            Icons.visibility,
                            color: context.adaptive.withValues(alpha: 0.5),
                          ),
                        ],
                      ),
                    ),
                    // Preview Content
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 600),
                            child: _buildPreviewCard(context),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewCard(BuildContext context) {
    return Card(
      elevation: 8,
      shadowColor: Colors.black.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: _previewSurface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _previewPrimary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.music_note,
                    color: _previewOnPrimary,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Theme Preview',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: _previewOnSurface,
                        ),
                      ),
                      Text(
                        'Live preview of your theme',
                        style: TextStyle(
                          fontSize: 14,
                          color: _previewOnSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Color Palette
            Text(
              'Color Palette',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildColorSwatch('Primary', _previewPrimary, _previewOnPrimary),
                _buildColorSwatch(
                  'Secondary',
                  _previewSecondary,
                  Colors.white,
                ),
                _buildColorSwatch('Surface', _previewSurface, _previewOnSurface),
                _buildColorSwatch(
                  'Background',
                  _previewBackground,
                  _previewOnSurface,
                ),
                _buildColorSwatch(
                  'On Primary',
                  _previewOnPrimary,
                  _previewPrimary,
                ),
                _buildColorSwatch(
                  'On Surface',
                  _previewOnSurface,
                  _previewSurface,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Sample UI Elements
            Text(
              'Sample UI Elements',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),

            // Buttons
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                FilledButton.icon(
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Filled Button'),
                  onPressed: () {},
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Outlined Button'),
                  onPressed: () {},
                ),
                TextButton.icon(
                  icon: const Icon(Icons.favorite),
                  label: const Text('Text Button'),
                  onPressed: () {},
                ),
                IconButton.filled(
                  icon: const Icon(Icons.favorite),
                  onPressed: () {},
                  tooltip: 'Favorite',
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Song Card
            Card(
              elevation: 2,
              color: _previewSurface,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: _previewPrimary,
                          child: Icon(
                            Icons.music_note,
                            color: _previewOnPrimary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Sample Song Title',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: _previewOnSurface,
                                ),
                              ),
                              Text(
                                'Sample Artist',
                                style: TextStyle(
                                  color: _previewOnSurface.withValues(
                                    alpha: 0.7,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.more_vert,
                            color: _previewOnSurface.withValues(alpha: 0.7),
                          ),
                          onPressed: () {},
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    LinearProgressIndicator(
                      value: 0.6,
                      backgroundColor: _previewOnSurface.withValues(alpha: 0.2),
                      valueColor: AlwaysStoppedAnimation(_previewPrimary),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Text Field
            TextField(
              decoration: InputDecoration(
                labelText: 'Search...',
                hintText: 'Search songs, artists...',
                prefixIcon: Icon(
                  Icons.search,
                  color: _previewOnSurface.withValues(alpha: 0.5),
                ),
                filled: true,
                fillColor: _previewSurface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: _previewPrimary, width: 2),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Slider
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Volume',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                const SizedBox(height: 8),
                Slider(
                  value: 0.7,
                  onChanged: (_) {},
                  activeColor: _previewPrimary,
                  inactiveColor: _previewPrimary.withValues(alpha: 0.3),
                  thumbColor: _previewPrimary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorSwatch(String label, Color color, Color onColor) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Text(
              '#${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}',
              style: TextStyle(
                color: onColor,
                fontSize: 8,
                fontWeight: FontWeight.w600,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildColorPreviewRow(String label, Color color) {
    return Material(
      color: Colors.transparent,
      child: ListTile(
        dense: true,
        title: Text(label),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '#${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}',
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ),
      ),
    );
  }
}

/// Simple color picker dialog
class _ColorPickerDialog extends StatefulWidget {
  final Color initialColor;

  const _ColorPickerDialog({required this.initialColor});

  @override
  State<_ColorPickerDialog> createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<_ColorPickerDialog> {
  late Color _selectedColor;

  @override
  void initState() {
    super.initState();
    _selectedColor = widget.initialColor;
  }

  @override
  Widget build(BuildContext context) {
    final presetColors = [
      const Color(0xFF1DB954), // Spotify Green
      const Color(0xFF1E88E5), // Blue
      const Color(0xFFE53935), // Red
      const Color(0xFF8E24AA), // Purple
      const Color(0xFFFB8C00), // Orange
      const Color(0xFF00897B), // Teal
      const Color(0xFFD81B60), // Pink
      const Color(0xFF3949AB), // Indigo
      const Color(0xFF43A047), // Green
      const Color(0xFF6D4C41), // Brown
      const Color(0xFFFDD835), // Yellow
      const Color(0xFF757575), // Grey
    ];

    return AlertDialog(
      title: const Text('Pick a Color'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Current color preview
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: _selectedColor,
              shape: BoxShape.circle,
              border: Border.all(
                color: Theme.of(context).dividerColor,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: _selectedColor.withValues(alpha: 0.4),
                  blurRadius: 16,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: Center(
              child: Text(
                '#${_selectedColor.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}',
                style: TextStyle(
                  color: _selectedColor.computeLuminance() > 0.5
                      ? Colors.black
                      : Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Preset colors
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: presetColors.map((color) {
              final isSelected = color == _selectedColor;
              return GestureDetector(
                onTap: () => setState(() => _selectedColor = color),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: isSelected
                        ? Border.all(
                            color: Theme.of(context).colorScheme.primary,
                            width: 3,
                          )
                        : null,
                  ),
                  child: isSelected
                      ? Icon(
                          Icons.check,
                          size: 18,
                          color: color.computeLuminance() > 0.5
                              ? Colors.black
                              : Colors.white,
                        )
                      : null,
                ),
              );
            }).toList(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _selectedColor),
          child: const Text('Select'),
        ),
      ],
    );
  }
}