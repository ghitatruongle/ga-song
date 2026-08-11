/// Empty State Widgets for G.A - Song
///
/// Illustrated empty states with actionable buttons for better UX.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme_utils.dart';
import '../../providers/service_providers.dart';
import '../../l10n/app_localizations.dart';
import 'playlist_manager_widget.dart';

/// Main empty library state
class EmptyLibraryState extends ConsumerWidget {
  const EmptyLibraryState({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = context.isDark;
    final adaptiveColor = context.adaptive;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Illustration
            Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkSurface2
                    : AppColors.lightSurface2,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.music_note_outlined,
                size: 80,
                color: adaptiveColor.withValues(alpha: 0.3),
              ),
            ),
            const SizedBox(height: 32),

            // Title
            Text(
              l10n.emptyLibraryTitle,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: adaptiveColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),

            // Description
            Text(
              l10n.emptyLibraryMessage,
              style: TextStyle(
                fontSize: 16,
                color: adaptiveColor.withValues(alpha: 0.6),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Action buttons
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                // Import local files
                FilledButton.icon(
                  icon: const Icon(Icons.folder_open_rounded),
                  label: Text(l10n.importMusic),
                  onPressed: () => _importLocalSongs(context, ref),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
                  ),
                ),
                // Scan for music
                OutlinedButton.icon(
                  icon: const Icon(Icons.search_rounded),
                  label: Text(l10n.scanForMusic),
                  onPressed: () => _scanForMusic(context, ref),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
                  ),
                ),
                // Create playlist
                OutlinedButton.icon(
                  icon: const Icon(Icons.playlist_add_rounded),
                  label: Text(l10n.createPlaylist),
                  onPressed: () => _createPlaylist(context, ref),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _importLocalSongs(final BuildContext context, final WidgetRef ref) {
    final manager = ref.read(musicManagerProvider);
    final messenger = ScaffoldMessenger.of(context);
    manager
        .importLocalSongs()
        .then((_) {
          if (context.mounted) {
            messenger.showSnackBar(
              SnackBar(
                content: Text(AppLocalizations.of(context)!.importSuccess),
              ),
            );
          }
        })
        .catchError((final e) {
          if (context.mounted) {
            messenger.showSnackBar(
              SnackBar(
                content: Text(
                  '${AppLocalizations.of(context)!.importError}: $e',
                ),
              ),
            );
          }
        });
  }

  void _scanForMusic(final BuildContext context, final WidgetRef ref) {
    // Scan for music uses the same import flow (file picker)
    _importLocalSongs(context, ref);
  }

  void _createPlaylist(final BuildContext context, final WidgetRef ref) {
    PlaylistManagerWidget.show(context);
  }
}

/// Empty search results state
class EmptySearchState extends StatelessWidget {
  final String query;
  final VoidCallback? onClearSearch;

  const EmptySearchState({super.key, required this.query, this.onClearSearch});

  @override
  Widget build(final BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = context.isDark;
    final adaptiveColor = context.adaptive;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkSurface2
                    : AppColors.lightSurface2,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.search_off_rounded,
                size: 60,
                color: adaptiveColor.withValues(alpha: 0.3),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.noResultsTitle,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: adaptiveColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.noResultsMessage(query),
              style: TextStyle(
                fontSize: 14,
                color: adaptiveColor.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
            if (onClearSearch != null) ...[
              const SizedBox(height: 24),
              TextButton.icon(
                icon: const Icon(Icons.clear_rounded),
                label: Text(l10n.clearSearch),
                onPressed: onClearSearch,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Empty playlist state
class EmptyPlaylistState extends ConsumerWidget {
  final String playlistName;

  const EmptyPlaylistState({super.key, required this.playlistName});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = context.isDark;
    final adaptiveColor = context.adaptive;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkSurface2
                    : AppColors.lightSurface2,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.playlist_play_rounded,
                size: 70,
                color: adaptiveColor.withValues(alpha: 0.3),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.emptyPlaylistTitle,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: adaptiveColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.emptyPlaylistMessage(playlistName),
              style: TextStyle(
                fontSize: 14,
                color: adaptiveColor.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                FilledButton.icon(
                  icon: const Icon(Icons.add_rounded),
                  label: Text(l10n.addSongs),
                  onPressed: () => PlaylistManagerWidget.show(context),
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.import_export_rounded),
                  label: Text(l10n.importPlaylist),
                  onPressed: () => _importPlaylist(context, ref),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _importPlaylist(final BuildContext context, final WidgetRef ref) {
    // Implementation for importing playlist
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.featureComingSoon)),
    );
  }
}

/// Error loading state with retry
class ErrorLoadingState extends StatelessWidget {
  final String errorMessage;
  final VoidCallback onRetry;

  const ErrorLoadingState({
    super.key,
    required this.errorMessage,
    required this.onRetry,
  });

  @override
  Widget build(final BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = context.isDark;
    final adaptiveColor = context.adaptive;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.red.withValues(alpha: 0.1)
                    : Colors.red.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 60,
                color: Colors.red.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.errorLoadingTitle,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: adaptiveColor,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              errorMessage,
              style: TextStyle(
                fontSize: 14,
                color: adaptiveColor.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              icon: const Icon(Icons.refresh_rounded),
              label: Text(l10n.retry),
              onPressed: onRetry,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// No internet connection state
class NoInternetState extends StatelessWidget {
  final VoidCallback onRetry;

  const NoInternetState({super.key, required this.onRetry});

  @override
  Widget build(final BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = context.isDark;
    final adaptiveColor = context.adaptive;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkSurface2
                    : AppColors.lightSurface2,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.wifi_off_rounded,
                size: 60,
                color: adaptiveColor.withValues(alpha: 0.3),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.noInternetTitle,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: adaptiveColor,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.noInternetMessage,
              style: TextStyle(
                fontSize: 14,
                color: adaptiveColor.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                FilledButton.icon(
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(l10n.retry),
                  onPressed: onRetry,
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.settings_rounded),
                  label: Text(l10n.openNetworkSettings),
                  onPressed: () => _openNetworkSettings(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _openNetworkSettings(final BuildContext context) {
    // Platform-specific network settings
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.featureComingSoon)),
    );
  }
}
