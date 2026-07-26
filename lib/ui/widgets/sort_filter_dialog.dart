// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/service_providers.dart';
import '../../core/theme/tokens.dart';

class SortFilterDialog {
  static void show(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (context) => const _SortFilterDialog(),
    );
  }
}

class _SortFilterDialog extends ConsumerStatefulWidget {
  const _SortFilterDialog();

  @override
  ConsumerState<_SortFilterDialog> createState() => _SortFilterDialogState();
}

class _SortFilterDialogState extends ConsumerState<_SortFilterDialog> {
  late final _settings = ref.read(settingsManagerProvider);

  static const _sortOptions = [
    {'icon': Icons.sort_by_alpha, 'label': 'Tên bài hát', 'value': 0},
    {'icon': Icons.person_outline, 'label': 'Nghệ sĩ', 'value': 1},
    {'icon': Icons.calendar_today, 'label': 'Ngày thêm', 'value': 2},
    {'icon': Icons.timer_outlined, 'label': 'Thời lượng', 'value': 3},
  ];

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).brightness == Brightness.dark
        ? Colors.white
        : Colors.black87;
    final bgColor = Theme.of(context).brightness == Brightness.dark
        ? AppColors.darkSurface
        : AppColors.lightSurface;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: RepaintBoundary(
        child: Container(
          width: 400,
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
                  Icon(Icons.sort, color: textColor, size: 24),
                  const SizedBox(width: 12),
                  Text(
                    'Sắp xếp & Lọc',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'Sắp xếp theo',
                style: TextStyle(
                  color: textColor.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              ValueListenableBuilder<int>(
                valueListenable: _settings.sortModeNotifier,
                builder: (context, currentMode, _) {
                  return Column(
                    children: _sortOptions.map((option) {
                      final isSelected = currentMode == option['value'];
                      return RadioListTile<int>(
                        value: option['value'] as int,
                        groupValue: currentMode,
                        onChanged: (value) {
                          if (value != null) {
                            _settings.setSortMode(value);
                          }
                        },
                        title: Row(
                          children: [
                            Icon(
                              option['icon'] as IconData,
                              color: isSelected
                                  ? Theme.of(context).primaryColor
                                  : textColor.withValues(alpha: 0.7),
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              option['label'] as String,
                              style: TextStyle(
                                color: isSelected
                                    ? Theme.of(context).primaryColor
                                    : textColor,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                        activeColor: Theme.of(context).primaryColor,
                        dense: true,
                      );
                    }).toList(),
                  );
                },
              ),
              const SizedBox(height: 16),
              ValueListenableBuilder<bool>(
                valueListenable: _settings.sortAscendingNotifier,
                builder: (context, ascending, _) {
                  return SwitchListTile(
                    title: Row(
                      children: [
                        Icon(
                          ascending ? Icons.arrow_upward : Icons.arrow_downward,
                          color: textColor.withValues(alpha: 0.7),
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          ascending ? 'Tăng dần' : 'Giảm dần',
                          style: TextStyle(color: textColor),
                        ),
                      ],
                    ),
                    value: ascending,
                    activeThumbColor: Theme.of(context).primaryColor,
                    onChanged: (value) => _settings.setSortAscending(value),
                    dense: true,
                  );
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: textColor,
                  foregroundColor: bgColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  minimumSize: const Size(double.infinity, 44),
                  elevation: 0,
                ),
                child: const Text(
                  'Xong',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
