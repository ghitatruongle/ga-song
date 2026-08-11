/// Frame Budget Overlay for Development
///
/// Displays real-time frame timing, FPS, and memory usage in a floating overlay.
/// Only active in debug mode. Enable with `--dart-define=FRAME_BUDGET_OVERLAY=true`
/// or by setting `kShowFrameBudgetOverlay = true` in main.dart.
library;

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class FrameBudgetOverlay extends StatefulWidget {
  final Widget child;
  final bool enabled;

  const FrameBudgetOverlay({
    super.key,
    required this.child,
    this.enabled = true,
  });

  @override
  State<FrameBudgetOverlay> createState() => _FrameBudgetOverlayState();
}

class _FrameBudgetOverlayState extends State<FrameBudgetOverlay>
    with TickerProviderStateMixin {
  final List<Duration> _frameTimes = [];
  static const int _maxSamples = 120;

  Timer? _updateTimer;
  String _fps = '--';
  String _avgFrameMs = '--';
  String _p99FrameMs = '--';
  String _jankCount = '--';
  String _memoryMB = '--';

  @override
  void initState() {
    super.initState();
    if (widget.enabled) {
      _startMonitoring();
    }
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }

  void _startMonitoring() {
    // Use SchedulerBinding to track frame times
    SchedulerBinding.instance.addPersistentFrameCallback(_onFrame);

    // Update display every 500ms
    _updateTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      _updateDisplay();
    });
  }

  void _onFrame(final Duration timestamp) {
    _frameTimes.add(timestamp);
    if (_frameTimes.length > _maxSamples) {
      _frameTimes.removeAt(0);
    }
  }

  void _updateDisplay() {
    if (!mounted) return;

    // Calculate FPS from frame timestamps
    if (_frameTimes.length >= 2) {
      final now = _frameTimes.last;
      final oneSecondAgo = now - const Duration(seconds: 1);
      final recentFrames = _frameTimes
          .where((final t) => t > oneSecondAgo)
          .length;

      final frameDeltas = <int>[];
      for (int i = 1; i < _frameTimes.length; i++) {
        final delta = (_frameTimes[i] - _frameTimes[i - 1]).inMicroseconds;
        if (delta > 0 && delta < 100000) {
          // Filter outliers
          frameDeltas.add(delta);
        }
      }

      if (frameDeltas.isNotEmpty) {
        frameDeltas.sort();
        final avgUs =
            frameDeltas.reduce((final a, final b) => a + b) /
            frameDeltas.length;
        final p99Us = frameDeltas[(frameDeltas.length * 0.99).floor()];
        final jankFrames = frameDeltas
            .where((final d) => d > 16000)
            .length; // > 16ms

        setState(() {
          _fps = recentFrames.toString();
          _avgFrameMs = (avgUs / 1000).toStringAsFixed(1);
          _p99FrameMs = (p99Us / 1000).toStringAsFixed(1);
          _jankCount = jankFrames.toString();
        });
      }
    }

    // Update memory (approximate)
    try {
      final info = ProcessInfo.currentRss;
      if (info > 0) {
        setState(() {
          _memoryMB = (info / 1024 / 1024).toStringAsFixed(1);
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(final BuildContext context) {
    if (!widget.enabled) return widget.child;

    return Stack(
      children: [
        widget.child,
        Positioned(
          top: 50,
          right: 10,
          child: Material(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.all(12),
              constraints: const BoxConstraints(minWidth: 180),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Icon(
                        _getFpsColor(_fps) == Colors.green
                            ? Icons.check_circle
                            : Icons.warning,
                        color: _getFpsColor(_fps),
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Frame Budget Overlay',
                        style: TextStyle(
                          color: _getFpsColor(_fps),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildMetric('FPS', _fps, _getFpsColor(_fps)),
                  _buildMetric(
                    'Avg Frame',
                    '${_avgFrameMs}ms',
                    _getFrameTimeColor(_avgFrameMs),
                  ),
                  _buildMetric(
                    'P99 Frame',
                    '${_p99FrameMs}ms',
                    _getFrameTimeColor(_p99FrameMs),
                  ),
                  _buildMetric(
                    'Jank (>16ms)',
                    _jankCount,
                    _jankCount != '--' && int.tryParse(_jankCount)! > 5
                        ? Colors.orange
                        : Colors.green,
                  ),
                  _buildMetric('Memory', '${_memoryMB}MB', Colors.blue),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMetric(
    final String label,
    final String value,
    final Color color,
  ) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label: ',
          style: const TextStyle(color: Colors.white70, fontSize: 11),
        ),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
          ),
        ),
      ],
    ),
  );

  Color _getFpsColor(final String fps) {
    final fpsValue = int.tryParse(fps) ?? 0;
    if (fpsValue >= 55) return Colors.green;
    if (fpsValue >= 30) return Colors.orange;
    return Colors.red;
  }

  Color _getFrameTimeColor(final String ms) {
    final msValue = double.tryParse(ms) ?? 0;
    if (msValue <= 16) return Colors.green;
    if (msValue <= 32) return Colors.orange;
    return Colors.red;
  }
}

/// Wrapper to easily add frame budget overlay to any app
class FrameBudgetOverlayWrapper extends StatelessWidget {
  final Widget child;
  final bool enabled;

  const FrameBudgetOverlayWrapper({
    super.key,
    required this.child,
    this.enabled = true,
  });

  @override
  Widget build(final BuildContext context) => FrameBudgetOverlay(
    enabled: enabled && !const bool.fromEnvironment('dart.vm.product'),
    child: child,
  );
}
