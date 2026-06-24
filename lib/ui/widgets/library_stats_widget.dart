import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/service_providers.dart';
import '../../core/theme_utils.dart';

/// Widget that displays library statistics.
///
/// Shows total songs, total duration, total plays,
/// and breakdown by genre.
class LibraryStatsWidget extends ConsumerStatefulWidget {
  const LibraryStatsWidget({super.key});

  static Future<void> show(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (context) => const Dialog(
        child: LibraryStatsWidget(),
      ),
    );
  }

  @override
  ConsumerState<LibraryStatsWidget> createState() => _LibraryStatsWidgetState();
}

class _LibraryStatsWidgetState extends ConsumerState<LibraryStatsWidget> {
  Map<String, dynamic>? _stats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final db = ref.read(databaseServiceProvider);
    final stats = await db.getLibraryStats();
    setState(() {
      _stats = stats;
      _isLoading = false;
    });
  }

  String _formatDuration(int ms) {
    final duration = Duration(milliseconds: ms);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    if (hours > 0) {
      return '$hours giờ $minutes phút';
    }
    return '$minutes phút';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 400),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: _isLoading
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Title
                  Text(
                    'Thống kê thư viện',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: context.adaptive,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Stats cards
                  _StatCard(
                    icon: Icons.music_note,
                    label: 'Tổng bài hát',
                    value: '${_stats!['totalSongs']}',
                    isDark: isDark,
                  ),
                  const SizedBox(height: 12),
                  _StatCard(
                    icon: Icons.timer,
                    label: 'Tổng thời gian',
                    value: _formatDuration(_stats!['totalDurationMs'] as int),
                    isDark: isDark,
                  ),
                  const SizedBox(height: 12),
                  _StatCard(
                    icon: Icons.play_circle,
                    label: 'Tổng lượt nghe',
                    value: '${_stats!['totalPlayCount']}',
                    isDark: isDark,
                  ),

                  // Genre breakdown
                  if ((_stats!['genreCounts'] as List).isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Text(
                      'Thể loại',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: context.adaptive,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...(_stats!['genreCounts'] as List).take(5).map((g) {
                      final genre = g['genre'] as String;
                      final count = g['count'] as int;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                genre,
                                style: TextStyle(
                                  color: context.adaptive.withValues(alpha: 0.7),
                                ),
                              ),
                            ),
                            Text(
                              '$count bài',
                              style: TextStyle(
                                color: context.adaptive.withValues(alpha: 0.5),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ],
              ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isDark;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE5E5E5),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 24, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: context.adaptive.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: context.adaptive,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
