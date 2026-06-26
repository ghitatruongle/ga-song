import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Keyboard shortcuts for the app.
class AppShortcuts extends StatelessWidget {
  /// Child widget.
  final Widget child;

  /// Callback for play/pause action.
  final VoidCallback? onPlayPause;

  /// Callback for next song action.
  final VoidCallback? onNext;

  /// Callback for previous song action.
  final VoidCallback? onPrevious;

  /// Callback for volume up action.
  final VoidCallback? onVolumeUp;

  /// Callback for volume down action.
  final VoidCallback? onVolumeDown;

  /// Callback for mute toggle action.
  final VoidCallback? onMute;

  /// Creates app shortcuts.
  const AppShortcuts({
    super.key,
    required this.child,
    this.onPlayPause,
    this.onNext,
    this.onPrevious,
    this.onVolumeUp,
    this.onVolumeDown,
    this.onMute,
  });

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: {
        LogicalKeySet(LogicalKeyboardKey.space): const _PlayPauseIntent(),
        LogicalKeySet(LogicalKeyboardKey.mediaPlayPause): const _PlayPauseIntent(),
        LogicalKeySet(LogicalKeyboardKey.arrowRight, LogicalKeyboardKey.control): const _NextIntent(),
        LogicalKeySet(LogicalKeyboardKey.mediaTrackNext): const _NextIntent(),
        LogicalKeySet(LogicalKeyboardKey.arrowLeft, LogicalKeyboardKey.control): const _PreviousIntent(),
        LogicalKeySet(LogicalKeyboardKey.mediaTrackPrevious): const _PreviousIntent(),
        LogicalKeySet(LogicalKeyboardKey.arrowUp, LogicalKeyboardKey.control): const _VolumeUpIntent(),
        LogicalKeySet(LogicalKeyboardKey.arrowDown, LogicalKeyboardKey.control): const _VolumeDownIntent(),
        LogicalKeySet(LogicalKeyboardKey.keyM, LogicalKeyboardKey.control): const _MuteIntent(),
      },
      child: Actions(
        actions: {
          _PlayPauseIntent: CallbackAction<_PlayPauseIntent>(
            onInvoke: (_) => onPlayPause?.call(),
          ),
          _NextIntent: CallbackAction<_NextIntent>(
            onInvoke: (_) => onNext?.call(),
          ),
          _PreviousIntent: CallbackAction<_PreviousIntent>(
            onInvoke: (_) => onPrevious?.call(),
          ),
          _VolumeUpIntent: CallbackAction<_VolumeUpIntent>(
            onInvoke: (_) => onVolumeUp?.call(),
          ),
          _VolumeDownIntent: CallbackAction<_VolumeDownIntent>(
            onInvoke: (_) => onVolumeDown?.call(),
          ),
          _MuteIntent: CallbackAction<_MuteIntent>(
            onInvoke: (_) => onMute?.call(),
          ),
        },
        child: Focus(
          autofocus: true,
          child: child,
        ),
      ),
    );
  }
}

class _PlayPauseIntent extends Intent {
  const _PlayPauseIntent();
}

class _NextIntent extends Intent {
  const _NextIntent();
}

class _PreviousIntent extends Intent {
  const _PreviousIntent();
}

class _VolumeUpIntent extends Intent {
  const _VolumeUpIntent();
}

class _VolumeDownIntent extends Intent {
  const _VolumeDownIntent();
}

class _MuteIntent extends Intent {
  const _MuteIntent();
}
