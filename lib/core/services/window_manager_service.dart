import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart';
import '../service_locator.dart';
import '../settings_manager.dart';

class WindowManagerService with WindowListener {
  Future<void> init() async {
    if (kIsWeb || (!kIsWeb && !(defaultTargetPlatform == TargetPlatform.windows || defaultTargetPlatform == TargetPlatform.linux || defaultTargetPlatform == TargetPlatform.macOS))) {
      return;
    }

    try {
      await Window.initialize();
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
          try {
            await windowManager.setPreventClose(true);
          } catch (e) {
            debugPrint('Wayland/Linux fallback: setPreventClose not supported. $e');
          }
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

        try {
          await windowManager.show();
          await windowManager.focus();
        } catch (e) {
          debugPrint('Failed to show/focus window: $e');
        }
        
        _applyWindowEffect();
      });
    } catch (e) {
      debugPrint('Window manager initialization failed (possible Wayland unsupported feature): $e');
    }

    if (!kDebugMode) {
      windowManager.addListener(this);
    }
    
    sl<SettingsManager>().useNativeWindowEffectNotifier.addListener(_applyWindowEffect);
    sl<SettingsManager>().themeModeNotifier.addListener(_applyWindowEffect);
  }

  void _applyWindowEffect() {
    final useNative = sl<SettingsManager>().useNativeWindowEffectNotifier.value;
    final theme = sl<SettingsManager>().themeModeNotifier.value;
    final isDark = theme == ThemeMode.dark || (theme == ThemeMode.system && PlatformDispatcher.instance.platformBrightness == Brightness.dark);
    
    if (useNative) {
      Window.setEffect(effect: WindowEffect.mica, dark: isDark).catchError((_) {
        Window.setEffect(effect: WindowEffect.acrylic, dark: isDark).catchError((_) {});
      });
    } else {
      Window.setEffect(effect: WindowEffect.disabled);
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
    sl<SettingsManager>().useNativeWindowEffectNotifier.removeListener(_applyWindowEffect);
    sl<SettingsManager>().themeModeNotifier.removeListener(_applyWindowEffect);
    if (!kDebugMode) {
      windowManager.removeListener(this);
    }
  }
}
