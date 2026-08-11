import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audiotags/audiotags.dart';

import '../../models/song.dart';
import '../../providers/service_providers.dart';
import '../../core/theme_utils.dart';
import '../../core/theme/tokens.dart';
import '../../core/logging/app_logger.dart';

/// Dialog for editing song metadata (tags).
///
/// Reads existing tags from the audio file, allows editing,
/// and saves changes back to both the file and the database.
class TagEditorDialog extends ConsumerStatefulWidget {
  final Song song;

  const TagEditorDialog({super.key, required this.song});

  /// Show the tag editor dialog
  static Future<void> show(final BuildContext context, final Song song) async {
    await showDialog(
      context: context,
      builder: (final context) => TagEditorDialog(song: song),
    );
  }

  @override
  ConsumerState<TagEditorDialog> createState() => _TagEditorDialogState();
}

class _TagEditorDialogState extends ConsumerState<TagEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _artistController;
  late TextEditingController _albumController;
  late TextEditingController _genreController;
  late TextEditingController _yearController;

  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;
  Tag? _originalTag;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.song.name);
    _artistController = TextEditingController(text: widget.song.artist ?? '');
    _albumController = TextEditingController(text: widget.song.album ?? '');
    _genreController = TextEditingController(text: widget.song.genre ?? '');
    _yearController = TextEditingController(
      text: widget.song.year?.toString() ?? '',
    );
    _loadTags();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _artistController.dispose();
    _albumController.dispose();
    _genreController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  Future<void> _loadTags() async {
    try {
      final tag = await AudioTags.read(widget.song.sourcePath);
      if (!mounted) return; // dialog closed while reading tags
      setState(() {
        _originalTag = tag;
        _isLoading = false;
        // Update controllers with file tags if available
        if (tag != null) {
          _titleController.text = tag.title ?? widget.song.name;
          _artistController.text = tag.trackArtist ?? widget.song.artist ?? '';
          _albumController.text = tag.album ?? widget.song.album ?? '';
          _genreController.text = tag.genre ?? widget.song.genre ?? '';
          _yearController.text =
              (tag.year ?? widget.song.year)?.toString() ?? '';
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Không thể đọc tags: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final newTitle = _titleController.text.trim();
      final newArtist = _artistController.text.trim();
      final newAlbum = _albumController.text.trim();
      final newGenre = _genreController.text.trim();
      final newYear = int.tryParse(_yearController.text.trim());

      // Write tags to file
      if (!widget.song.isBuiltIn) {
        final tag = Tag(
          title: newTitle,
          trackArtist: newArtist.isNotEmpty ? newArtist : null,
          album: newAlbum.isNotEmpty ? newAlbum : null,
          genre: newGenre.isNotEmpty ? newGenre : null,
          year: newYear,
          pictures: _originalTag?.pictures ?? [],
        );

        try {
          await AudioTags.write(widget.song.sourcePath, tag);
        } catch (e) {
          AppLogger.w('tag_editor.dialog', 'write tags failed', error: e);
          // Continue even if file write fails - we can still update DB
        }
      }

      // Update song in database
      final db = ref.read(databaseServiceProvider);
      final updatedSong = widget.song.copyWith(
        name: newTitle,
        artist: newArtist.isNotEmpty ? newArtist : null,
        album: newAlbum.isNotEmpty ? newAlbum : null,
        genre: newGenre.isNotEmpty ? newGenre : null,
        year: newYear,
      );
      await db.putSong(updatedSong);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Đã lưu tags')));
      }
    } catch (e) {
      setState(() {
        _error = 'Lỗi lưu tags: $e';
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(final BuildContext context) {
    final isDark = context.isDark;

    return AlertDialog(
      title: const Text('Chỉnh sửa Tags'),
      content: SizedBox(
        width: 400,
        child: _isLoading
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              )
            : _error != null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Text(_error!, textAlign: TextAlign.center),
                    ],
                  ),
                ),
              )
            : Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Cover art preview
                      if (_originalTag?.pictures.isNotEmpty ?? false)
                        Center(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.memory(
                              _originalTag!.pictures.first.bytes,
                              width: 120,
                              height: 120,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => Container(
                                width: 120,
                                height: 120,
                                color: isDark
                                    ? AppColors.darkSurface2
                                    : AppColors.lightSidebarHover,
                                child: const Icon(Icons.music_note, size: 48),
                              ),
                            ),
                          ),
                        ),
                      if (_originalTag?.pictures.isNotEmpty ?? false)
                        const SizedBox(height: 16),

                      // Title
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Tiêu đề',
                          prefixIcon: Icon(Icons.title),
                        ),
                        validator: (final value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Vui lòng nhập tiêu đề';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      // Artist
                      TextFormField(
                        controller: _artistController,
                        decoration: const InputDecoration(
                          labelText: 'Nghệ sĩ',
                          prefixIcon: Icon(Icons.person),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Album
                      TextFormField(
                        controller: _albumController,
                        decoration: const InputDecoration(
                          labelText: 'Album',
                          prefixIcon: Icon(Icons.album),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Genre + Year (side by side)
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _genreController,
                              decoration: const InputDecoration(
                                labelText: 'Thể loại',
                                prefixIcon: Icon(Icons.category),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _yearController,
                              decoration: const InputDecoration(
                                labelText: 'Năm',
                                prefixIcon: Icon(Icons.calendar_today),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Hủy'),
        ),
        FilledButton(
          onPressed: _isLoading || _isSaving ? null : _save,
          child: _isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Lưu'),
        ),
      ],
    );
  }
}
