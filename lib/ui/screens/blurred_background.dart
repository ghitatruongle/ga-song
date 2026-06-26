import 'dart:ui';
import 'package:flutter/material.dart';

/// Wraps [child] with an [ImageFiltered] blur and a dark tint.
///
/// Unlike [BackdropFilter], this only blurs the image itself (not the entire
/// scene behind it), and the result is cached by the compositor between frames.
/// This eliminates the per-frame GPU cost that made the old approach a
/// performance bottleneck.
class BlurredBackground extends StatelessWidget {
  const BlurredBackground({super.key, required this.blurLevel, required this.child});

  final double blurLevel;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (blurLevel > 0)
          ImageFiltered(
            imageFilter: ImageFilter.blur(
              sigmaX: blurLevel,
              sigmaY: blurLevel,
              tileMode: TileMode.clamp,
            ),
            child: child,
          )
        else
          child,
        IgnorePointer(
          child: ColoredBox(color: Colors.black.withValues(alpha: 0.5)),
        ),
      ],
    );
  }
}
