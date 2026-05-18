import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/service_locator.dart';
import '../../core/audio/audio_engine_service.dart';
import '../../providers/lyric_provider.dart';

class LyricView extends ConsumerStatefulWidget {
  final bool isFullScreen;
  const LyricView({super.key, this.isFullScreen = false});

  @override
  ConsumerState<LyricView> createState() => _LyricViewState();
}

class _LyricViewState extends ConsumerState<LyricView> {
  final ScrollController _scrollController = ScrollController();
  final AudioEngineService _audioEngine = sl<AudioEngineService>();
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
    final lineHeight = widget.isFullScreen ? 60.0 : 40.0;
    final offset = (_currentIndex * lineHeight) - (MediaQuery.of(context).size.height / 3);
    
    _scrollController.animateTo(
      offset.clamp(0.0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final lyrics = ref.watch(lyricProvider);

    if (lyrics.isEmpty) {
      return Center(
        child: Text(
          'Chưa có lời bài hát',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: widget.isFullScreen ? 24 : 16,
          ),
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

        return GestureDetector(
          onTap: () {
            _audioEngine.seek(line.startTime);
          },
          child: Container(
            height: widget.isFullScreen ? 60.0 : 40.0,
            alignment: Alignment.center,
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontFamily: 'Inter',
                color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.4),
                fontSize: widget.isFullScreen 
                    ? (isActive ? 36 : 24)
                    : (isActive ? 22 : 16),
                fontWeight: isActive ? FontWeight.w800 : FontWeight.w500,
                shadows: isActive && widget.isFullScreen ? [
                  const Shadow(
                    color: Colors.black54,
                    blurRadius: 8,
                  )
                ] : null,
              ),
              child: Text(
                line.text,
                textAlign: TextAlign.center,
              ),
            ),
          ),
        );
      },
    );
  }
}
