/// Keyboard Navigation System for G.A - Song
///
/// Provides comprehensive keyboard navigation support:
/// - Tab/Shift+Tab navigation
/// - Enter/Space activation
/// - Escape to dismiss/close
/// - Arrow keys for lists/grids
/// - Custom shortcuts
/// - Focus management

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme_utils.dart';

/// Global keyboard navigation configuration
class KeyboardNavigation {
  static const Duration _focusAnimationDuration = Duration(milliseconds: 150);
  
  /// Wraps a widget with keyboard navigation support
  static Widget navigable({
    required Widget child,
    FocusNode? focusNode,
    bool autofocus = false,
    bool canRequestFocus = true,
    Iterable<LogicalKeyboardKey>? additionalExitKeys,
    VoidCallback? onFocusLost,
    Map<LogicalKeySet, Intent>? shortcuts,
    Map<Type, Action<Intent>>? actions,
  }) {
    return Focus(
      focusNode: focusNode,
      autofocus: autofocus,
      canRequestFocus: canRequestFocus,
      onFocusChange: (hasFocus) {
        if (!hasFocus) onFocusLost?.call();
      },
      child: Shortcuts(
        shortcuts: {
          LogicalKeySet(LogicalKeyboardKey.escape): const DismissIntent(),
          LogicalKeySet(LogicalKeyboardKey.enter): const ActivateIntent(),
          LogicalKeySet(LogicalKeyboardKey.space): const ActivateIntent(),
          LogicalKeySet(LogicalKeyboardKey.tab): const NextFocusIntent(),
          LogicalKeySet(LogicalKeyboardKey.shift, LogicalKeyboardKey.tab): const PreviousFocusIntent(),
          ...?shortcuts,
        },
        child: Actions(
          actions: {
            DismissIntent: CallbackAction<DismissIntent>(onInvoke: (intent) {
              FocusManager.instance.primaryFocus?.unfocus();
              return null;
            }),
            ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (intent) {
              // Handled by individual widgets
              return null;
            }),
            NextFocusIntent: CallbackAction<NextFocusIntent>(onInvoke: (intent) {
              FocusManager.instance.primaryFocus?.nextFocus();
              return null;
            }),
            PreviousFocusIntent: CallbackAction<PreviousFocusIntent>(onInvoke: (intent) {
              FocusManager.instance.primaryFocus?.previousFocus();
              return null;
            }),
            ...?actions,
          },
          child: child,
        ),
      ),
    );
  }
}

/// Intent to dismiss/close current focus
class DismissIntent extends Intent {
  const DismissIntent();
}

/// Intent to activate/click focused widget
class ActivateIntent extends Intent {
  const ActivateIntent();
}

/// Intent to move focus to next widget
class NextFocusIntent extends Intent {
  const NextFocusIntent();
}

/// Intent to move focus to previous widget
class PreviousFocusIntent extends Intent {
  const PreviousFocusIntent();
}

