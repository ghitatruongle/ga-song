import 'dart:async';

/// A simple debouncer that delays calling [action] until [duration] has
/// passed without a new invocation. Use to coalesce high-frequency events
/// (slider drags, search input, etc.) into a single delayed call.
///
/// ```dart
/// final _d = Debouncer(milliseconds: 100);
/// Slider(
///   onChanged: (v) => _d.run(() => applyValue(v)),
/// ),
/// ```
class Debouncer {
  Debouncer({this.milliseconds = 100});

  final int milliseconds;
  Timer? _timer;

  /// Cancels any pending call and schedules [action] after [milliseconds].
  void run(void Function() action) {
    _timer?.cancel();
    _timer = Timer(Duration(milliseconds: milliseconds), action);
  }

  /// Cancels any pending call without firing [action].
  void cancel() => _timer?.cancel();

  /// True if a call is currently scheduled.
  bool get isPending => _timer?.isActive ?? false;

  void dispose() {
    _timer?.cancel();
    _timer = null;
  }
}
