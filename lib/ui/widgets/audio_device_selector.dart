import 'package:flutter/material.dart';
import 'package:flutter_soloud/flutter_soloud.dart';

import '../../core/theme_utils.dart';

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

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 400),
      child: Padding(
        padding: const EdgeInsets.all(24),
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
                const SizedBox(width: 12),
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
            const SizedBox(height: 16),

            // Content
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_error != null)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.orange),
                      const SizedBox(height: 16),
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
                  padding: const EdgeInsets.all(32),
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
                    );
                  },
                ),
              ),

            // Default device button
            if (_devices.isNotEmpty) ...[
              const SizedBox(height: 16),
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

  const _DeviceTile({
    required this.device,
    required this.isSelected,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isSelected
            ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
            : (isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF5F5F5)),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)
              : (isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE5E5E5)),
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
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      ),
    );
  }
}
