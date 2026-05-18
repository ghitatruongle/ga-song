import 'package:flutter/material.dart';

import '../../core/cover_art_repository.dart';
import '../../core/service_locator.dart';
import 'package:ga_song/models/song.dart';

class CoverArtImage extends StatefulWidget {
  const CoverArtImage({
    super.key,
    required this.song,
    required this.fallbackBuilder,
    this.cacheWidth,
    this.cacheHeight,
    this.fit = BoxFit.cover,
    this.filterQuality = FilterQuality.medium,
  });

  final Song song;
  final WidgetBuilder fallbackBuilder;
  final int? cacheWidth;
  final int? cacheHeight;
  final BoxFit fit;
  final FilterQuality filterQuality;

  @override
  State<CoverArtImage> createState() => _CoverArtImageState();
}

class _CoverArtImageState extends State<CoverArtImage> {
  final CoverArtRepository _repository = sl<CoverArtRepository>();
  CoverArtEntry? _entry;
  Object? _requestToken;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  @override
  void didUpdateWidget(covariant CoverArtImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.song.fileName != widget.song.fileName ||
        oldWidget.cacheWidth != widget.cacheWidth ||
        oldWidget.cacheHeight != widget.cacheHeight) {
      _resolve();
    }
  }

  Future<void> _resolve() async {
    final cached = _repository.getCachedEntry(widget.song.fileName);
    if (cached != null) {
      setState(() {
        _entry = cached;
      });
      return;
    }

    final token = Object();
    _requestToken = token;
    
    // C5 fix: Added try-catch to handle async resolve errors gracefully
    try {
      final entry = await _repository.resolveEntry(widget.song);
      if (!mounted || _requestToken != token) {
        return;
      }

      setState(() {
        _entry = entry;
      });
    } catch (e) {
      debugPrint('Failed to resolve cover art for ${widget.song.fileName}: $e');
      if (!mounted || _requestToken != token) return;
      setState(() {
        _entry = CoverArtEntry(
          fileName: widget.song.fileName,
          imagePath: '',
          exists: false,
          isAsset: false,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final entry = _entry ?? _repository.getCachedEntry(widget.song.fileName);
    final provider = _repository.getCachedProvider(
      widget.song.fileName,
      cacheWidth: widget.cacheWidth,
      cacheHeight: widget.cacheHeight,
    );

    if (entry == null || !entry.hasCover || provider == null) {
      return widget.fallbackBuilder(context);
    }

    return Image(
      image: provider,
      fit: widget.fit,
      filterQuality: widget.filterQuality,
      gaplessPlayback: true,
      errorBuilder: (context, error, stackTrace) {
        debugPrint('Image rendering failed for ${widget.song.fileName}: $error');
        return widget.fallbackBuilder(context);
      },
    );
  }
}
