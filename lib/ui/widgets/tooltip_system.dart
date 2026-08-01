/// Unified Tooltip System for G.A - Song
///
/// Provides consistent tooltips across the app with support for:
/// - Hover (desktop)
/// - Long press (mobile/touch)
/// - Keyboard focus
/// - Custom positioning and styling

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme_utils.dart';

/// Global tooltip theme configuration
class AppTooltipTheme {
  static const Duration _showDuration = Duration(milliseconds: 500);
  static const Duration _hideDuration = Duration(milliseconds: 200);
  static const double _verticalOffset = 8.0;
  static const double _horizontalOffset = 0.0;
  
  /// Creates a tooltip with app-standard styling
  static Widget tooltip({
    required Widget child,
    required String message,
    TooltipPosition position = TooltipPosition.top,
    Duration? showDuration,
    Duration? hideDuration,
    bool preferBelow = false,
    EdgeInsetsGeometry? padding,
    TextStyle? textStyle,
    Decoration? decoration,
    double? height,
    bool excludeFromSemantics = false,
    Widget? triggerWidget,
  }) {
    return Tooltip(
      message: message,
      child: child,
      triggerMode: TooltipTriggerMode.tap,
      showDuration: showDuration ?? _showDuration,
      waitDuration: const Duration(milliseconds: 300),
      textStyle: textStyle ?? const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: Colors.white,
        height: 1.3,
      ),
      decoration: decoration ?? BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      verticalOffset: _verticalOffset,
      preferBelow: preferBelow,
      excludeFromSemantics: excludeFromSemantics,
      richMessage: null,
    );
  }
}

/// Tooltip positions
enum TooltipPosition {
  top,
  bottom,
  left,
  right,
}

/// Custom tooltip with more control over appearance and behavior
class AppTooltip extends StatefulWidget {
  final Widget child;
  final String message;
  final TooltipPosition position;
  final Duration showDelay;
  final Duration hideDelay;
  final EdgeInsetsGeometry? padding;
  final TextStyle? textStyle;
  final Color? backgroundColor;
  final double borderRadius;
  final double offset;
  final bool showOnHover;
  final bool showOnLongPress;
  final bool showOnFocus;
  final VoidCallback? onTooltipVisible;
  final VoidCallback? onTooltipHidden;

  const AppTooltip({
    super.key,
    required this.child,
    required this.message,
    this.position = TooltipPosition.top,
    this.showDelay = const Duration(milliseconds: 300),
    this.hideDelay = const Duration(milliseconds: 200),
    this.padding,
    this.textStyle,
    this.backgroundColor,
    this.borderRadius = 8,
    this.offset = 8,
    this.showOnHover = true,
    this.showOnLongPress = true,
    this.showOnFocus = true,
    this.onTooltipVisible,
    this.onTooltipHidden,
  });

  @override
  State<AppTooltip> createState() => _AppTooltipState();
}

class _AppTooltipState extends State<AppTooltip> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  Timer? _showTimer;
  Timer? _hideTimer;
  bool _isTooltipVisible = false;

  @override
  void dispose() {
    _showTimer?.cancel();
    _hideTimer?.cancel();
    _removeOverlay();
    super.dispose();
  }

  void _showTooltip() {
    if (_isTooltipVisible || _overlayEntry != null) return;
    
    _showTimer?.cancel();
    _showTimer = Timer(widget.showDelay, () {
      if (!mounted || _isTooltipVisible) return;
      _insertOverlay();
      _isTooltipVisible = true;
      widget.onTooltipVisible?.call();
    });
  }

  void _hideTooltip() {
    _showTimer?.cancel();
    _hideTimer?.cancel();
    _hideTimer = Timer(widget.hideDelay, () {
      _removeOverlay();
      _isTooltipVisible = false;
      widget.onTooltipHidden?.call();
    });
  }

  void _insertOverlay() {
    _overlayEntry = OverlayEntry(
      builder: (context) => _TooltipOverlay(
        layerLink: _layerLink,
        message: widget.message,
        position: widget.position,
        padding: widget.padding ?? const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        textStyle: widget.textStyle ?? const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: Colors.white,
          height: 1.3,
        ),
        backgroundColor: widget.backgroundColor ?? Colors.black87,
        borderRadius: widget.borderRadius,
        offset: widget.offset,
      ),
    );
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: MouseRegion(
        onEnter: widget.showOnHover ? (_) => _showTooltip() : null,
        onExit: widget.showOnHover ? (_) => _hideTooltip() : null,
        child: GestureDetector(
          onLongPress: widget.showOnLongPress ? _showTooltip : null,
          onLongPressUp: widget.showOnLongPress ? _hideTooltip : null,
          onLongPressEnd: widget.showOnLongPress ? (_) => _hideTooltip() : null,
          child: Focus(
            onFocusChange: widget.showOnFocus ? (hasFocus) {
              if (hasFocus) _showTooltip();
              else _hideTooltip();
            } : null,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

/// Internal tooltip overlay widget
class _TooltipOverlay extends StatelessWidget {
  final LayerLink layerLink;
  final String message;
  final TooltipPosition position;
  final EdgeInsetsGeometry padding;
  final TextStyle textStyle;
  final Color backgroundColor;
  final double borderRadius;
  final double offset;

  const _TooltipOverlay({
    required this.layerLink,
    required this.message,
    required this.position,
    required this.padding,
    required this.textStyle,
    required this.backgroundColor,
    required this.borderRadius,
    required this.offset,
  });

  @override
  Widget build(BuildContext context) {
    return CompositedTransformFollower(
      link: layerLink,
      showWhenUnlinked: false,
      offset: _getOffset(),
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(borderRadius),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            message,
            style: textStyle,
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Offset _getOffset() {
    switch (position) {
      case TooltipPosition.top:
        return Offset(0, -offset);
      case TooltipPosition.bottom:
        return Offset(0, offset);
      case TooltipPosition.left:
        return Offset(-offset, 0);
      case TooltipPosition.right:
        return Offset(offset, 0);
    }
  }
}

/// Tooltip wrapper for icon buttons with semantic labels
class IconTooltip extends StatelessWidget {
  final Widget icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final Color? iconColor;
  final double iconSize;
  final EdgeInsetsGeometry? padding;
  final TooltipPosition position;
  final String? semanticLabel;

  const IconTooltip({
    super.key,
    required this.icon,
    required this.tooltip,
    this.onPressed,
    this.iconColor,
    this.iconSize = 20,
    this.padding,
    this.position = TooltipPosition.top,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    return AppTooltip(
      message: tooltip,
      position: position,
      child: IconButton(
        icon: Icon(icon as IconData?, color: iconColor, size: iconSize),
        onPressed: onPressed,
        padding: padding ?? EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
        tooltip: semanticLabel,
      ),
    );
  }
}

/// Rich tooltip with custom content
class RichTooltip extends StatelessWidget {
  final Widget child;
  final Widget tooltipContent;
  final TooltipPosition position;
  final Duration showDelay;
  final Duration hideDelay;
  final double offset;
  final Color? backgroundColor;
  final double borderRadius;

  const RichTooltip({
    super.key,
    required this.child,
    required this.tooltipContent,
    this.position = TooltipPosition.top,
    this.showDelay = const Duration(milliseconds: 300),
    this.hideDelay = const Duration(milliseconds: 200),
    this.offset = 8,
    this.backgroundColor,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return AppTooltip(
      message: '', // Not used for rich tooltip
      position: position,
      showDelay: showDelay,
      hideDelay: hideDelay,
      offset: offset,
      backgroundColor: backgroundColor,
      borderRadius: borderRadius,
      child: child,
    );
  }
}