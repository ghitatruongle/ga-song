import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/cover_art_repository.dart';
import '../../core/logging/app_logger.dart';
import '../../providers/service_providers.dart';
import '../../models/song.dart';

class CoverArtImage extends ConsumerStatefulWidget {
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
  ConsumerState<CoverArtImage> createState() => _CoverArtImageState();
}

class _CoverArtImageState extends ConsumerState<CoverArtImage> {
  late final CoverArtRepository _repository = ref.read(
    coverArtRepositoryProvider,
  );
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
      AppLogger.w(
        'ui.cover_art_image',
        'resolve failed for ${widget.song.fileName}',
        error: e,
      );
      if (!mounted || _requestToken != token) return;
      setState(() {
        _entry = CoverArtEntry(
          fileName: widget.song.fileName,
          imagePath: '',
          exists: false,
          isAsset: false,
          tier: CoverArtCacheTier.memory,
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

    return RepaintBoundary(
      child: Image(
        image: provider,
        fit: widget.fit,
        filterQuality: widget.filterQuality,
        gaplessPlayback: true,
        errorBuilder: (context, error, stackTrace) {
          AppLogger.w(
            'ui.cover_art_image',
            'rendering failed for ${widget.song.fileName}',
            error: error,
          );
          return widget.fallbackBuilder(context);
        },
      ),
    );
  }
}
