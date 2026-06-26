import 'package:flutter/material.dart';

import '../../../core/theme_utils.dart';
import '../../../models/song.dart';
import '../cover_art_image.dart';

class SongInfo extends StatelessWidget {
  const SongInfo({super.key, required this.song});

  final Song song;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: context.adaptive.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: CoverArtImage(
            song: song,
            cacheWidth: 104,
            cacheHeight: 104,
            fallbackBuilder: (context) =>
                Icon(Icons.music_note, color: context.adaptiveSubtle, size: 28),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                song.name,
                style: TextStyle(
                  color: context.adaptive,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                song.artist ?? 'Unknown Artist',
                style: TextStyle(
                  color: context.adaptive.withValues(alpha: 0.6),
                  fontSize: 13,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
