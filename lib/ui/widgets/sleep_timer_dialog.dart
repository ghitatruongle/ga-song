import 'package:flutter/material.dart';
import '../../core/service_locator.dart';
import '../../core/audio/playlist_service.dart';

class SleepTimerDialog {
  static void show(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (context) => const _SleepTimerDialog(),
    );
  }
}

class _SleepTimerDialog extends StatefulWidget {
  const _SleepTimerDialog();

  @override
  State<_SleepTimerDialog> createState() => _SleepTimerDialogState();
}

class _SleepTimerDialogState extends State<_SleepTimerDialog> {
  final _playlistService = sl<PlaylistService>();
  int _selectedMinutes = 30;

  static const _presetMinutes = [5, 10, 15, 30, 45, 60, 90, 120];

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87;
    final bgColor = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF1E1E1E)
        : Colors.white;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: RepaintBoundary(
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: bgColor.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: textColor.withValues(alpha: 0.1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 30,
                offset: const Offset(0, 15),
              ),
            ],
          ),
          child: ValueListenableBuilder<Duration?>(
            valueListenable: _playlistService.sleepTimerRemainingNotifier,
            builder: (context, remaining, child) {
              if (remaining != null) {
                // C6 fix: Show active timer state and cancel button
                final minutes = remaining.inMinutes;
                final seconds = remaining.inSeconds % 60;
                final timeStr = '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.timer_outlined, color: textColor, size: 24),
                        const SizedBox(width: 12),
                        Text(
                          'Sleep Timer',
                          style: TextStyle(
                            color: textColor,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'Nhạc sẽ dừng sau',
                      style: TextStyle(color: textColor.withValues(alpha: 0.7)),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      timeStr,
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontSize: 48,
                        fontWeight: FontWeight.w200,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(height: 32),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: textColor,
                              side: BorderSide(color: textColor.withValues(alpha: 0.3)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              minimumSize: const Size(double.infinity, 44),
                            ),
                            child: const Text('Đóng'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              _playlistService.cancelSleepTimer();
                              Navigator.of(context).pop();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.shade400,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              minimumSize: const Size(double.infinity, 44),
                              elevation: 0,
                            ),
                            child: const Text('Hủy Timer'),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              }

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Icon(Icons.timer_outlined, color: textColor, size: 24),
                      const SizedBox(width: 12),
                      Text(
                        'Sleep Timer',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Tự động dừng nhạc sau:',
                    style: TextStyle(color: textColor.withValues(alpha: 0.7)),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: _presetMinutes.map((minutes) {
                      final isSelected = _selectedMinutes == minutes;
                      return ChoiceChip(
                        label: Text(
                          minutes < 60 ? '$minutes phút' : '${minutes ~/ 60} giờ ${minutes % 60 > 0 ? '${minutes % 60} phút' : ''}',
                          style: TextStyle(
                            color: isSelected ? Colors.white : textColor,
                            fontSize: 13,
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: Theme.of(context).primaryColor,
                        backgroundColor: textColor.withValues(alpha: 0.08),
                        side: BorderSide.none,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        onSelected: (_) => setState(() => _selectedMinutes = minutes),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  Slider(
                    value: _selectedMinutes.toDouble(),
                    min: 1,
                    max: 180,
                    divisions: 179,
                    label: '$_selectedMinutes phút',
                    activeColor: Theme.of(context).primaryColor,
                    onChanged: (value) => setState(() => _selectedMinutes = value.round()),
                  ),
                  Text(
                    '$_selectedMinutes phút',
                    style: TextStyle(color: textColor, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: textColor,
                            side: BorderSide(color: textColor.withValues(alpha: 0.3)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            minimumSize: const Size(double.infinity, 44),
                          ),
                          child: const Text('Hủy'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            _playlistService.startSleepTimer(Duration(minutes: _selectedMinutes));
                            Navigator.of(context).pop();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            minimumSize: const Size(double.infinity, 44),
                            elevation: 0,
                          ),
                          child: const Text('Bắt đầu'),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}