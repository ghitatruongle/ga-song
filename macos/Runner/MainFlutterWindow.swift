import Cocoa
import FlutterMacOS
import UserNotifications
import MediaPlayer

class MainFlutterWindow: NSWindow {
  private var channel: FlutterMethodChannel?

  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)

    setupMethodChannel(binaryMessenger: flutterViewController.engine.binaryMessenger)

    super.awakeFromNib()
  }

  private func setupMethodChannel(binaryMessenger: FlutterBinaryMessenger) {
    channel = FlutterMethodChannel(name: "gasong/macos", binaryMessenger: binaryMessenger)
    channel?.setMethodCallHandler { [weak self] (call, result) in
      guard let self = self else {
        result(FlutterMethodNotImplemented)
        return
      }

      switch call.method {
      case "configureWindow":
        if let args = call.arguments as? [String: Any] {
          if let titleBarStyle = args["titleBarStyle"] as? String, titleBarStyle == "hidden" {
            self.titlebarAppearsTransparent = true
            self.titleVisibility = .hidden
            self.styleMask.insert(.fullSizeContentView)
          }
        }
        result(nil)

      case "setDockBadge":
        if let args = call.arguments as? [String: Any], let count = args["count"] as? Int, count > 0 {
          NSApp.dockTile.badgeLabel = "\(count)"
        } else {
          NSApp.dockTile.badgeLabel = nil
        }
        result(nil)

      case "showNotification":
        if let args = call.arguments as? [String: Any],
           let title = args["title"] as? String,
           let body = args["body"] as? String {
          let content = UNMutableNotificationContent()
          content.title = title
          content.body = body
          if let subtitle = args["subtitle"] as? String, !subtitle.isEmpty {
            content.subtitle = subtitle
          }
          let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
          )
          UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
        }
        result(nil)

      case "setNowPlaying":
        if let args = call.arguments as? [String: Any],
           let title = args["title"] as? String,
           let artist = args["artist"] as? String {
          var nowPlayingInfo = [String: Any]()
          nowPlayingInfo[MPMediaItemPropertyTitle] = title
          nowPlayingInfo[MPMediaItemPropertyArtist] = artist
          if let album = args["album"] as? String {
            nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = album
          }
          if let pos = args["position"] as? Double {
            nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = pos / 1000.0
          }
          if let dur = args["duration"] as? Double {
            nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = dur / 1000.0
          }
          let isPlaying = (args["isPlaying"] as? Bool) ?? false
          nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1.0 : 0.0

          MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
        }
        result(nil)

      case "clearNowPlaying":
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
        result(nil)

      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }
}
