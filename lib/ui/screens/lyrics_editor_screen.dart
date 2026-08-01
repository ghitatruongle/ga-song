/// Lyrics Editor Widget with Inline Editing and LRCLIB Auto-Fetch
///
/// Features:
/// - Inline text editing with syntax highlighting for LRC format
/// - Real-time preview of synced lyrics
/// - LRCLIB search and auto-fetch
/// - Synced lyrics generation from plain text
/// - Save to database

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/audio/lyric_parser.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme_utils.dart';
import '../../models/song.dart';
import '../../providers/lyric_provider.dart';
import '../../providers/lyrics_editor_provider.dart';
import '../../providers/service_providers.dart';
import '../utils/haptic_helper.dart';
import '../widgets/cover_art_image.dart';

/// Main Lyrics Editor Screen
class LyricsEditorScreen extends ConsumerStatefulWidget {
  final Song? song;
  final String? initialPlainLyrics;
  final String? initialSyncedLyrics;

  const LyricsEditorScreen({
    super.key,
    this.song,
    this.initialPlainLyrics,
    this.initialSyncedLyrics,
  });

  @override
  ConsumerState<LyricsEditorScreen> createState() => _LyricsEditorScreenState();
}

class _LyricsEditorScreenState extends ConsumerState<LyricsEditorScreen> {
  late final TextEditingController _plainController;
  late final TextEditingController _syncedController;
  late final ScrollController _plainScrollController;
  late final ScrollController _syncedScrollController;
  bool _syncedScrollSync = true;

