import Flutter
import UIKit
import AVFoundation
import AVKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var iosChannel: FlutterMethodChannel?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    do {
      try AVAudioSession.sharedInstance().setCategory(
        .playback,
        mode: .default,
        options: [.allowBluetooth, .allowBluetoothA2DP, .allowAirPlay]
      )
      try AVAudioSession.sharedInstance().setActive(true)
    } catch {
      print("Failed to set AVAudioSession category: \(error)")
    }
    // Request notification permission for sleep timer alerts.
    UNUserNotificationCenter.current().requestAuthorization(
      options: [.alert, .sound, .badge]
    ) { granted, error in
      if let error = error {
        print("Notification permission error: \(error)")
      }
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Notify Dart to drop image caches and decoded audio buffers.
    iosChannel?.invokeMethod("onMemoryWarning", arguments: nil)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "GaSongIOSPlugin") {
      iosChannel = FlutterMethodChannel(name: "gasong/ios", binaryMessenger: registrar.messenger())
      iosChannel?.setMethodCallHandler { (call, result) in
        switch call.method {
        case "updateWidget":
          result(nil)
        case "registerSiriShortcut", "donateSiriShortcut":
          result(nil)
        case "enableAirPlay", "disableAirPlay":
          result(nil)
        case "isAirPlayAvailable":
          result(true)
        case "isLowPowerMode":
          result(ProcessInfo.processInfo.isLowPowerModeEnabled)
        case "showNotification":
          guard let args = call.arguments as? [String: Any],
                let title = args["title"] as? String else {
            result(nil)
            return
          }
          let body = args["body"] as? String ?? ""
          let subtitle = args["subtitle"] as? String ?? ""
          self.showLocalNotification(title: title, body: body, subtitle: subtitle)
          result(nil)
        default:
          result(FlutterMethodNotImplemented)
        }
      }

      // Push Low Power Mode changes to Flutter
      NotificationCenter.default.addObserver(
        forName: .NSProcessInfoPowerStateDidChange,
        object: nil,
        queue: .main
      ) { [weak self] _ in
        self?.postLowPowerState()
      }
      postLowPowerState()
    }
  }

  private func postLowPowerState() {
    iosChannel?.invokeMethod(
      "onLowPowerModeChanged",
      arguments: ProcessInfo.processInfo.isLowPowerModeEnabled
    )
  }

  private func showLocalNotification(title: String, body: String, subtitle: String) {
    let content = UNMutableNotificationContent()
    content.title = title
    content.body = body
    if !subtitle.isEmpty {
      content.subtitle = subtitle
    }
    content.sound = .default

    let request = UNNotificationRequest(
      identifier: UUID().uuidString,
      content: content,
      trigger: nil // Deliver immediately
    )

    UNUserNotificationCenter.current().add(request) { error in
      if let error = error {
        print("Failed to show notification: \(error)")
      }
    }
  }
}
