import Flutter
import UIKit
import AVFoundation
import AVKit

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
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "GaSongIOSPlugin") {
      iosChannel = FlutterMethodChannel(name: "gasong/ios", binaryMessenger: registrar.messenger())
      iosChannel?.setMethodCallHandler { (call, result) in
        switch call.method {
        case "updateWidget":
          // WidgetKit sync stub
          result(nil)
        case "registerSiriShortcut", "donateSiriShortcut":
          // Siri shortcuts stub
          result(nil)
        case "enableAirPlay", "disableAirPlay":
          result(nil)
        case "isAirPlayAvailable":
          result(true)
        default:
          result(FlutterMethodNotImplemented)
        }
      }
    }
  }
}
