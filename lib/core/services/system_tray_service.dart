import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:system_tray/system_tray.dart';
import 'package:window_manager/window_manager.dart';
import '../service_locator.dart';
import '../audio/audio_engine_service.dart';
import '../audio/playlist_service.dart';

class SystemTrayService {
  SystemTray? _systemTray;
  final AppWindow _appWindow = AppWindow();
  final Menu _menu = Menu();
  DateTime _lastMenuUpdate = DateTime(2000);

  Future<void> init() async {
    if (kIsWeb || (!Platform.isWindows && !Platform.isMacOS && !Platform.isLinux)) {
      return;
    }

    try {
      _systemTray = SystemTray();
      String path = Platform.isWindows
          ? 'assets/pic/app_icon.ico'
          : 'assets/pic/app_logo.png';

      if (Platform.isWindows) {
        final iconFile = File('${Directory.systemTemp.path}\\ga_song_app_icon.ico');
        final needsWrite = !iconFile.existsSync() || iconFile.lengthSync() == 0;
        if (needsWrite) {
          try {
            final byteData = await rootBundle.load(path);
            await iconFile.writeAsBytes(byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes), flush: true);
          } catch (e) {
            debugPrint("System tray icon extraction failed: $e");
          }
        }
        path = iconFile.path;
      }

      // Linux: cần copy icon từ assets vào temp giống Windows
      if (Platform.isLinux) {
        final iconFile = File('${Directory.systemTemp.path}/ga_song_app_icon.png');
        final needsWrite = !iconFile.existsSync() || iconFile.lengthSync() == 0;
        if (needsWrite) {
          try {
            final byteData = await rootBundle.load(path);
            await iconFile.writeAsBytes(byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes), flush: true);
          } catch (e) {
            debugPrint("System tray icon extraction failed (Linux): $e");
          }
        }
        path = iconFile.path;
      }

      final iconFileCheck = File(path);
      if (!iconFileCheck.existsSync()) {
        debugPrint("System tray icon not found at $path, skipping system tray initialization");
        _systemTray = null;
        return;
      }

      await _systemTray!.initSystemTray(title: "G.A - Song", iconPath: path);
      
      await _buildMenu();

      _systemTray!.registerSystemTrayEventHandler((eventName) {
        if (eventName == kSystemTrayEventClick) {
          Platform.isWindows
              ? _appWindow.show()
              : _systemTray!.popUpContextMenu();
        } else if (eventName == kSystemTrayEventRightClick) {
          Platform.isWindows
              ? _systemTray!.popUpContextMenu()
              : _appWindow.show();
        }
      });

      sl<AudioEngineService>().engineState.addListener(_updateMenu);
    } catch (e, stackTrace) {
      debugPrint("SystemTray init failed: $e");
      debugPrint("Stack trace: $stackTrace");
      _systemTray = null;
    }
  }

  Future<void> _buildMenu() async {
    if (_systemTray == null) return;

    final engineService = sl<AudioEngineService>();
    final isPlaying = engineService.engineState.value == AudioEngineState.playing;

    await _menu.buildFrom([
      MenuItemLabel(
        label: 'Show',
        onClicked: (menuItem) => _appWindow.show(),
      ),
      MenuItemLabel(
        label: 'Hide',
        onClicked: (menuItem) => _appWindow.hide(),
      ),
      MenuSeparator(),
      MenuItemLabel(
        label: isPlaying ? 'Pause' : 'Play',
        onClicked: (menuItem) {
          if (isPlaying) {
            engineService.pause();
          } else {
            sl<PlaylistService>().play();
          }
        },
      ),
      MenuItemLabel(
        label: 'Next',
        onClicked: (menuItem) => sl<PlaylistService>().next(),
      ),
      MenuItemLabel(
        label: 'Previous',
        onClicked: (menuItem) => sl<PlaylistService>().previous(),
      ),
      MenuSeparator(),
      MenuItemLabel(
        label: 'Exit',
        onClicked: (menuItem) async {
          await teardownServices();
          await windowManager.destroy();
        },
      ),
    ]);

    await _systemTray!.setContextMenu(_menu);
  }

  void _updateMenu() {
    // Throttle: chỉ rebuild menu tối đa 1 lần/giây
    final now = DateTime.now();
    if (now.difference(_lastMenuUpdate).inMilliseconds < 1000) return;
    _lastMenuUpdate = now;
    _buildMenu();
  }

  void dispose() {
    try {
      sl<AudioEngineService>().engineState.removeListener(_updateMenu);
    } catch (e, stack) { debugPrint('Error in system_tray_service: $e\n$stack'); }
    try {
      _systemTray?.destroy();
    } catch (e) {
      debugPrint('SystemTray dispose error: $e');
    }
  }
}
