import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/service_locator.dart';
import '../../core/settings_manager.dart';

class CustomHotkeysDialog {
  static void show(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (context) => const _CustomHotkeysDialog(),
    );
  }
}

class _CustomHotkeysDialog extends StatefulWidget {
  const _CustomHotkeysDialog();

  @override
  State<_CustomHotkeysDialog> createState() => _CustomHotkeysDialogState();
}

class _CustomHotkeysDialogState extends State<_CustomHotkeysDialog> {
  final _settings = sl<SettingsManager>();
  late final FocusNode _focusNode;

  static const _hotkeyActions = [
    {'action': 'playPause', 'label': 'Phát / Tạm dừng', 'defaultKey': 'Alt + Space'},
    {'action': 'next', 'label': 'Bài tiếp theo', 'defaultKey': 'Alt + ArrowRight'},
    {'action': 'previous', 'label': 'Bài trước đó', 'defaultKey': 'Alt + ArrowLeft'},
    {'action': 'volumeUp', 'label': 'Tăng âm lượng', 'defaultKey': 'Alt + ArrowUp'},
    {'action': 'volumeDown', 'label': 'Giảm âm lượng', 'defaultKey': 'Alt + ArrowDown'},
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
    final textColor = Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87;
    final bgColor = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF1E1E1E)
        : Colors.white;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: RepaintBoundary(
        child: Container(
          width: 480,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: bgColor.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(20),
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
                  const SizedBox(width: 12),
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
              const SizedBox(height: 8),
              Text(
                'Nhấn phím bạn muốn gán cho mỗi hành động',
                style: TextStyle(color: textColor.withValues(alpha: 0.6), fontSize: 13),
              ),
              const SizedBox(height: 20),
              ValueListenableBuilder<Map<String, String>>(
                valueListenable: _settings.customHotkeysNotifier,
                builder: (context, hotkeys, _) {
                  return Column(
                    children: _hotkeyActions.map((action) {
                      final actionKey = action['action'] as String;
                      final currentKey = hotkeys[actionKey] ?? action['defaultKey'] as String;
                      final isEditing = _editingAction == actionKey;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: isEditing
                              ? Theme.of(context).primaryColor.withValues(alpha: 0.1)
                              : textColor.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
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
                                onTap: () => setState(() => _editingAction = actionKey),
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: textColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
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
                                icon: Icon(Icons.close, color: Colors.red.withValues(alpha: 0.7), size: 18),
                                onPressed: () => _settings.removeCustomHotkey(actionKey),
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
              const SizedBox(height: 8),
              Text(
                'Mẹo: Sử dụng phím Alt, Ctrl, Shift kết hợp với phím khác',
                style: TextStyle(color: textColor.withValues(alpha: 0.5), fontSize: 12),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: textColor,
                        side: BorderSide(color: textColor.withValues(alpha: 0.3)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        minimumSize: const Size(double.infinity, 44),
                      ),
                      child: const Text('Đóng'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
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
          if (keyLabel.isNotEmpty && !['Alt', 'Control', 'Shift'].contains(keyLabel)) {
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
                    content: Text('Phím tắt "$keys" đã được gán cho hành động khác'),
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(8),
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