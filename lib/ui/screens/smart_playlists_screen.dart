import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/smart_playlist_service.dart';
import '../../providers/smart_playlist_provider.dart';
import '../../providers/service_providers.dart';
import '../widgets/song_tiles.dart';
import '../../core/theme_utils.dart';

class SmartPlaylistsScreen extends ConsumerWidget {
  const SmartPlaylistsScreen({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) => Scaffold(
    backgroundColor: Colors.transparent,
    body: CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(24),
          sliver: SliverToBoxAdapter(
            child: Text(
              'Danh sách phát thông minh',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: context.onAdaptive,
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          sliver: SliverGrid.count(
            crossAxisCount: MediaQuery.sizeOf(context).width > 800 ? 5 : 3,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            children: SmartPlaylistType.values
                .map((final type) => _SmartPlaylistCard(type: type))
                .toList(),
          ),
        ),
      ],
    ),
  );
}

class _SmartPlaylistCard extends ConsumerWidget {
  final SmartPlaylistType type;

  const _SmartPlaylistCard({required this.type});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final playlistAsync = ref.watch(smartPlaylistProvider(type));

    return Card(
      elevation: 0,
      color: context.adaptive.withValues(alpha: 0.5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Theme.of(context).dividerColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          _showPlaylistDetails(context, ref, type);
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                SmartPlaylistService.getIcon(type),
                style: const TextStyle(fontSize: 48),
              ),
              const SizedBox(height: 16),
              Text(
                SmartPlaylistService.getDisplayName(type),
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              playlistAsync.when(
                skipLoadingOnReload: true,
                data: (final songs) => Text(
                  '${songs.length} bài hát',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: context.onAdaptive.withValues(alpha: 0.6),
                  ),
                ),
                loading: () => const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                error: (final error, final stackTrace) => Text(
                  'Lỗi tải',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.red),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPlaylistDetails(
    final BuildContext context,
    final WidgetRef ref,
    final SmartPlaylistType type,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (final context) => _SmartPlaylistDetailsScreen(type: type),
      ),
    );
  }
}

class _SmartPlaylistDetailsScreen extends ConsumerWidget {
  final SmartPlaylistType type;

  const _SmartPlaylistDetailsScreen({required this.type});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final playlistAsync = ref.watch(smartPlaylistProvider(type));

    return Scaffold(
      backgroundColor: context.adaptive,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(
          '${SmartPlaylistService.getIcon(type)} ${SmartPlaylistService.getDisplayName(type)}',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.play_arrow_rounded),
            onPressed: () {
              playlistAsync.whenOrNull(
                data: (final songs) {
                  if (songs.isNotEmpty) {
                    final playlist = ref.read(playlistServiceProvider);
                    playlist.setPlaylist(songs);
                    playlist.play();
                  }
                },
              );
            },
          ),
        ],
      ),
      body: playlistAsync.when(
        skipLoadingOnReload: true,
        data: (final songs) {
          if (songs.isEmpty) {
            return const Center(child: Text('Danh sách trống'));
          }
          return ListView.builder(
            itemCount: songs.length,
            itemBuilder: (final context, final index) {
              final song = songs[index];
              return InkWell(
                onTap: () {
                  final playlist = ref.read(playlistServiceProvider);
                  playlist.setPlaylist(songs, startIndex: index);
                  playlist.play();
                },
                child: SongListTile(song: song, songIndex: index),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (final err, final stack) => Center(child: Text('Lỗi: $err')),
      ),
    );
  }
}
