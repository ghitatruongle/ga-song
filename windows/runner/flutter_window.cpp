#include "flutter_window.h"

#include <optional>

#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>
#include "flutter/generated_plugin_registrant.h"

FlutterWindow::FlutterWindow(const flutter::DartProject& project)
    : project_(project) {}

FlutterWindow::~FlutterWindow() {}

bool FlutterWindow::OnCreate() {
  if (!Win32Window::OnCreate()) {
    return false;
  }

  RECT frame = GetClientArea();

  flutter_controller_ = std::make_unique<flutter::FlutterViewController>(
      frame.right - frame.left, frame.bottom - frame.top, project_);
  if (!flutter_controller_->engine() || !flutter_controller_->view()) {
    return false;
  }

  RegisterPlugins(flutter_controller_->engine());
  SetChildContent(flutter_controller_->view()->GetNativeWindow());

  RegisterPowerStateChannel(flutter_controller_->engine());

  flutter_controller_->engine()->SetNextFrameCallback([&]() {
    this->Show();
  });

  flutter_controller_->ForceRedraw();

  return true;
}

void FlutterWindow::OnDestroy() {
  if (flutter_controller_) {
    flutter_controller_ = nullptr;
  }

  Win32Window::OnDestroy();
}

// Exposes Windows power state (battery saver / AC / level) to Dart via
// the "com.gasong.ga_song/power" MethodChannel.
void FlutterWindow::RegisterPowerStateChannel(
    flutter::FlutterEngine* engine) {
  power_channel_ = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
      engine->messenger(), "com.gasong.ga_song/power",
      &flutter::StandardMethodCodec::GetInstance());

  power_channel_->SetMethodCallHandler(
      [](const flutter::MethodCall<flutter::EncodableValue>& call,
         std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
        if (call.method_name() == "powerState") {
          SYSTEM_POWER_STATUS status{};
          const BOOL ok = ::GetSystemPowerStatus(&status);

          // SPI_GETBATTERYSAVERSTATE (0x0073) — Windows 10 1607+. Reads
          // whether Battery Saver is currently active. Not defined unless the
          // SDK targets Win10, so define it locally as a fallback.
          BOOL battery_saver = FALSE;
#ifndef SPI_GETBATTERYSAVERSTATE
#define SPI_GETBATTERYSAVERSTATE 0x0073
#endif
          ::SystemParametersInfo(SPI_GETBATTERYSAVERSTATE, 0, &battery_saver, 0);

          if (!ok) {
            // GetSystemPowerStatus failed — report defaults (charging).
            result->Success(flutter::EncodableValue(flutter::EncodableMap{
                {flutter::EncodableValue("isPowerSaving"),
                 flutter::EncodableValue(false)},
                {flutter::EncodableValue("isCharging"),
                 flutter::EncodableValue(true)},
                {flutter::EncodableValue("level"),
                 flutter::EncodableValue(100)},
            }));
            return;
          }

          const bool is_charging = status.ACLineStatus == 1;
          const int level = status.BatteryLifePercent;  // 0-100, 255=unknown

          result->Success(flutter::EncodableValue(flutter::EncodableMap{
              {flutter::EncodableValue("isPowerSaving"),
               flutter::EncodableValue(battery_saver == TRUE)},
              {flutter::EncodableValue("isCharging"),
               flutter::EncodableValue(is_charging)},
              {flutter::EncodableValue("level"),
               flutter::EncodableValue(level == 255 ? -1 : level)},
          }));
        } else {
          result->NotImplemented();
        }
      });
}

LRESULT
FlutterWindow::MessageHandler(HWND hwnd, UINT const message,
                              WPARAM const wparam,
                              LPARAM const lparam) noexcept {
  if (flutter_controller_) {
    std::optional<LRESULT> result =
        flutter_controller_->HandleTopLevelWindowProc(hwnd, message, wparam,
                                                      lparam);
    if (result) {
      return *result;
    }
  }

  switch (message) {
    case WM_FONTCHANGE:
      flutter_controller_->engine()->ReloadSystemFonts();
      break;
  }

  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}