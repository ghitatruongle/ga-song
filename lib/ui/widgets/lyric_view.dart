import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/service_providers.dart';
import '../../providers/lyric_provider.dart';

/// Enhanced lyric view with karaoke-style effects.
///
/// Features:
/// - Gradient color on current line (accent → white)
/// - Fade effect on past/future lines
/// - Smooth scroll to current line
/// - Tap to seek
/// - Full-screen mode for KTV
class LyricView extends ConsumerStatefulWidget {
  final bool isFullScreen;
  const LyricView({super.key, this.isFullScreen = false});

  @override
  ConsumerState<LyricView> createState() => _LyricViewState();
}

class _LyricViewState extends ConsumerState<LyricView> {
  final ScrollController _scrollController = ScrollController();
  late final _audioEngine = ref.read(audioEngineServiceProvider);
  int _currentIndex = -1;

  @override
  void initState() {
    super.initState();
    _audioEngine.positionNotifier.addListener(_onPositionChanged);
  }

  @override
  void dispose() {
    _audioEngine.positionNotifier.removeListener(_onPositionChanged);
    _scrollController.dispose();
    super.dispose();
  }

  void _onPositionChanged() {
    final lyrics = ref.read(lyricProvider);
    if (lyrics.isEmpty) return;

    final currentPosition = _audioEngine.positionNotifier.value;
    
    // Find the current line
    int newIndex = -1;
    for (int i = 0; i < lyrics.length; i++) {
      if (currentPosition >= lyrics[i].startTime) {
        newIndex = i;
      } else {
        break;
      }
    }

    if (newIndex != _currentIndex && newIndex != -1) {
      if (mounted) {
        setState(() {
          _currentIndex = newIndex;
        });
        _scrollToCurrentIndex();
      }
    }
  }

  void _scrollToCurrentIndex() {
    if (!_scrollController.hasClients) return;
    
    // Approximate line height
    final lineHeight = widget.isFullScreen ? 70.0 : 48.0;
    final viewportHeight = MediaQuery.of(context).size.height;
    final offset = (_currentIndex * lineHeight) - (viewportHeight / 3);
    
    _scrollController.animateTo(
      offset.clamp(0.0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final lyrics = ref.watch(lyricProvider);
    final accentColor = Theme.of(context).colorScheme.primary;

    if (lyrics.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.lyrics_outlined,
              size: widget.isFullScreen ? 64 : 48,
              color: Colors.white.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Đang tìm lời bài hát...',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: widget.isFullScreen ? 20 : 14,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.symmetric(
        vertical: MediaQuery.of(context).size.height / 2.5,
        horizontal: 24,
      ),
      itemCount: lyrics.length,
      itemBuilder: (context, index) {
        final line = lyrics[index];
        final isActive = index == _currentIndex;
        final isPast = index < _currentIndex;
        final distance = (index - _currentIndex).abs();

        // Calculate opacity based on distance from current line
        double opacity;
        if (isActive) {
          opacity = 1.0;
        } else if (isPast) {
          opacity = (0.4 - (distance * 0.08)).clamp(0.1, 0.4);
        } else {
          opacity = (0.5 - (distance * 0.08)).clamp(0.15, 0.5);
        }

        return GestureDetector(
          onTap: () {
            _audioEngine.seek(line.startTime);
          },
          child: Container(
            height: widget.isFullScreen ? 70.0 : 48.0,
            alignment: Alignment.center,
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              style: TextStyle(
                color: isActive 
                    ? Colors.white 
                    : Colors.white.withValues(alpha: opacity),
                fontSize: widget.isFullScreen 
                    ? (isActive ? 40 : 26)
                    : (isActive ? 24 : 17),
                fontWeight: isActive ? FontWeight.w800 : FontWeight.w500,
                letterSpacing: isActive ? 0.5 : 0,
                height: 1.4,
                shadows: isActive && widget.isFullScreen ? [
                  Shadow(
                    color: accentColor.withValues(alpha: 0.5),
                    blurRadius: 16,
                  ),
                  const Shadow(
                    color: Colors.black54,
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ] : isActive ? [
                  const Shadow(
                    color: Colors.black38,
                    blurRadius: 4,
                  ),
                ] : null,
              ),
              child: ShaderMask(
                shaderCallback: (bounds) {
                  if (!isActive) {
                    return const LinearGradient(
                      colors: [Colors.white, Colors.white],
                    ).createShader(bounds);
                  }
                  // Gradient effect on active line
                  return LinearGradient(
                    colors: [
                      accentColor,
                      Colors.white,
                    ],
                    stops: const [0.0, 0.6],
                  ).createShader(bounds);
                },
                blendMode: BlendMode.srcIn,
                child: Text(
                  line.text,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
