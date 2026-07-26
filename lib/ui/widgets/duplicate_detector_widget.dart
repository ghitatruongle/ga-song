import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/song.dart';
import '../../providers/service_providers.dart';
import '../../core/motion/app_motion.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme_utils.dart';
import '../utils/animation_utils.dart';
import '../utils/theme_helpers.dart';

/// Widget that detects and manages duplicate songs in the library.
///
/// Finds songs with the same (name, artist) combination or same fileName,
/// and allows the user to remove duplicates while keeping the newest.
class DuplicateDetectorWidget extends ConsumerStatefulWidget {
  const DuplicateDetectorWidget({super.key});

  static Future<void> show(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (context) => const Dialog(child: DuplicateDetectorWidget()),
    );
  }

  @override
  ConsumerState<DuplicateDetectorWidget> createState() =>
      _DuplicateDetectorWidgetState();
}

class _DuplicateDetectorWidgetState
    extends ConsumerState<DuplicateDetectorWidget> {
  List<List<Song>> _duplicateGroups = [];
  final Set<int> _selectedForDeletion = {};
  bool _isLoading = true;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _findDuplicates();
  }

  Future<void> _findDuplicates() async {
    final db = ref.read(databaseServiceProvider);
    final songs = await db.getAllSongs();

    // Group by (name, artist) combination
    final Map<String, List<Song>> groups = {};
    for (final song in songs) {
      if (song.isBuiltIn) continue; // Skip built-in songs
      final key =
          '${song.name.toLowerCase()}|${song.artist?.toLowerCase() ?? ''}';
      groups.putIfAbsent(key, () => []).add(song);
    }

    // Filter to only groups with duplicates
    final duplicates = groups.values.where((g) => g.length > 1).toList();

    // Sort each group by dateAdded (newest first) so we can recommend keeping the first
    for (final group in duplicates) {
      group.sort((a, b) {
        final aDate = a.dateAdded ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = b.dateAdded ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate); // Newest first
      });
    }

    setState(() {
      _duplicateGroups = duplicates;
      _isLoading = false;
    });
  }

  Future<void> _deleteSelected() async {
    if (_selectedForDeletion.isEmpty) return;

    setState(() => _isDeleting = true);

    final db = ref.read(databaseServiceProvider);

    for (final id in _selectedForDeletion) {
      final song = _duplicateGroups
          .expand((g) => g)
          .where((s) => s.id == id)
          .firstOrNull;
      if (song?.id != null) {
        await db.deleteSong(song!.id!);
      }
    }

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã xóa ${_selectedForDeletion.length} bài trùng'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final spacing = ThemeSpacing.of(context);
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
      child: Padding(
        padding: EdgeInsets.all(spacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Title
            Text(
              'Tìm bài trùng',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: context.adaptive,
              ),
            ),
            SizedBox(height: spacing.md),

            // Content
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _duplicateGroups.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            size: 64,
                            color: AppColors.success.withValues(alpha: 0.5),
                          ),
                          SizedBox(height: spacing.md),
                          Text(
                            'Không tìm thấy bài trùng',
                            style: TextStyle(
                              color: context.adaptive.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _duplicateGroups.length,
                      itemBuilder: (context, groupIndex) {
                        final group = _duplicateGroups[groupIndex];
                        return _DuplicateGroup(
                          songs: group,
                          selectedIds: _selectedForDeletion,
                          onToggle: (id, selected) {
                            setState(() {
                              if (selected) {
                                _selectedForDeletion.add(id);
                              } else {
                                _selectedForDeletion.remove(id);
                              }
                            });
                          },
                        );
                      },
                    ),
            ),

            // Actions
            if (!_isLoading && _duplicateGroups.isNotEmpty) ...[
              SizedBox(height: spacing.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Đóng'),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  FilledButton(
                    onPressed: _selectedForDeletion.isEmpty || _isDeleting
                        ? null
                        : _deleteSelected,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.danger,
                    ),
                    child: _isDeleting
                        ? const SizedBox(
                            width: AppSpacing.md,
                            height: AppSpacing.md,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text('Xóa ${_selectedForDeletion.length} bài'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DuplicateGroup extends StatefulWidget {
  final List<Song> songs;
  final Set<int> selectedIds;
  final Function(int id, bool selected) onToggle;

  const _DuplicateGroup({
    required this.songs,
    required this.selectedIds,
    required this.onToggle,
  });

  @override
  State<_DuplicateGroup> createState() => _DuplicateGroupState();
}

class _DuplicateGroupState extends State<_DuplicateGroup> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final spacing = ThemeSpacing.of(context);
    final radius = ThemeRadius.of(context);
    final groupBg = AppColors.adaptive(
      context,
      dark: AppColors.darkSurface,
      light: AppColors.lightSurface2,
    );
    final groupBorder = AppColors.adaptive(
      context,
      dark: AppColors.darkSurface2,
      light: AppColors.lightBorder,
    );
    final dividerColor = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.06);

    final animations = animationsEnabled(context);

    return AnimatedContainer(
      duration: animations ? AppDurations.short : Duration.zero,
      curve: AppCurves.decelerate,
      transform: Matrix4.identity()
        ..scaleByDouble(
          _isHovered ? 1.01 : 1.0,
          _isHovered ? 1.01 : 1.0,
          1.0,
          1.0,
        ),
      margin: EdgeInsets.only(bottom: spacing.sm + spacing.xxs),
      decoration: BoxDecoration(
        color: groupBg,
        borderRadius: radius.circular(),
        border: Border.all(
          color: _isHovered
              ? groupBorder.withValues(alpha: 1.0)
              : groupBorder.withValues(alpha: 0.7),
          width: _isHovered ? 1.5 : 1.0,
        ),
        boxShadow: _isHovered
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: MouseRegion(
        onEnter: (_) {
          if (animations) setState(() => _isHovered = true);
        },
        onExit: (_) {
          if (animations) setState(() => _isHovered = false);
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Group header
            Padding(
              padding: EdgeInsets.all(spacing.sm + spacing.xxs),
              child: Text(
                '${widget.songs.first.name} - ${widget.songs.first.artist ?? "Unknown"}',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: context.adaptive,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Songs in group
            ...widget.songs.asMap().entries.map((entry) {
              final index = entry.key;
              final song = entry.value;
              final isSelected = widget.selectedIds.contains(song.id);
              final isRecommended =
                  index == 0; // First is newest (keep this one)

              return Container(
                padding: EdgeInsets.symmetric(
                  horizontal: spacing.sm + spacing.xxs,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: dividerColor)),
                ),
                child: Row(
                  children: [
                    // Checkbox
                    if (!isRecommended)
                      Checkbox(
                        value: isSelected,
                        onChanged: (value) {
                          if (song.id != null) {
                            widget.onToggle(song.id!, value ?? false);
                          }
                        },
                      )
                    else
                      SizedBox(width: spacing.sm + spacing.md + spacing.sm),

                    const SizedBox(width: AppSpacing.sm),

                    // Song info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              if (isRecommended)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.sm - 2,
                                    vertical: AppSpacing.xxs,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.success.withValues(
                                      alpha: 0.2,
                                    ),
                                    borderRadius: BorderRadius.circular(
                                      AppRadius.sm - 4,
                                    ),
                                  ),
                                  child: const Text(
                                    'GIỮ LẠI',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.success,
                                    ),
                                  ),
                                ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Text(
                                  song.fileName,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: context.adaptive.withValues(
                                      alpha: 0.5,
                                    ),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          if (song.dateAdded != null)
                            Text(
                              'Thêm: ${song.dateAdded!.day}/${song.dateAdded!.month}/${song.dateAdded!.year}',
                              style: TextStyle(
                                fontSize: 11,
                                color: context.adaptive.withValues(alpha: 0.4),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
