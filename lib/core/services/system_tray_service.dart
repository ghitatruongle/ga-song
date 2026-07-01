import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:system_tray/system_tray.dart';
import 'package:window_manager/window_manager.dart';
import '../audio/audio_engine_service.dart';
import '../audio/playlist_service.dart';
import '../logging/app_logger.dart';

class SystemTrayService {
  SystemTrayService({
    AudioEngineService? audioEngineService,
    PlaylistService? playlistService,
  }) : _engine = audioEngineService,
       _playlist = playlistService;

  final AudioEngineService? _engine;
  final PlaylistService? _playlist;
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
            AppLogger.w('system_tray.service', 'icon extraction failed', error: e);
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
            AppLogger.w('system_tray.service', 'icon extraction failed (Linux)', error: e);
          }
        }
        path = iconFile.path;
      }

      final iconFileCheck = File(path);
      if (!iconFileCheck.existsSync()) {
        AppLogger.i('system_tray.service', 'icon not found, skipping init: $path');
        _systemTray = null;
        return;
      }

      await _systemTray!.initSystemTray(title: 'G.A - Song', iconPath: path);
      
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

      _engine?.engineState.addListener(_updateMenu);
    } catch (e, stackTrace) {
      AppLogger.e('system_tray.service', 'SystemTray init failed', error: e);
      AppLogger.d('system_tray.service', 'stack', error: stackTrace);
      _systemTray = null;
    }
  }

  Future<void> _buildMenu() async {
    if (_systemTray == null) return;

    final engineService = _engine;
    final playlistService = _playlist;
    if (engineService == null || playlistService == null) return;

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
            playlistService.play();
          }
        },
      ),
      MenuItemLabel(
        label: 'Next',
        onClicked: (menuItem) => playlistService.next(),
      ),
      MenuItemLabel(
        label: 'Previous',
        onClicked: (menuItem) => playlistService.previous(),
      ),
      MenuSeparator(),
      MenuItemLabel(
        label: 'Exit',
        onClicked: (menuItem) async {
          await windowManager.destroy();
        },
      ),
    ]);

    await _systemTray!.setContextMenu(_menu);
  }

  void _updateMenu() {
    final now = DateTime.now();
    if (now.difference(_lastMenuUpdate).inMilliseconds < 1000) return;
    _lastMenuUpdate = now;
    _buildMenu();
  }

  void dispose() {
    try {
      _engine?.engineState.removeListener(_updateMenu);
    } catch (e, stack) {
      AppLogger.e('system_tray.service', 'operation failed', error: e, stack: stack);
    }
    try {
      _systemTray?.destroy();
    } catch (e) {
      AppLogger.w('system_tray.service', 'dispose failed', error: e);
    }
  }
}
