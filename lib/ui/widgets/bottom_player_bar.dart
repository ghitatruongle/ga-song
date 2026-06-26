import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/service_providers.dart';
import '../../core/theme_utils.dart';
import 'player_bar/song_info.dart';
import 'player_bar/center_controls.dart';
import 'player_bar/right_controls.dart';

class BottomPlayerBarWidget extends ConsumerWidget {
  const BottomPlayerBarWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlistService = ref.read(playlistServiceProvider);
    final viewModel = ref.read(playerViewModelProvider);
    return ValueListenableBuilder<int>(
      valueListenable: playlistService.currentIndexNotifier,
      builder: (context, idx, child) {
        final song = viewModel.currentSong;
        final isDark = context.isDark;

        return Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          height: 72,
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF1A1A1A)
                : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark
                  ? const Color(0xFF2A2A2A)
                  : const Color(0xFFE5E5E5),
              width: 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Column(
              children: [
                // Thin progress line on top
                if (song != null)
                  _TopProgressBar(viewModel: viewModel),

                // Main content
                Expanded(
                  child: song == null
                      ? Center(
                          child: Text(
                            'Chưa chọn bài hát',
                            style: TextStyle(
                              color: context.adaptive.withValues(alpha: 0.35),
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        )
                      : Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                child: SongInfo(song: song),
                              ),
                            ),
                            const Expanded(
                              flex: 4,
                              child: RepaintBoundary(
                                child: CenterControls(),
                              ),
                            ),
                            const Expanded(
                              flex: 3,
                              child: RepaintBoundary(
                                child: RightControls(),
                              ),
                            ),
                          ],
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Thin 2px progress indicator at the top of the player bar.
class _TopProgressBar extends StatelessWidget {
  final dynamic viewModel;

  const _TopProgressBar({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge(<Listenable>[
        viewModel.positionNotifier,
        viewModel.durationNotifier,
      ]),
      builder: (context, _) {
        final progress = viewModel.progress;
        return SizedBox(
          height: 2,
          child: LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            backgroundColor: Colors.transparent,
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).colorScheme.primary,
            ),
          ),
        );
      },
    );
  }
}