/// Keyboard-aware list tile with proper focus handling
class KeyboardListTile extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onEnter;
  final VoidCallback? onSpace;
  final FocusNode? focusNode;
  final bool autofocus;
  final bool enabled;
  final Color? focusColor;
  final Color? hoverColor;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;

  const KeyboardListTile({
    super.key,
    required this.child,
    this.onTap,
    this.onEnter,
    this.onSpace,
    this.focusNode,
    this.autofocus = false,
    this.enabled = true,
    this.focusColor,
    this.hoverColor,
    this.borderRadius,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final theme = Theme.of(context);
    final effectiveFocusColor = focusColor ?? theme.colorScheme.primary.withValues(alpha: 0.15);
    final effectiveHoverColor = hoverColor ?? theme.colorScheme.primary.withValues(alpha: 0.05);
    final effectiveBorderRadius = borderRadius ?? BorderRadius.circular(8);
    
    return Focus(
      focusNode: focusNode,
      autofocus: autofocus,
      child: KeyboardNavigation.navigable(
        shortcuts: {
          LogicalKeySet(LogicalKeyboardKey.enter): const ActivateIntent(),
          LogicalKeySet(LogicalKeyboardKey.space): const ActivateIntent(),
          LogicalKeySet(LogicalKeyboardKey.arrowDown): const NextFocusIntent(),
          LogicalKeySet(LogicalKeyboardKey.arrowUp): const PreviousFocusIntent(),
        },
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (intent) {
            if (enabled) {
              onEnter?.call();
              onTap?.call();
            }
            return null;
          }),
        },
        child: MouseRegion(
          cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: effectiveBorderRadius,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: enabled ? onTap : null,
                borderRadius: effectiveBorderRadius,
                focusColor: effectiveFocusColor,
                hoverColor: effectiveHoverColor,
                splashColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                highlightColor: theme.colorScheme.primary.withValues(alpha: 0.05),
                child: Padding(
                  padding: padding ?? const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Keyboard-aware grid tile
class KeyboardGridTile extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final FocusNode? focusNode;
  final bool autofocus;
  final bool enabled;
  final Color? focusColor;
  final BorderRadius? borderRadius;

  const KeyboardGridTile({
    super.key,
    required this.child,
    this.onTap,
    this.focusNode,
    this.autofocus = false,
    this.enabled = true,
    this.focusColor,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveFocusColor = focusColor ?? theme.colorScheme.primary.withValues(alpha: 0.15);
    final effectiveBorderRadius = borderRadius ?? BorderRadius.circular(12);
    
    return Focus(
      focusNode: focusNode,
      autofocus: autofocus,
      child: KeyboardNavigation.navigable(
        shortcuts: {
          LogicalKeySet(LogicalKeyboardKey.enter): const ActivateIntent(),
          LogicalKeySet(LogicalKeyboardKey.space): const ActivateIntent(),
          LogicalKeySet(LogicalKeyboardKey.arrowRight): const NextFocusIntent(),
          LogicalKeySet(LogicalKeyboardKey.arrowLeft): const PreviousFocusIntent(),
          LogicalKeySet(LogicalKeyboardKey.arrowDown): const NextFocusIntent(),
          LogicalKeySet(LogicalKeyboardKey.arrowUp): const PreviousFocusIntent(),
        },
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (intent) {
            if (enabled) onTap?.call();
            return null;
          }),
        },
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: enabled ? onTap : null,
            borderRadius: effectiveBorderRadius,
            focusColor: effectiveFocusColor,
            hoverColor: theme.colorScheme.primary.withValues(alpha: 0.05),
            splashColor: theme.colorScheme.primary.withValues(alpha: 0.1),
            highlightColor: theme.colorScheme.primary.withValues(alpha: 0.05),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Focus scope for modal dialogs and overlays
class FocusScopeWidget extends StatelessWidget {
  final Widget child;
  final FocusScopeNode? focusNode;
  final bool autofocus;
  final VoidCallback? onFocusLost;

  const FocusScopeWidget({
    super.key,
    required this.child,
    this.focusNode,
    this.autofocus = true,
    this.onFocusLost,
  });

  @override
  Widget build(BuildContext context) {
    return FocusScope(
      node: focusNode ?? FocusScopeNode(),
      autofocus: autofocus,
      onFocusChange: (hasFocus) {
        if (!hasFocus) onFocusLost?.call();
      },
      child: child,
    );
  }
}

/// Focus trap for modals - prevents focus from escaping
class FocusTrap extends StatefulWidget {
  final Widget child;
  final FocusScopeNode? focusNode;
  final bool enabled;

  const FocusTrap({
    super.key,
    required this.child,
    this.focusNode,
    this.enabled = true,
  });

  @override
  State<FocusTrap> createState() => _FocusTrapState();
}

class _FocusTrapState extends State<FocusTrap> {
  late FocusScopeNode _focusNode;
  FocusNode? _previousFocus;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusScopeNode();
    _previousFocus = FocusManager.instance.primaryFocus;
    
    // Request focus on first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.enabled) {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    // Restore previous focus when trap is removed
    if (widget.enabled && _previousFocus != null) {
      _previousFocus!.requestFocus();
    }
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;
    
    return FocusScope(
      node: _focusNode,
      onFocusChange: (hasFocus) {
        // Could add logic here if needed
      },
      child: FocusTraversalGroup(
        policy: WidgetOrderTraversalPolicy(),
        child: widget.child,
      ),
    );
  }
}

/// Skip to main content link (accessibility)
class SkipToMainContent extends StatelessWidget {
  final String mainContentId;
  final String label;
  
  const SkipToMainContent({
    super.key,
    this.mainContentId = 'main-content',
    this.label = 'Skip to main content',
  });

  @override
  Widget build(BuildContext context) {
    return Focus(
      child: Container(
        color: Theme.of(context).colorScheme.primary,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

/// Keyboard shortcut help dialog
class KeyboardShortcutsDialog extends StatelessWidget {
  final List<KeyboardShortcut> shortcuts;
  final String title;
  
  const KeyboardShortcutsDialog({
    super.key,
    required this.shortcuts,
    this.title = 'Keyboard Shortcuts',
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final adaptiveColor = context.adaptive;
    
    return AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: 400,
        child: ListView.separated(
          shrinkWrap: true,
          itemCount: shortcuts.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final shortcut = shortcuts[index];
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: _KeyCombination(keys: shortcut.keys),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 3,
                    child: Text(
                      shortcut.description,
                      style: TextStyle(color: adaptiveColor.withValues(alpha: 0.8)),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

class KeyboardShortcut {
  final List<LogicalKeyboardKey> keys;
  final String description;
  
  const KeyboardShortcut({
    required this.keys,
    required this.description,
  });
}

class _KeyCombination extends StatelessWidget {
  final List<LogicalKeyboardKey> keys;
  
  const _KeyCombination({required this.keys});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final adaptiveColor = context.adaptive;
    
    return Wrap(
      spacing: 4,
      children: keys.map((key) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isDark ? Colors.white12 : Colors.black12,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: adaptiveColor.withValues(alpha: 0.2)),
        ),
        child: Text(
          _keyToString(key),
          style: TextStyle(
            fontSize: 12,
            fontFamily: 'monospace',
            fontWeight: FontWeight.w500,
            color: adaptiveColor,
          ),
        ),
      )).toList(),
    );
  }

  String _keyToString(LogicalKeyboardKey key) {
    if (key == LogicalKeyboardKey.control) return 'Ctrl';
    if (key == LogicalKeyboardKey.alt) return 'Alt';
    if (key == LogicalKeyboardKey.shift) return 'Shift';
    if (key == LogicalKeyboardKey.meta) return '⌘';
    if (key == LogicalKeyboardKey.enter) return 'Enter';
    if (key == LogicalKeyboardKey.space) return 'Space';
    if (key == LogicalKeyboardKey.escape) return 'Esc';
    if (key == LogicalKeyboardKey.tab) return 'Tab';
    if (key == LogicalKeyboardKey.arrowUp) return '↑';
    if (key == LogicalKeyboardKey.arrowDown) return '↓';
    if (key == LogicalKeyboardKey.arrowLeft) return '←';
    if (key == LogicalKeyboardKey.arrowRight) return '→';
    if (key == LogicalKeyboardKey.f1) return 'F1';
    if (key == LogicalKeyboardKey.f2) return 'F2';
    if (key == LogicalKeyboardKey.f3) return 'F3';
    if (key == LogicalKeyboardKey.f4) return 'F4';
    if (key == LogicalKeyboardKey.f5) return 'F5';
    if (key == LogicalKeyboardKey.f6) return 'F6';
    if (key == LogicalKeyboardKey.f7) return 'F7';
    if (key == LogicalKeyboardKey.f8) return 'F8';
    if (key == LogicalKeyboardKey.f9) return 'F9';
    if (key == LogicalKeyboardKey.f10) return 'F10';
    if (key == LogicalKeyboardKey.f11) return 'F11';
    if (key == LogicalKeyboardKey.f12) return 'F12';
    return key.keyLabel;
  }
}

/// Global keyboard shortcut handler
class GlobalKeyboardShortcuts extends StatelessWidget {
  final Widget child;
  final Map<LogicalKeySet, VoidCallback> shortcuts;
  final bool enabled;
  
  const GlobalKeyboardShortcuts({
    super.key,
    required this.child,
    required this.shortcuts,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;
    
    return Shortcuts(
      shortcuts: shortcuts.map(
        (keySet, callback) => MapEntry(
          keySet,
          _CallbackIntent(callback),
        ),
      ),
      child: Actions(
        actions: {
          _CallbackIntent: CallbackAction<_CallbackIntent>(
            onInvoke: (intent) => intent.callback(),
          ),
        },
        child: Focus(
          autofocus: true,
          child: child,
        ),
      ),
    );
  }
}

class _CallbackIntent extends Intent {
  final VoidCallback callback;
  
  const _CallbackIntent(this.callback);
}