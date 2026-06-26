// Q-2 fix: Shared time formatting utilities.

/// Formats a [Duration] as "MM:SS" (zero-padded, minutes capped at 59).
String formatDuration(Duration duration) {
  final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}
