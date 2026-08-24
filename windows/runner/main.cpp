#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>

#include "flutter_window.h"
#include "utils.h"

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    CreateAndAttachConsole();
  }

  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  flutter::DartProject project(L"data");

  std::vector<std::string> command_line_arguments = GetCommandLineArguments();

  // Enable Impeller GPU renderer on Windows 10 2004+ (build 19041) and
  // Windows 11+ for better visualizer performance. Older Win10 builds have
  // GPU driver issues that make Impeller slower than Skia.
  RTL_OSVERSIONINFOW osvi{};
  osvi.dwOSVersionInfoSize = sizeof(osvi);
  typedef LONG(WINAPI *RtlGetVersionPtr)(PRTL_OSVERSIONINFOW);
  const HMODULE ntdll = ::GetModuleHandleW(L"ntdll.dll");
  if (ntdll) {
    const auto fn = reinterpret_cast<RtlGetVersionPtr>(
        ::GetProcAddress(ntdll, "RtlGetVersion"));
    if (fn && fn(&osvi) == 0) {
      const bool isWin11OrLater =
          (osvi.dwMajorVersion > 10) ||
          (osvi.dwMajorVersion == 10 && osvi.dwBuildNumber >= 22000);
      const bool isWin10_2004Plus =
          (osvi.dwMajorVersion == 10 && osvi.dwMinorVersion == 0 &&
           osvi.dwBuildNumber >= 19041);
      if (isWin11OrLater || isWin10_2004Plus) {
        command_line_arguments.push_back("--enable-impeller");
      }
    } else {
      // RtlGetVersion unavailable — enable Impeller as safe default
      command_line_arguments.push_back("--enable-impeller");
    }
  } else {
    command_line_arguments.push_back("--enable-impeller");
  }

  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  FlutterWindow window(project);
  Win32Window::Point origin(10, 10);
  Win32Window::Size size(1280, 720);
  if (!window.Create(L"GA Song", origin, size)) {
    return EXIT_FAILURE;
  }
  window.SetQuitOnClose(true);

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  ::CoUninitialize();
  return EXIT_SUCCESS;
}