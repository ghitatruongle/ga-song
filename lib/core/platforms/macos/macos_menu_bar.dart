import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/service_providers.dart';
import '../../audio/audio_engine_service.dart';

/// macOS menu bar configuration for G.A Song.
///
/// Provides native macOS menu bar items for playback control,
/// window management, and app features.
class MacOSMenuBar extends ConsumerWidget {
  /// Child widget.
  final Widget child;

  /// Callback for play/pause action.
  final VoidCallback? onPlayPause;

  /// Callback for next song action.
  final VoidCallback? onNext;

  /// Callback for previous song action.
  final VoidCallback? onPrevious;

  /// Callback for opening settings.
  final VoidCallback? onOpenSettings;

  /// Callback for importing songs.
  final VoidCallback? onImportSongs;

  /// Creates a macOS menu bar.
  const MacOSMenuBar({
    super.key,
    required this.child,
    this.onPlayPause,
    this.onNext,
    this.onPrevious,
    this.onOpenSettings,
    this.onImportSongs,
  });

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    if (!Platform.isMacOS) return child;

    final playlistService = ref.read(playlistServiceProvider);
    final engineService = ref.read(audioEngineServiceProvider);

    final handlePlayPause =
        onPlayPause ??
        () {
          if (engineService.engineState.value == AudioEngineState.playing) {
            engineService.pause();
          } else {
            playlistService.play();
          }
        };
    final handleNext = onNext ?? () => playlistService.next();
    final handlePrevious = onPrevious ?? () => playlistService.previous();

    return PlatformMenuBar(
      menus: [
        // App Menu
        PlatformMenu(
          label: 'G.A Song',
          menus: [
            PlatformMenuItemGroup(
              members: [
                PlatformMenuItem(
                  label: 'About G.A Song',
                  onSelected: () => _showAboutDialog(context),
                ),
              ],
            ),
            PlatformMenuItemGroup(
              members: [
                PlatformMenuItem(
                  label: 'Preferences...',
                  shortcut: const SingleActivator(
                    LogicalKeyboardKey.comma,
                    meta: true,
                  ),
                  onSelected: () => onOpenSettings?.call(),
                ),
              ],
            ),
            PlatformMenuItemGroup(
              members: [
                PlatformMenuItem(
                  label: 'Quit G.A Song',
                  shortcut: const SingleActivator(
                    LogicalKeyboardKey.keyQ,
                    meta: true,
                  ),
                  onSelected: () => SystemNavigator.pop(),
                ),
              ],
            ),
          ],
        ),

        // File Menu
        PlatformMenu(
          label: 'File',
          menus: [
            PlatformMenuItemGroup(
              members: [
                PlatformMenuItem(
                  label: 'Import Songs...',
                  shortcut: const SingleActivator(
                    LogicalKeyboardKey.keyO,
                    meta: true,
                  ),
                  onSelected: () => onImportSongs?.call(),
                ),
              ],
            ),
            PlatformMenuItemGroup(
              members: [
                PlatformMenuItem(
                  label: 'Close Window',
                  shortcut: const SingleActivator(
                    LogicalKeyboardKey.keyW,
                    meta: true,
                  ),
                  onSelected: () => SystemNavigator.pop(),
                ),
              ],
            ),
          ],
        ),

        // Playback Menu
        PlatformMenu(
          label: 'Playback',
          menus: [
            PlatformMenuItemGroup(
              members: [
                PlatformMenuItem(
                  label: 'Play/Pause',
                  shortcut: const SingleActivator(LogicalKeyboardKey.space),
                  onSelected: handlePlayPause,
                ),
                PlatformMenuItem(
                  label: 'Next',
                  shortcut: const SingleActivator(
                    LogicalKeyboardKey.arrowRight,
                    meta: true,
                  ),
                  onSelected: handleNext,
                ),
                PlatformMenuItem(
                  label: 'Previous',
                  shortcut: const SingleActivator(
                    LogicalKeyboardKey.arrowLeft,
                    meta: true,
                  ),
                  onSelected: handlePrevious,
                ),
              ],
            ),
          ],
        ),

        // Window Menu
        PlatformMenu(
          label: 'Window',
          menus: [
            PlatformMenuItemGroup(
              members: [
                PlatformMenuItem(
                  label: 'Minimize',
                  shortcut: const SingleActivator(
                    LogicalKeyboardKey.keyM,
                    meta: true,
                  ),
                  onSelected: () {},
                ),
              ],
            ),
          ],
        ),
      ],
      child: child,
    );
  }

  void _showAboutDialog(final BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'G.A Song',
      applicationVersion: '1.0.0',
      applicationIcon: const FlutterLogo(size: 64),
    );
  }
}
