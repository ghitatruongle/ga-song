import 'package:flutter/material.dart';
import '../../core/theme_utils.dart';

class WindowCaptionButton extends StatelessWidget {
  const WindowCaptionButton.minimize({
    super.key,
    required this.onPressed,
    required this.iconNormal,
  });

  const WindowCaptionButton.maximize({
    super.key,
    required this.onPressed,
    required this.iconNormal,
  });

  const WindowCaptionButton.close({
    super.key,
    required this.onPressed,
    required this.iconNormal,
  });

  final VoidCallback onPressed;
  final Icon iconNormal;

  @override
  Widget build(final BuildContext context) => MouseRegion(
    cursor: SystemMouseCursors.click,
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        hoverColor: context.adaptive.withValues(alpha: 0.12),
        splashColor: context.adaptive.withValues(alpha: 0.15),
        focusColor: context.adaptive.withValues(alpha: 0.1),
        child: Padding(padding: const EdgeInsets.all(8), child: iconNormal),
      ),
    ),
  );
}