  @override
  void initState() {
    super.initState();
    _plainController = TextEditingController(
      text: widget.initialPlainLyrics ?? '',
    );
    _syncedController = TextEditingController(
      text: widget.initialSyncedLyrics ?? '',
    );
    _plainScrollController = ScrollController();
    _syncedScrollController = ScrollController();

    // Sync scroll between editors
    _plainScrollController.addListener(_syncScroll);
    _syncedScrollController.addListener(_syncScroll);

    // Initialize editor state
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(lyricsEditorProvider.notifier).resetForSong(
        initialPlain: widget.initialPlainLyrics,
        initialSynced: widget.initialSyncedLyrics,
      );

      // Auto-search if song info available
      if (widget.song != null) {
        ref.read(lyricsEditorProvider.notifier).searchLyrics(
          title: widget.song!.name,
          artist: widget.song!.artist,
          album: widget.song!.album,
        );
      }
    });
  }

  @override
  void dispose() {
    _plainController.dispose();
    _syncedController.dispose();
    _plainScrollController.dispose();
    _syncedScrollController.dispose();
    super.dispose();
  }

  void _syncScroll() {
    if (!_syncedScrollSync) return;

    if (_plainScrollController.hasClients && _syncedScrollController.hasClients) {
      final plainOffset = _plainScrollController.offset;
      final plainMax = _plainScrollController.position.maxScrollExtent;
      final syncedMax = _syncedScrollController.position.maxScrollExtent;

      if (plainMax > 0 && syncedMax > 0) {
        final ratio = plainOffset / plainMax;
        _syncedScrollController.jumpTo(syncedMax * ratio);
      }
    }
  }

  void _toggleSyncScroll(bool value) {
    setState(() => _syncedScrollSync = value);
  }

  @override
  Widget build(BuildContext context) {
    final editorState = ref.watch(lyricsEditorProvider);
    final editorNotifier = ref.read(lyricsEditorProvider.notifier);
    final isDark = context.isDark;
    final accentColor = Theme.of(context).colorScheme.primary;
    final textColor = context.adaptive;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trình soạn thảo lời bài hát'),
        actions: [
          IconButton(
            icon: Icon(editorState.isEditing ? Icons.edit_off : Icons.edit),
            onPressed: () {
              ref.read(lyricsEditorProvider.notifier).startEditing();
            },
            tooltip: editorState.isEditing ? 'Xem trước' : 'Chỉnh sửa',
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _showSearchDialog,
            tooltip: 'Tìm lời bài hát (LRCLIB)',
          ),
          IconButton(
            icon: const Icon(Icons.auto_fix_high),
            onPressed: () => ref.read(lyricsEditorProvider.notifier).generateSyncedFromPlain(),
            tooltip: 'Tạo lời bài hát có thời gian từ văn bản thuần',
          ),
          if (widget.song != null)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: () => _saveLyrics(),
              tooltip: 'Lưu lời bài hát',
            ),
        ],
      ),
      body: Column(
        children: [
          // Song info header
          if (widget.song != null) _buildSongHeader(),

          // Error message
          if (editorState.errorMessage != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: Colors.red.withValues(alpha: 0.1),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      editorState.errorMessage!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => ref.read(lyricsEditorProvider.notifier).clearError(),
                  ),
                ],
              ),
            ),

          // Search results
          if (editorState.searchResults.isNotEmpty) _buildSearchResults(),

          // Main editor area
          Expanded(
            child: Row(
              children: [
                // Plain text editor
                Expanded(
                  child: _buildEditorPane(
                    label: 'Văn bản thuần',
                    controller: _plainController,
                    scrollController: _plainScrollController,
                    isEditing: editorState.isEditing,
                    onChanged: (text) => ref.read(lyricsEditorProvider.notifier).updatePlainLyrics(text),
                    hintText: 'Nhập lời bài hát ở đây...\nMỗi dòng một câu',
                  ),
                ),

                // Vertical divider
                VerticalDivider(
                  width: 1,
                  thickness: 1,
                  color: context.adaptive.withValues(alpha: 0.2),
                ),

                // Synced lyrics editor
                Expanded(
                  child: _buildEditorPane(
                    label: 'Lời bài hát có thời gian (LRC)',
                    controller: _syncedController,
                    scrollController: _syncedScrollController,
                    isEditing: editorState.isEditing,
                    onChanged: (text) => ref.read(lyricsEditorProvider.notifier).updateSyncedLyrics(text),
                    hintText: '[mm:ss.xx]Dòng lời bài hát\n[mm:ss.xx]Dòng tiếp theo',
                    showFormatHelp: true,
                  ),
                ),
              ],
            ),
          ),

          // Bottom toolbar
          _buildBottomToolbar(),
        ],
      ),
    );
  }

  Widget _buildSongHeader() {
    final song = widget.song!;
    final isDark = context.isDark;
    final textColor = context.adaptive;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface2 : AppColors.lightSurface2,
        border: Border(
          bottom: BorderSide(
            color: context.adaptive.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CoverArtImage(
              song: widget.song!,
              cacheWidth: 64,
              cacheHeight: 64,
              fallbackBuilder: (context) => Container(
                width: 56,
                height: 56,
                color: Theme.of(context).cardColor.withValues(alpha: 0.2),
                child: Icon(
                  Icons.music_note_rounded,
                  color: context.adaptive.withValues(alpha: 0.3),
                  size: 24,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  song.name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: context.adaptive,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  song.artist ?? 'Unknown Artist',
                  style: TextStyle(
                    fontSize: 13,
                    color: context.adaptive.withValues(alpha: 0.6),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Sync toggle
          Row(
            children: [
              const Text('Đồng bộ cuộn'),
              Switch(
                value: _syncedScrollSync,
                onChanged: _toggleSyncScroll,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEditorPane({
    required String label,
    required TextEditingController controller,
    required ScrollController scrollController,
    required bool isEditing,
    required ValueChanged<String> onChanged,
    required String hintText,
    bool showFormatHelp = false,
  }) {
    final isDark = context.isDark;
    final textColor = context.adaptive;

    return Container(
      color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface2 : AppColors.lightSurface2,
              border: Border(
                bottom: BorderSide(
                  color: context.adaptive.withValues(alpha: 0.1),
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: context.adaptive.withValues(alpha: 0.8),
                    ),
                  ),
                ),
                if (showFormatHelp)
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.help_outline, size: 20),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'format',
                        child: Text('Định dạng LRC: [mm:ss.xx]Dòng lời'),
                      ),
                      const PopupMenuItem(
                        value: 'enhanced',
                        child: Text('Nâng cao: [mm:ss.xx]Từ[mm:ss.xx]Từ...'),
                      ),
                      const PopupMenuItem(
                        value: 'shortcuts',
                        child: Text('Ctrl+S: Lưu | Ctrl+G: Tạo LRC | Ctrl+F: Tìm kiếm'),
                      ),
                    ],
                    onSelected: (value) {
                      if (value == 'format') {
                        _showFormatHelp();
                      }
                    },
                  ),
              ],
            ),
          ),
          // Editor
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                controller: controller,
                scrollController: scrollController,
                readOnly: !isEditing,
                maxLines: null,
                expands: true,
                keyboardType: TextInputType.multiline,
                textAlignVertical: TextAlignVertical.top,
                style: TextStyle(
                  fontSize: 14,
                  fontFamily: 'monospace',
                  height: 1.5,
                  color: context.adaptive,
                ),
                decoration: InputDecoration(
                  hintText: hintText,
                  hintStyle: TextStyle(
                    fontSize: 14,
                    fontFamily: 'monospace',
                    color: context.adaptive.withValues(alpha: 0.3),
                  ),
                  border: InputBorder.none,
                  filled: true,
                  fillColor: isDark
                      ? AppColors.darkSurface2
                      : AppColors.lightSurface2,
                ),
                onChanged: onChanged,
              ),
            ),
          ),
          if (!isEditing)
            Container(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.lock_outline,
                    size: 16,
                    color: context.adaptive.withValues(alpha: 0.5),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Chế độ xem trước - nhấn nút sửa để chỉnh sửa',
                      style: TextStyle(
                        fontSize: 12,
                        color: context.adaptive.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                ],
              ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    final editorState = ref.watch(lyricsEditorProvider);
    final notifier = ref.read(lyricsEditorProvider.notifier);
    final isDark = context.isDark;
    final accentColor = Theme.of(context).colorScheme.primary;

    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface2 : AppColors.lightSurface2,
        border: Border(
          bottom: BorderSide(
            color: context.adaptive.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(Icons.search, size: 18, color: context.adaptive.withValues(alpha: 0.6)),
                const SizedBox(width: 8),
                Text(
                  'Kết quả tìm kiếm (${editorState.searchResults.length})',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: context.adaptive,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => notifier.clearSearch(),
                  child: const Text('Đóng'),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: editorState.searchResults.length,
              itemBuilder: (context, index) {
                final result = editorState.searchResults[index];
                final isSelected = editorState.selectedResultIndex == index;

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
                      : null,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: isSelected
                        ? BorderSide(color: Theme.of(context).colorScheme.primary, width: 2)
                        : BorderSide.none,
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => notifier.selectResult(index),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              if (result.hasSyncedLyrics)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'LRC',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                ),
                              if (result.hasPlainLyrics) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'Văn bản',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.orange,
                                    ),
                                  ),
                                ),
                            ],
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            result.trackName,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: context.adaptive,
                            ),
                          ),
                          Text(
                            result.artistName,
                            style: TextStyle(
                              fontSize: 12,
                              color: context.adaptive.withValues(alpha: 0.6),
                            ),
                          ),
                          if (result.albumName != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Album: ${result.albumName}',
                              style: TextStyle(
                                fontSize: 11,
                                color: context.adaptive.withValues(alpha: 0.5),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (editorState.selectedResultIndex != null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  icon: const Icon(Icons.check),
                  label: const Text('Áp dụng kết quả này'),
                  onPressed: () => notifier.applySelectedResult(),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBottomToolbar() {
    final editorState = ref.watch(lyricsEditorProvider);
    final notifier = ref.read(lyricsEditorProvider.notifier);
    final isDark = context.isDark;
    final accentColor = Theme.of(context).colorScheme.primary;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface2 : AppColors.lightSurface2,
        border: Border(
          top: BorderSide(
            color: context.adaptive.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        alignment: WrapAlignment.center,
        children: [
          if (editorState.isEditing) ...[
            OutlinedButton.icon(
              icon: const Icon(Icons.auto_fix_high),
              label: const Text('Tạo LRC từ văn bản'),
              onPressed: () => notifier.generateSyncedFromPlain(),
            ),
            OutlinedButton.icon(
              icon: const Icon(Icons.format_align_left),
              label: const Text('Kiểm tra định dạng'),
              onPressed: () {
                final valid = notifier.validateSyncedFormat();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      valid ? 'Định dạng LRC hợp lệ' : 'Định dạng LRC không hợp lệ',
                    ),
                    backgroundColor: valid ? Colors.green : Colors.red,
                  ),
                );
              },
            ),
            FilledButton.icon(
              icon: const Icon(Icons.preview),
              label: const Text('Xem trước'),
              onPressed: () => notifier.stopEditing(),
            ),
          ] else ...[
            FilledButton.icon(
              icon: const Icon(Icons.edit),
              label: const Text('Chỉnh sửa'),
              onPressed: () => notifier.startEditing(),
            ),
            if (editorState.syncedLyrics.isNotEmpty)
              OutlinedButton.icon(
                icon: const Icon(Icons.play_arrow),
                label: const Text('Xem trước lời bài hát'),
                onPressed: () => _showPreviewDialog(),
              ),
          ],
          if (widget.song != null)
            FilledButton.tonalIcon(
              icon: const Icon(Icons.save),
              label: const Text('Lưu vào cơ sở dữ liệu'),
              onPressed: () => _saveLyrics(),
            ),
        ],
      ),
    );
  }

  void _showSearchDialog() {
    final notifier = ref.read(lyricsEditorProvider.notifier);
    final titleController = TextEditingController(text: widget.song?.name ?? '');
    final artistController = TextEditingController(text: widget.song?.artist ?? '');
    final albumController = TextEditingController(text: widget.song?.album ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tìm lời bài hát (LRCLIB)'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Tên bài hát *',
                hintText: 'Nhập tên bài hát',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: artistController,
              decoration: const InputDecoration(
                labelText: 'Nghệ sĩ',
                hintText: 'Nhập tên nghệ sĩ',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: albumController,
              decoration: const InputDecoration(
                labelText: 'Album',
                hintText: 'Nhập tên album (tùy chọn)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () {
              if (titleController.text.trim().isEmpty) return;
              notifier.searchLyrics(
                title: titleController.text.trim(),
                artist: artistController.text.trim().isEmpty ? null : artistController.text.trim(),
                album: albumController.text.trim().isEmpty ? null : albumController.text.trim(),
              );
              Navigator.pop(context);
            },
            child: const Text('Tìm kiếm'),
          ),
        ],
      ),
    );
  }

  void _showFormatHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Định dạng LRC'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Định dạng LRC cơ bản:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const SelectableText(
                '[00:12.34]Dòng lời thứ nhất\n'
                '[00:15.67]Dòng lời thứ hai\n'
                '[00:18.90]Dòng lời thứ ba',
                style: TextStyle(fontFamily: 'monospace'),
              ),
              const SizedBox(height: 16),
              const Text(
                'Định dạng LRC nâng cao (karaoke từng từ):',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const SelectableText(
                '[00:12.34]Xin [00:12.50]chào [00:12.70]các [00:13.00]bạn\n'
                '[00:15.67]Hôm [00:15.80]nay [00:16.00]thời [00:16.20]tiết [00:16.40]đẹp',
                style: TextStyle(fontFamily: 'monospace'),
              ),
              const SizedBox(height: 16),
              const Text(
                'Lưu ý:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('• Thời gian: [phút:giây.số_ms] (số_ms có 2 hoặc 3 chữ số)'),
              const Text('• Mỗi timestamp phải ở đầu dòng hoặc giữa các từ'),
              const Text('• Dòng không có timestamp sẽ được bỏ qua'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  void _showPreviewDialog() {
    final editorState = ref.watch(lyricsEditorProvider);
    final lyrics = LyricParser.parse(editorState.syncedLyrics);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xem trước lời bài hát'),
        content: SizedBox(
          width: 400,
          height: 400,
          child: ListView.builder(
            itemCount: lyrics.length,
            itemBuilder: (context, index) {
              final line = lyrics[index];
              return ListTile(
                title: Text(
                  line.text,
                  style: TextStyle(
                    fontSize: 14,
                    color: context.adaptive,
                  ),
                ),
                subtitle: Text(
                  _formatTime(line.startTime),
                  style: TextStyle(
                    fontSize: 12,
                    color: context.adaptive.withValues(alpha: 0.5),
                    fontFamily: 'monospace',
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveLyrics() async {
    if (widget.song == null) return;

    final notifier = ref.read(lyricsEditorProvider.notifier);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    notifier.setLoading(true);

    try {
      await notifier.saveLyrics(
        songId: widget.song!.id!,
        title: widget.song!.name,
        artist: widget.song!.artist,
      );

      notifier.setLoading(false);
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Đã lưu lời bài hát thành công'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      notifier.setLoading(false);
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Lưu thất bại: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatTime(Duration d) {
    final mm = d.inMinutes.toString().padLeft(2, '0');
    final ss = (d.inSeconds % 60).toString().padLeft(2, '0');
    final ms = ((d.inMilliseconds % 1000) ~/ 10).toString().padLeft(2, '0');
    return '[$mm:$ss.$ms]';
  }
}