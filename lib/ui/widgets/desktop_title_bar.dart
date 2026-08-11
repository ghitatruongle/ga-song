import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart' hide WindowCaptionButton;
import 'window_caption_button.dart';

/// Q-3 fix: Shared desktop title bar widget.
/// Replaces 4 duplicate implementations across home_screen, main_content,
/// settings_widget, and visualizer_widget.
///
/// Returns an empty [SizedBox] on mobile/web platforms.
/// On desktop, renders a [DragToMoveArea] with minimize/maximize/close buttons.
class DesktopTitleBar extends StatelessWidget {
  const DesktopTitleBar({super.key, this.iconColor, this.height = 50});

  /// Color for the window control icons.
  /// Defaults to the current theme's adaptive color if null.
  final Color? iconColor;

  /// Height of the title bar area.
  final double height;

  @override
  Widget build(final BuildContext context) {
    if (kIsWeb ||
        defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS) {
      return SizedBox(height: height);
    }

    final color = iconColor ?? _defaultIconColor(context);

    return DragToMoveArea(
      child: SizedBox(
        height: height,
        child: Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              WindowCaptionButton.minimize(
                onPressed: () async => windowManager.minimize(),
                iconNormal: Icon(Icons.remove, color: color, size: 20),
              ),
              const SizedBox(width: 8),
              WindowCaptionButton.maximize(
                onPressed: () async {
                  if (await windowManager.isMaximized()) {
                    await windowManager.unmaximize();
                  } else {
                    await windowManager.maximize();
                  }
                },
                iconNormal: Icon(Icons.crop_square, color: color, size: 18),
              ),
              const SizedBox(width: 8),
              WindowCaptionButton.close(
                onPressed: () async => windowManager.close(),
                iconNormal: Icon(Icons.close, color: color, size: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Color _defaultIconColor(final BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark ? Colors.white : Colors.black87;
  }
}
