import 'package:flutter/material.dart';
import '../settings_manager.dart';
import '../audio/lyric_parser.dart';

/// Service that manages the desktop lyrics overlay.
///
/// Shows a floating, semi-transparent lyrics display that syncs
/// with the current playback position. Only available on desktop platforms.
class DesktopLyricsService {
  DesktopLyricsService({
    required SettingsManager settingsManager,
  }) : _settingsManager = settingsManager;

  final SettingsManager _settingsManager;

  // ─── State ─────────────────────────────────────────────────────────────────
  final ValueNotifier<bool> isVisibleNotifier = ValueNotifier(false);
  final ValueNotifier<double> opacityNotifier = ValueNotifier(0.9);
  final ValueNotifier<double> fontSizeNotifier = ValueNotifier(24.0);
  final ValueNotifier<bool> clickThroughNotifier = ValueNotifier(false);

  // Current lyrics data
  final ValueNotifier<List<LyricLine>> lyricsNotifier = ValueNotifier([]);
  final ValueNotifier<int> currentLineIndexNotifier = ValueNotifier(-1);
  final ValueNotifier<String?> currentSongTitleNotifier = ValueNotifier(null);

  OverlayEntry? _overlayEntry;

  // ─── Lifecycle ─────────────────────────────────────────────────────────────

  void init() {
    // Sync with settings
    opacityNotifier.value = _settingsManager.desktopLyricsOpacityNotifier.value;
    fontSizeNotifier.value = _settingsManager.desktopLyricsFontSizeNotifier.value;
    clickThroughNotifier.value = _settingsManager.desktopLyricsClickThroughNotifier.value;
    isVisibleNotifier.value = _settingsManager.desktopLyricsEnabledNotifier.value;

    // Listen to settings changes
    _settingsManager.desktopLyricsOpacityNotifier.addListener(_onOpacityChanged);
    _settingsManager.desktopLyricsFontSizeNotifier.addListener(_onFontSizeChanged);
    _settingsManager.desktopLyricsClickThroughNotifier.addListener(_onClickThroughChanged);
    _settingsManager.desktopLyricsEnabledNotifier.addListener(_onEnabledChanged);
  }

  void dispose() {
    _settingsManager.desktopLyricsOpacityNotifier.removeListener(_onOpacityChanged);
    _settingsManager.desktopLyricsFontSizeNotifier.removeListener(_onFontSizeChanged);
    _settingsManager.desktopLyricsClickThroughNotifier.removeListener(_onClickThroughChanged);
    _settingsManager.desktopLyricsEnabledNotifier.removeListener(_onEnabledChanged);
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  // ─── Settings Sync ─────────────────────────────────────────────────────────

  void _onOpacityChanged() {
    opacityNotifier.value = _settingsManager.desktopLyricsOpacityNotifier.value;
  }

  void _onFontSizeChanged() {
    fontSizeNotifier.value = _settingsManager.desktopLyricsFontSizeNotifier.value;
  }

  void _onClickThroughChanged() {
    clickThroughNotifier.value = _settingsManager.desktopLyricsClickThroughNotifier.value;
  }

  void _onEnabledChanged() {
    isVisibleNotifier.value = _settingsManager.desktopLyricsEnabledNotifier.value;
    if (!isVisibleNotifier.value) {
      hide();
    }
  }

  // ─── Public API ────────────────────────────────────────────────────────────

  /// Update lyrics for the current song
  void updateLyrics(List<LyricLine> lyrics, String? songTitle) {
    lyricsNotifier.value = lyrics;
    currentSongTitleNotifier.value = songTitle;
    currentLineIndexNotifier.value = -1;
  }

  /// Update the current playback position to sync lyrics
  void updatePosition(Duration position) {
    final lyrics = lyricsNotifier.value;
    if (lyrics.isEmpty) {
      currentLineIndexNotifier.value = -1;
      return;
    }

    // Find the current line using Duration comparison
    int currentIndex = -1;
    for (int i = lyrics.length - 1; i >= 0; i--) {
      if (lyrics[i].startTime <= position) {
        currentIndex = i;
        break;
      }
    }

    if (currentIndex != currentLineIndexNotifier.value) {
      currentLineIndexNotifier.value = currentIndex;
    }
  }

  /// Show the lyrics overlay
  void show(BuildContext context) {
    if (_overlayEntry != null) return;

    _overlayEntry = OverlayEntry(
      builder: (context) => _DesktopLyricsOverlay(service: this),
    );

    Overlay.of(context).insert(_overlayEntry!);
    isVisibleNotifier.value = true;
    _settingsManager.setDesktopLyricsEnabled(true);
  }

  /// Hide the lyrics overlay
  void hide() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    isVisibleNotifier.value = false;
  }

  /// Toggle lyrics visibility
  void toggle(BuildContext context) {
    if (isVisibleNotifier.value) {
      hide();
      _settingsManager.setDesktopLyricsEnabled(false);
    } else {
      show(context);
    }
  }

