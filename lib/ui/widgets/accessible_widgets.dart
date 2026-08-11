import 'package:flutter/material.dart';

import 'debounced_slider.dart';

/// A play/pause button with proper accessibility semantics.
class AccessiblePlayButton extends StatelessWidget {
  /// Whether the player is currently playing.
  final bool isPlaying;

  /// Callback when the button is pressed.
  final VoidCallback onPressed;

  /// Creates an accessible play button.
  const AccessiblePlayButton({
    super.key,
    required this.isPlaying,
    required this.onPressed,
  });

  @override
  Widget build(final BuildContext context) => Semantics(
    label: isPlaying ? 'Pause' : 'Play',
    hint: isPlaying ? 'Tap to pause current song' : 'Tap to play current song',
    button: true,
    enabled: true,
    child: IconButton(
      icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
      onPressed: onPressed,
      tooltip: isPlaying ? 'Pause' : 'Play',
    ),
  );
}

/// A song list tile with proper accessibility semantics.
class AccessibleSongTile extends StatelessWidget {
  /// Song title.
  final String title;

  /// Song artist.
  final String artist;

  /// Song duration formatted as string.
  final String duration;

  /// Whether the song is a favorite.
  final bool isFavorite;

  /// Whether this song is currently playing.
  final bool isPlaying;

  /// Callback when the tile is tapped.
  final VoidCallback onTap;

  /// Callback when the favorite button is tapped.
  final VoidCallback onFavoriteToggle;

  /// Creates an accessible song tile.
  const AccessibleSongTile({
    super.key,
    required this.title,
    required this.artist,
    required this.duration,
    required this.isFavorite,
    this.isPlaying = false,
    required this.onTap,
    required this.onFavoriteToggle,
  });

  @override
  Widget build(final BuildContext context) => Semantics(
    label:
        '$title by $artist, duration $duration${isPlaying ? ', currently playing' : ''}',
    hint: 'Tap to play, double tap to toggle favorite',
    button: true,
    selected: isPlaying,
    child: ListTile(
      title: Text(title),
      subtitle: Text(artist),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(duration),
          Semantics(
            label: isFavorite ? 'Remove from favorites' : 'Add to favorites',
            button: true,
            child: IconButton(
              icon: Icon(
                isFavorite ? Icons.favorite : Icons.favorite_border,
                color: isFavorite ? Colors.red : null,
              ),
              onPressed: onFavoriteToggle,
              tooltip: isFavorite
                  ? 'Remove from favorites'
                  : 'Add to favorites',
            ),
          ),
        ],
      ),
      onTap: onTap,
    ),
  );
}

/// A volume slider with proper accessibility semantics.
class AccessibleVolumeSlider extends StatelessWidget {
  /// Current volume level (0.0 to 1.0).
  final double volume;

  /// Callback when volume changes.
  final ValueChanged<double> onChanged;

  /// Whether the volume is muted.
  final bool isMuted;

  /// Callback when mute is toggled.
  final VoidCallback? onMuteToggle;

  /// Creates an accessible volume slider.
  const AccessibleVolumeSlider({
    super.key,
    required this.volume,
    required this.onChanged,
    this.isMuted = false,
    this.onMuteToggle,
  });

  @override
  Widget build(final BuildContext context) {
    final percentage = (volume * 100).round();

    return Semantics(
      label: 'Volume: $percentage%',
      hint: 'Slide to adjust volume',
      value: '$percentage%',
      increasedValue: '${((volume + 0.1).clamp(0, 1) * 100).round()}%',
      decreasedValue: '${((volume - 0.1).clamp(0, 1) * 100).round()}%',
      onIncrease: () => onChanged((volume + 0.1).clamp(0, 1)),
      onDecrease: () => onChanged((volume - 0.1).clamp(0, 1)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (onMuteToggle != null)
            Semantics(
              label: isMuted ? 'Unmute' : 'Mute',
              button: true,
              child: IconButton(
                icon: Icon(isMuted ? Icons.volume_off : Icons.volume_up),
                onPressed: onMuteToggle,
                tooltip: isMuted ? 'Unmute' : 'Mute',
              ),
            ),
          SizedBox(
            width: 100,
            child: DebouncedSlider(
              value: volume,
              onChanged: onChanged,
              debounceMs: 80, // volume — short debounce for responsive feel
            ),
          ),
        ],
      ),
    );
  }
}
