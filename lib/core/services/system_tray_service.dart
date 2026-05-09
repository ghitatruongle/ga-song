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

      final iconFileCheck = File(path);
      if (!iconFileCheck.existsSync()) {
        debugPrint("System tray icon not found at $path, skipping system tray initialization");
        _systemTray = null;
        return;
      }

      await _systemTray!.initSystemTray(title: "G.A - Song", iconPath: path);
      
      final Menu menu = Menu();
      await menu.buildFrom([
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
          label: 'Play/Pause',
          onClicked: (menuItem) {
            final engineService = sl<AudioEngineService>();
            if (engineService.engineState.value == AudioEngineState.playing) {
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

      await _systemTray!.setContextMenu(menu);

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
    } catch (e, stackTrace) {
      debugPrint("SystemTray init failed: $e");
      debugPrint("Stack trace: $stackTrace");
      _systemTray = null;
    }
  }

  void dispose() {
    _systemTray?.destroy();
  }
}