  /// Set font size
  void setFontSize(double size) {
    fontSizeNotifier.value = size;
    _settingsManager.setDesktopLyricsFontSize(size);
  }

  /// Set opacity
  void setOpacity(double opacity) {
    opacityNotifier.value = opacity;
    _settingsManager.setDesktopLyricsOpacity(opacity);
  }

  /// Toggle click-through mode
  void toggleClickThrough() {
    final newValue = !clickThroughNotifier.value;
    clickThroughNotifier.value = newValue;
    _settingsManager.setDesktopLyricsClickThrough(newValue);
  }
}

// ─── Overlay Widget ──────────────────────────────────────────────────────────

class _DesktopLyricsOverlay extends StatefulWidget {
  final DesktopLyricsService service;

  const _DesktopLyricsOverlay({required this.service});

  @override
  State<_DesktopLyricsOverlay> createState() => _DesktopLyricsOverlayState();
}

class _DesktopLyricsOverlayState extends State<_DesktopLyricsOverlay> {
  Offset _position = const Offset(100, 100);
  bool _isDragging = false;
  bool _showControls = false;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Positioned(
      left: _position.dx.clamp(0, screenWidth - 400),
      top: _position.dy.clamp(0, screenHeight - 200),
      child: MouseRegion(
        onEnter: (_) => setState(() => _showControls = true),
        onExit: (_) {
          if (!_isDragging) {
            setState(() => _showControls = false);
          }
        },
        child: GestureDetector(
          onPanStart: (details) {
            setState(() => _isDragging = true);
          },
          onPanUpdate: (details) {
            setState(() {
              _position += details.delta;
            });
          },
          onPanEnd: (_) {
            setState(() => _isDragging = false);
          },
          child: ValueListenableBuilder<double>(
            valueListenable: widget.service.opacityNotifier,
            builder: (context, opacity, _) {
              return AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: opacity,
                child: Container(
                  width: 400,
                  constraints: const BoxConstraints(minHeight: 100, maxHeight: 300),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Controls bar (shown on hover)
                      if (_showControls)
                        _ControlsBar(service: widget.service),

                      // Lyrics content
                      Flexible(
                        child: _LyricsContent(service: widget.service),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

// ─── Controls Bar ────────────────────────────────────────────────────────────

class _ControlsBar extends StatelessWidget {
  final DesktopLyricsService service;

  const _ControlsBar({required this.service});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Font size controls
          GestureDetector(
            onTap: () {
              final currentSize = service.fontSizeNotifier.value;
              if (currentSize > 16) {
                service.setFontSize(currentSize - 2);
              }
            },
            child: Icon(
              Icons.text_decrease_rounded,
              size: 18,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              final currentSize = service.fontSizeNotifier.value;
              if (currentSize < 48) {
                service.setFontSize(currentSize + 2);
              }
            },
            child: Icon(
              Icons.text_increase_rounded,
              size: 18,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(width: 16),

          // Click-through toggle
          ValueListenableBuilder<bool>(
            valueListenable: service.clickThroughNotifier,
            builder: (context, isClickThrough, _) {
              return GestureDetector(
                onTap: () => service.toggleClickThrough(),
                child: Icon(
                  isClickThrough
                      ? Icons.do_not_touch_rounded
                      : Icons.touch_app_rounded,
                  size: 18,
                  color: isClickThrough
                      ? Colors.blue
                      : Colors.white.withValues(alpha: 0.6),
                ),
              );
            },
          ),
          const SizedBox(width: 16),

          // Close button
          GestureDetector(
            onTap: () => service.hide(),
            child: Icon(
              Icons.close_rounded,
              size: 18,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Lyrics Content ──────────────────────────────────────────────────────────

class _LyricsContent extends StatelessWidget {
  final DesktopLyricsService service;

  const _LyricsContent({required this.service});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<LyricLine>>(
      valueListenable: service.lyricsNotifier,
      builder: (context, lyrics, _) {
        if (lyrics.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Không có lời bài hát',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 14,
                ),
              ),
            ),
          );
        }

        return ValueListenableBuilder<int>(
          valueListenable: service.currentLineIndexNotifier,
          builder: (context, currentIndex, _) {
            return ValueListenableBuilder<double>(
              valueListenable: service.fontSizeNotifier,
              builder: (context, fontSize, _) {
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  itemCount: lyrics.length,
                  itemBuilder: (context, index) {
                    final line = lyrics[index];
                    final isCurrent = index == currentIndex;
                    final isPast = index < currentIndex;

                    return AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 200),
                      style: TextStyle(
                        fontSize: isCurrent ? fontSize : fontSize * 0.65,
                        fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w400,
                        color: isCurrent
                            ? Colors.white
                            : isPast
                                ? Colors.white.withValues(alpha: 0.25)
                                : Colors.white.withValues(alpha: 0.4),
                        height: 1.5,
                      ),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: isCurrent ? 8 : 4,
                        ),
                        child: Text(
                          line.text,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}
