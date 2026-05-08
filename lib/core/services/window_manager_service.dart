import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import '../service_locator.dart';
import '../settings_manager.dart';

class WindowManagerService with WindowListener {
  Future<void> init() async {
    if (kIsWeb || (!kIsWeb && !(defaultTargetPlatform == TargetPlatform.windows || defaultTargetPlatform == TargetPlatform.linux || defaultTargetPlatform == TargetPlatform.macOS))) {
      return;
    }

    await windowManager.ensureInitialized();

    const windowOptions = WindowOptions(
      size: Size(1000, 700),
      minimumSize: Size(800, 600),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.hidden,
    );

    windowManager.waitUntilReadyToShow(windowOptions, () async {
      if (!kDebugMode) {
        await windowManager.setPreventClose(true);
      }
      
      // Restore previous window position if available
      final savedPosition = sl<SettingsManager>().savedWindowPosition;
      if (savedPosition != null) {
        try {
          await windowManager.setPosition(savedPosition);
        } catch (e) {
          debugPrint('Failed to restore window position: $e');
        }
      }
      
      // C3 fix: also restore the saved window size
      final savedSize = sl<SettingsManager>().savedWindowSize;
      if (savedSize != null) {
        try {
          await windowManager.setSize(savedSize);
        } catch (e) {
          debugPrint('Failed to restore window size: $e');
        }
      }

      await windowManager.show();
      await windowManager.focus();
    });

    if (!kDebugMode) {
      windowManager.addListener(this);
    }
  }

  @override
  void onWindowClose() async {
    bool isPreventClose = await windowManager.isPreventClose();
    if (isPreventClose) {
      if (sl<SettingsManager>().minimizeToTrayNotifier.value) {
        await windowManager.hide();
      } else {
        await teardownServices();
        await windowManager.destroy();
      }
    }
  }

  void dispose() {
    if (!kDebugMode) {
      windowManager.removeListener(this);
    }
  }
}
