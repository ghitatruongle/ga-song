import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/service_providers.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme_utils.dart';
import '../utils/theme_helpers.dart';

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
    final spacing = ThemeSpacing.of(context);

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 400),
      child: Padding(
        padding: EdgeInsets.all(spacing.lg),
        child: _isLoading
            ? Center(
                child: Padding(
                  padding: EdgeInsets.all(spacing.xl),
                  child: const CircularProgressIndicator(),
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
                  SizedBox(height: spacing.lg),

                  // Stats cards
                  _StatCard(
                    icon: Icons.music_note,
                    label: 'Tổng bài hát',
                    value: '${_stats!['totalSongs']}',
                    isDark: isDark,
                  ),
                  SizedBox(height: spacing.sm + spacing.xxs),
                  _StatCard(
                    icon: Icons.timer,
                    label: 'Tổng thời gian',
                    value: _formatDuration(_stats!['totalDurationMs'] as int),
                    isDark: isDark,
                  ),
                  SizedBox(height: spacing.sm + spacing.xxs),
                  _StatCard(
                    icon: Icons.play_circle,
                    label: 'Tổng lượt nghe',
                    value: '${_stats!['totalPlayCount']}',
                    isDark: isDark,
                  ),

                  // Genre breakdown
                  if ((_stats!['genreCounts'] as List).isNotEmpty) ...[
                    SizedBox(height: spacing.lg),
                    Text(
                      'Thể loại',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: context.adaptive,
                      ),
                    ),
                    SizedBox(height: spacing.sm + spacing.xxs),
                    ...(_stats!['genreCounts'] as List).take(5).map((g) {
                      final genre = g['genre'] as String;
                      final count = g['count'] as int;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
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
    final spacing = ThemeSpacing.of(context);
    final radius = ThemeRadius.of(context);
    final cardBg = AppColors.adaptive(
      context,
      dark: AppColors.darkSurface,
      light: AppColors.lightSurface2,
    );
    final cardBorder = AppColors.adaptive(
      context,
      dark: AppColors.darkSurface2,
      light: AppColors.lightBorder,
    );
    return Container(
      padding: EdgeInsets.all(spacing.md),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: radius.circular(),
        border: Border.all(color: cardBorder),
      ),
      child: Row(
        children: [
          Icon(icon, size: 24, color: Theme.of(context).colorScheme.primary),
          SizedBox(width: spacing.md),
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
                const SizedBox(height: AppSpacing.xs),
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