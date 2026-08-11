/// Queue Management Widget for Now Playing Screen
///
/// Provides drag-drop reordering, swipe-to-delete, and multi-select
/// for the playback queue.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/service_providers.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme_utils.dart';
import '../../models/song.dart';

/// Queue management sheet that slides up from bottom
class QueueManagementSheet extends ConsumerStatefulWidget {
  final VoidCallback? onClose;

  const QueueManagementSheet({super.key, this.onClose});

  @override
  ConsumerState<QueueManagementSheet> createState() =>
      _QueueManagementSheetState();
}

class _QueueManagementSheetState extends ConsumerState<QueueManagementSheet> {
  bool _isMultiSelectMode = false;
  final Set<int> _selectedIndices = {};
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _toggleMultiSelect() {
    setState(() {
      _isMultiSelectMode = !_isMultiSelectMode;
      if (!_isMultiSelectMode) {
        _selectedIndices.clear();
      }
    });
  }

  void _toggleSelection(final int index) {
    setState(() {
      if (_selectedIndices.contains(index)) {
        _selectedIndices.remove(index);
      } else {
        _selectedIndices.add(index);
      }
    });
  }

  void _selectAll() {
    final playlist = ref.read(playlistServiceProvider);
    final currentIndex = playlist.currentIndex;
    setState(() {
      _selectedIndices.clear();
      for (int i = 0; i < playlist.playlist.length; i++) {
        if (i != currentIndex) {
          // Don't select currently playing
          _selectedIndices.add(i);
        }
      }
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedIndices.clear();
    });
  }

  void _removeSelected() {
    if (_selectedIndices.isEmpty) return;

    final playlist = ref.read(playlistServiceProvider);
    final indicesToRemove = _selectedIndices.toList()
      ..sort((final a, final b) => b.compareTo(a));

    for (final index in indicesToRemove) {
      if (index < playlist.playlist.length) {
        playlist.remove(index);
      }
    }

    setState(() {
      _selectedIndices.clear();
      _isMultiSelectMode = false;
    });
  }

  Future<void> _moveToTop() async {
    if (_selectedIndices.isEmpty) return;

    final playlist = ref.read(playlistServiceProvider);
    final indicesToMove = _selectedIndices.toList()..sort();

    // Move each selected song to the top, ascending order preserves
    // their relative order (upward moves don't shift items below).
    for (final index in indicesToMove) {
      if (index < playlist.playlist.length) {
        await playlist.reorderQueue(index, 0);
      }
    }

    setState(() {
      _selectedIndices.clear();
    });
  }

  Future<void> _moveToBottom() async {
    if (_selectedIndices.isEmpty) return;

    final playlist = ref.read(playlistServiceProvider);
    final indicesToMove = _selectedIndices.toList()..sort();

    // Each successful move to the end shifts the remaining selected
    // songs down by one, so track the current position accordingly.
    for (int i = 0; i < indicesToMove.length; i++) {
      final currentPos = indicesToMove[i] - i;
      if (currentPos < playlist.playlist.length) {
        await playlist.reorderQueue(currentPos, playlist.playlist.length - 1);
      }
    }

    setState(() {
      _selectedIndices.clear();
    });
  }

