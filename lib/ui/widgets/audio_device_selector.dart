import 'package:flutter/material.dart';
import 'package:flutter_soloud/flutter_soloud.dart';

import '../../core/theme/tokens.dart';
import '../../core/theme_utils.dart';
import '../utils/theme_helpers.dart';

/// Widget for selecting audio output device (desktop only).
///
/// Lists available playback devices and allows switching between them.
class AudioDeviceSelector extends StatefulWidget {
  const AudioDeviceSelector({super.key});

  static Future<void> show(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (context) => const Dialog(
        child: AudioDeviceSelector(),
      ),
    );
  }

  @override
  State<AudioDeviceSelector> createState() => _AudioDeviceSelectorState();
}

class _AudioDeviceSelectorState extends State<AudioDeviceSelector> {
  List<PlaybackDevice> _devices = [];
  PlaybackDevice? _currentDevice;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDevices();
  }

  Future<void> _loadDevices() async {
    try {
      final soloud = SoLoud.instance;
      if (!soloud.isInitialized) {
        setState(() {
          _error = 'Audio engine chưa khởi tạo';
          _isLoading = false;
        });
        return;
      }

      final devices = soloud.listPlaybackDevices();
      setState(() {
        _devices = devices;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Không thể tải danh sách thiết bị: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _selectDevice(PlaybackDevice? device) async {
    try {
      final soloud = SoLoud.instance;
      soloud.changeDevice(newDevice: device);
      setState(() {
        _currentDevice = device;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              device != null
                  ? 'Đã chuyển sang: ${device.name}'
                  : 'Đã chuyển về thiết bị mặc định',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi chuyển thiết bị: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final spacing = ThemeSpacing.of(context);
    final radius = ThemeRadius.of(context);

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 400),
      child: Padding(
        padding: EdgeInsets.all(spacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Title
            Row(
              children: [
                Icon(
                  Icons.speaker_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                SizedBox(width: spacing.sm + spacing.xxs),
                Text(
                  'Thiết bị âm thanh',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: context.adaptive,
                  ),
                ),
              ],
            ),
            SizedBox(height: spacing.md),

            // Content
            if (_isLoading)
              Center(
                child: Padding(
                  padding: EdgeInsets.all(spacing.xl),
                  child: const CircularProgressIndicator(),
                ),
              )
            else if (_error != null)
              Center(
                child: Padding(
                  padding: EdgeInsets.all(spacing.xl),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.orange),
                      SizedBox(height: spacing.md),
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: context.adaptive.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else if (_devices.isEmpty)
              Center(
                child: Padding(
                  padding: EdgeInsets.all(spacing.xl),
                  child: Text(
                    'Không tìm thấy thiết bị âm thanh',
                    style: TextStyle(
                      color: context.adaptive.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              )
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _devices.length,
                  itemBuilder: (context, index) {
                    final device = _devices[index];
                    final isSelected = _currentDevice?.id == device.id;

                    return _DeviceTile(
                      device: device,
                      isSelected: isSelected,
                      onTap: () => _selectDevice(device),
                      isDark: isDark,
                      radius: radius,
                    );
                  },
                ),
              ),

            // Default device button
            if (_devices.isNotEmpty) ...[
              SizedBox(height: spacing.md),
              TextButton.icon(
                onPressed: () => _selectDevice(null),
                icon: const Icon(Icons.settings_backup_restore, size: 18),
                label: const Text('Sử dụng thiết bị mặc định'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DeviceTile extends StatelessWidget {
  final PlaybackDevice device;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDark;
  final ThemeRadius radius;

  const _DeviceTile({
    required this.device,
    required this.isSelected,
    required this.onTap,
    required this.isDark,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    final tileBg = AppColors.adaptive(
      context,
      dark: AppColors.darkSurface,
      light: AppColors.lightSurface2,
    );
    final tileBorder = AppColors.adaptive(
      context,
      dark: AppColors.darkSurface2,
      light: AppColors.lightBorder,
    );
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: isSelected
            ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
            : tileBg,
        borderRadius: radius.circular(),
        border: Border.all(
          color: isSelected
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)
              : tileBorder,
        ),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: ListTile(
        leading: Icon(
          isSelected ? Icons.check_circle : Icons.speaker_outlined,
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : context.adaptive.withValues(alpha: 0.5),
        ),
        title: Text(
          device.name,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: context.adaptive,
          ),
        ),
        subtitle: Text(
          'ID: ${device.id}',
          style: TextStyle(
            fontSize: 12,
            color: context.adaptive.withValues(alpha: 0.4),
          ),
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: radius.circular(),
        ),
      ),
      ),
    );
  }
}
