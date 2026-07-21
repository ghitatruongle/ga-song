import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/tokens.dart';
import '../../providers/service_providers.dart';
import '../utils/theme_helpers.dart';

class CustomHotkeysDialog {
  static void show(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (context) => const _CustomHotkeysDialog(),
    );
  }
}

class _CustomHotkeysDialog extends ConsumerStatefulWidget {
  const _CustomHotkeysDialog();

  @override
  ConsumerState<_CustomHotkeysDialog> createState() =>
      _CustomHotkeysDialogState();
}

class _CustomHotkeysDialogState extends ConsumerState<_CustomHotkeysDialog> {
  late final _settings = ref.read(settingsManagerProvider);
  late final FocusNode _focusNode;

  static const _hotkeyActions = [
    {
      'action': 'playPause',
      'label': 'Phát / Tạm dừng',
      'defaultKey': 'Alt + Space',
    },
    {
      'action': 'next',
      'label': 'Bài tiếp theo',
      'defaultKey': 'Alt + ArrowRight',
    },
    {
      'action': 'previous',
      'label': 'Bài trước đó',
      'defaultKey': 'Alt + ArrowLeft',
    },
    {
      'action': 'volumeUp',
      'label': 'Tăng âm lượng',
      'defaultKey': 'Alt + ArrowUp',
    },
    {
      'action': 'volumeDown',
      'label': 'Giảm âm lượng',
      'defaultKey': 'Alt + ArrowDown',
    },
  ];

  String? _editingAction;
  String _capturedKeys = '';

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).brightness == Brightness.dark
        ? Colors.white
        : Colors.black87;
    final bgColor = AppColors.adaptive(
      context,
      dark: AppColors.darkSurface,
      light: Colors.white,
    );
    final spacing = ThemeSpacing.of(context);
    final radius = ThemeRadius.of(context);

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: RepaintBoundary(
        child: Container(
          width: 480,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: bgColor.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(AppRadius.lg + 4),
            border: Border.all(color: textColor.withValues(alpha: 0.1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 30,
                offset: const Offset(0, 15),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(Icons.keyboard, color: textColor, size: 24),
                  SizedBox(width: spacing.sm + spacing.xxs),
                  Text(
                    'Tùy chỉnh Phím tắt',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Nhấn phím bạn muốn gán cho mỗi hành động',
                style: TextStyle(
                  color: textColor.withValues(alpha: 0.6),
                  fontSize: 13,
                ),
              ),
              SizedBox(height: spacing.lg - spacing.xs),
              ValueListenableBuilder<Map<String, String>>(
                valueListenable: _settings.customHotkeysNotifier,
                builder: (context, hotkeys, _) {
                  return Column(
                    children: _hotkeyActions.map((action) {
                      final actionKey = action['action'] as String;
                      final currentKey =
                          hotkeys[actionKey] ?? action['defaultKey'] as String;
                      final isEditing = _editingAction == actionKey;

                      return Container(
                        margin: EdgeInsets.only(
                          bottom: spacing.sm + spacing.xxs,
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: spacing.md,
                          vertical: spacing.sm + spacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: isEditing
                              ? Theme.of(
                                  context,
                                ).primaryColor.withValues(alpha: 0.1)
                              : textColor.withValues(alpha: 0.05),
                          borderRadius: radius.circular(),
                          border: Border.all(
                            color: isEditing
                                ? Theme.of(context).primaryColor
                                : textColor.withValues(alpha: 0.1),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                action['label'] as String,
                                style: TextStyle(color: textColor),
                              ),
                            ),
                            if (isEditing)
                              _buildKeyCaptureField(textColor)
                            else
                              InkWell(
                                onTap: () =>
                                    setState(() => _editingAction = actionKey),
                                borderRadius: BorderRadius.circular(
                                  AppRadius.sm,
                                ),
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: spacing.sm + spacing.xxs,
                                    vertical: AppSpacing.sm,
                                  ),
                                  decoration: BoxDecoration(
                                    color: textColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(
                                      AppRadius.sm,
                                    ),
                                  ),
                                  child: Text(
                                    currentKey,
                                    style: TextStyle(
                                      color: textColor,
                                      fontFamily: 'monospace',
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ),
                            if (hotkeys.containsKey(actionKey))
                              IconButton(
                                icon: Icon(
                                  Icons.close,
                                  color: AppColors.danger.withValues(
                                    alpha: 0.7,
                                  ),
                                  size: 18,
                                ),
                                onPressed: () =>
                                    _settings.removeCustomHotkey(actionKey),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                          ],
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Mẹo: Sử dụng phím Alt, Ctrl, Shift kết hợp với phím khác',
                style: TextStyle(
                  color: textColor.withValues(alpha: 0.5),
                  fontSize: 12,
                ),
              ),
              SizedBox(height: spacing.md),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: textColor,
                        side: BorderSide(
                          color: textColor.withValues(alpha: 0.3),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.sm + 2),
                        ),
                        minimumSize: const Size(double.infinity, 44),
                      ),
                      child: const Text('Đóng'),
                    ),
                  ),
                  SizedBox(width: spacing.sm + spacing.xxs),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.sm + 2),
                        ),
                        minimumSize: const Size(double.infinity, 44),
                        elevation: 0,
                      ),
                      child: const Text('Lưu'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKeyCaptureField(Color textColor) {
    return KeyboardListener(
      focusNode: _focusNode..requestFocus(),
      onKeyEvent: (event) {
        if (event is KeyDownEvent) {
          final key = event.logicalKey;
          if (key == LogicalKeyboardKey.escape) {
            setState(() {
              _editingAction = null;
              _capturedKeys = '';
            });
            return;
          }

          final modifiers = <String>[];
          if (HardwareKeyboard.instance.isAltPressed) modifiers.add('Alt');
          if (HardwareKeyboard.instance.isControlPressed) modifiers.add('Ctrl');
          if (HardwareKeyboard.instance.isShiftPressed) modifiers.add('Shift');

          final keyLabel = event.logicalKey.keyLabel;
          if (keyLabel.isNotEmpty &&
              !['Alt', 'Control', 'Shift'].contains(keyLabel)) {
            final keys = [...modifiers, keyLabel].join(' + ');

            // Check for conflicts with other actions
            final currentHotkeys = _settings.customHotkeysNotifier.value;
            for (final entry in currentHotkeys.entries) {
              if (entry.key != _editingAction && entry.value == keys) {
                // Conflict detected
                setState(() {
                  _capturedKeys = '';
                  _editingAction = null;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Phím tắt "$keys" đã được gán cho hành động khác',
                    ),
                    duration: const Duration(seconds: 2),
                  ),
                );
                return;
              }
            }

            setState(() {
              _capturedKeys = keys;
              if (_editingAction != null) {
                _settings.setCustomHotkey(_editingAction!, keys);
                _editingAction = null;
              }
            });
          }
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: Theme.of(context).primaryColor),
        ),
        child: Text(
          _capturedKeys.isEmpty ? 'Nhấn phím...' : _capturedKeys,
          style: TextStyle(
            color: Theme.of(context).primaryColor,
            fontFamily: 'monospace',
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