  @override
  Widget build(final BuildContext context) {
    final playlist = ref.watch(playlistServiceProvider);
    final currentIndex = playlist.currentIndex;
    final isDark = context.isDark;
    final textColor = context.adaptive;
    final accentColor = Theme.of(context).colorScheme.primary;

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.3,
      maxChildSize: 0.95,
      expand: false,
      builder: (final context, final scrollController) => DecoratedBox(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: textColor.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Hàng đợi phát (${playlist.playlist.length})',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                  ),
                  if (!_isMultiSelectMode) ...[
                    if (playlist.playlist.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.checklist_rounded),
                        onPressed: _toggleMultiSelect,
                        tooltip: 'Chọn nhiều',
                      ),
                    IconButton(
                      icon: const Icon(Icons.clear_all_rounded),
                      onPressed: () {
                        playlist.clear();
                      },
                      tooltip: 'Xóa tất cả',
                    ),
                  ] else ...[
                    Text(
                      '${_selectedIndices.length} đã chọn',
                      style: TextStyle(
                        color: accentColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () {
                        _clearSelection();
                        _toggleMultiSelect();
                      },
                      tooltip: 'Hủy',
                    ),
                  ],
                ],
              ),
            ),

            // Multi-select toolbar
            if (_isMultiSelectMode && _selectedIndices.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.1),
                  border: Border(
                    bottom: BorderSide(
                      color: accentColor.withValues(alpha: 0.3),
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton.icon(
                      icon: const Icon(Icons.drag_indicator_rounded),
                      label: const Text('Lên đầu'),
                      onPressed: _moveToTop,
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.keyboard_arrow_down_rounded),
                      label: const Text('Đi cuối'),
                      onPressed: _moveToBottom,
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.delete_outline_rounded),
                      label: const Text('Xóa'),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      onPressed: _removeSelected,
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.check_rounded),
                      label: const Text('Chọn tất cả'),
                      onPressed: _selectAll,
                    ),
                  ],
                ),
              ),

            // Queue list
            Expanded(
              child: playlist.playlist.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.queue_music_rounded,
                            size: 64,
                            color: textColor.withValues(alpha: 0.3),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Hàng đợi trống',
                            style: TextStyle(
                              fontSize: 16,
                              color: textColor.withValues(alpha: 0.5),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Kéo thả bài hát vào đây hoặc nhấn "Thêm vào hàng đợi"',
                            style: TextStyle(
                              fontSize: 13,
                              color: textColor.withValues(alpha: 0.4),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : ReorderableListView.builder(
                      scrollController: scrollController,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: playlist.playlist.length,
                      onReorderItem: (final oldIndex, newIndex) {
                        ref
                            .read(playlistServiceProvider)
                            .reorderQueue(oldIndex, newIndex);
                      },
                      proxyDecorator:
                          (final child, final index, final animation) =>
                              Material(
                                elevation: 8,
                                color: Colors.transparent,
                                child: child,
                              ),
                      itemBuilder: (final context, final index) {
                        final song = playlist.playlist[index];
                        final isCurrent = index == currentIndex;
                        final isSelected = _selectedIndices.contains(index);

                        return _QueueItem(
                          key: ValueKey(song.fileName),
                          song: song,
                          index: index,
                          isCurrent: isCurrent,
                          isSelected: isSelected,
                          isMultiSelectMode: _isMultiSelectMode,
                          onTap: () => _isMultiSelectMode
                              ? _toggleSelection(index)
                              : null,
                          onPlay: () => ref
                              .read(playlistServiceProvider)
                              .playSongAt(index),
                          onRemove: () =>
                              ref.read(playlistServiceProvider).remove(index),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Individual queue item with drag handle, swipe-to-delete, and selection
class _QueueItem extends StatelessWidget {
  final Song song;
  final int index;
  final bool isCurrent;
  final bool isSelected;
  final bool isMultiSelectMode;
  final VoidCallback? onTap;
  final VoidCallback? onPlay;
  final VoidCallback? onRemove;

  const _QueueItem({
    super.key,
    required this.song,
    required this.index,
    required this.isCurrent,
    required this.isSelected,
    required this.isMultiSelectMode,
    this.onTap,
    this.onPlay,
    this.onRemove,
  });

  @override
  Widget build(final BuildContext context) {
    final isDark = context.isDark;
    final textColor = context.adaptive;
    final accentColor = Theme.of(context).colorScheme.primary;

    return Dismissible(
      key: ValueKey(song.fileName),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete_rounded, color: Colors.white, size: 24),
      ),
      confirmDismiss: (final direction) async => showDialog<bool>(
        context: context,
        builder: (final context) => AlertDialog(
          title: const Text('Xóa bài hát'),
          content: Text('Bạn có chắc muốn xóa "${song.name}" khỏi hàng đợi?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Xóa', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ),
      onDismissed: (final direction) {
        // Actually remove the song from the queue — an empty handler left
        // the item in the list (and caused "dismissed Dismissible still in
        // tree" debug crashes).
        onRemove?.call();
      },
      child: Material(
        color: isCurrent
            ? (isDark
                  ? accentColor.withValues(alpha: 0.12)
                  : accentColor.withValues(alpha: 0.08))
            : (isSelected
                  ? accentColor.withValues(alpha: 0.1)
                  : Colors.transparent),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          onLongPress: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                // Drag handle / Selection checkbox
                if (isMultiSelectMode)
                  Checkbox(
                    value: isSelected,
                    onChanged: (_) {},
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  )
                else
                  ReorderableDragStartListener(
                    index: index,
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Icon(
                        Icons.drag_indicator_rounded,
                        color: textColor.withValues(alpha: 0.4),
                        size: 20,
                      ),
                    ),
                  ),

                const SizedBox(width: 8),

                // Cover art
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 48,
                    height: 48,
                    child: _CoverArtSmall(song: song),
                  ),
                ),

                const SizedBox(width: 12),

                // Song info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              song.name,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: isCurrent
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: isCurrent ? accentColor : textColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isCurrent)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: accentColor.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'ĐANG PHÁT',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                  color: accentColor,
                                ),
                              ),
                            ),
                        ],
                      ),
                      Text(
                        song.artist ?? 'Unknown Artist',
                        style: TextStyle(
                          fontSize: 12,
                          color: textColor.withValues(alpha: 0.5),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 12),

                // Duration
                if (song.durationMs != null && song.durationMs! > 0)
                  Text(
                    _formatDuration(song.durationMs!),
                    style: TextStyle(
                      fontSize: 12,
                      color: textColor.withValues(alpha: 0.4),
                      fontFamily: 'monospace',
                    ),
                  ),

                // Play button for non-current songs
                if (!isCurrent && onPlay != null)
                  IconButton(
                    icon: Icon(
                      Icons.play_arrow_rounded,
                      color: textColor.withValues(alpha: 0.6),
                      size: 20,
                    ),
                    onPressed: onPlay,
                    tooltip: 'Phát bài này',
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDuration(final int durationMs) {
    final duration = Duration(milliseconds: durationMs);
    final minutes = duration.inMinutes;
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

/// Small cover art for queue items
class _CoverArtSmall extends ConsumerWidget {
  final Song song;

  const _CoverArtSmall({required this.song});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final repository = ref.watch(coverArtRepositoryProvider);
    final provider = repository.getCachedProvider(
      song.fileName,
      cacheWidth: 96,
      cacheHeight: 96,
    );

    if (provider == null) {
      return ColoredBox(
        color: context.isDark
            ? AppColors.darkSurface2
            : AppColors.lightSurface2,
        child: Icon(
          Icons.music_note_rounded,
          color: context.adaptive.withValues(alpha: 0.3),
          size: 20,
        ),
      );
    }

    return Image(image: provider, fit: BoxFit.cover, gaplessPlayback: true);
  }
}
