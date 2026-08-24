import Flutter
import UIKit

class SceneDelegate: FlutterSceneDelegate {

  /// Called when the scene becomes active (foreground).
  /// Resume any paused animations and restore full frame rate.
  override func sceneDidBecomeActive(_ scene: UIScene) {
    super.sceneDidBecomeActive(scene)
    // Notify Dart side that the app is in foreground — visualizer can
    // resume full FPS, cover-art preloads can restart if needed.
    if let engine = (scene as? UIWindowScene)?
        .windows.first?
        .rootViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(
        name: "gasong/lifecycle",
        binaryMessenger: engine.binaryMessenger
      )
      channel.invokeMethod("onAppResumed", arguments: nil)
    }
  }

  /// Called when the scene is about to resign active (background).
  /// Reduce frame rate and release non-essential resources.
  override func sceneWillResignActive(_ scene: UIScene) {
    super.sceneWillResignActive(scene)
    // Notify Dart side to release non-essential caches.
    if let engine = (scene as? UIWindowScene)?
        .windows.first?
        .rootViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(
        name: "gasong/lifecycle",
        binaryMessenger: engine.binaryMessenger
      )
      channel.invokeMethod("onAppPaused", arguments: nil)
    }
  }
}
