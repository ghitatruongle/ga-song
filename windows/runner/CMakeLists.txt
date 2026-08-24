cmake_minimum_required(VERSION 3.14)
project(runner LANGUAGES CXX)

# Define the application target. To change its name, change BINARY_NAME in the
# top-level CMakeLists.txt, not the value here, or `flutter run` will no longer
# work.
#
# Any new source files that you add to the application should be added here.
add_executable(${BINARY_NAME} WIN32
  "flutter_window.cpp"
  "main.cpp"
  "utils.cpp"
  "win32_window.cpp"
  "${FLUTTER_MANAGED_DIR}/generated_plugin_registrant.cc"
  "Runner.rc"
  "runner.exe.manifest"
)

# Apply the standard set of build settings. This can be removed for applications
# that need different build settings.
apply_standard_settings(${BINARY_NAME})

# Add preprocessor definitions for the build version.
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION=\"${FLUTTER_VERSION}\"")
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION_MAJOR=${FLUTTER_VERSION_MAJOR}")
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION_MINOR=${FLUTTER_VERSION_MINOR}")
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION_PATCH=${FLUTTER_VERSION_PATCH}")
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION_BUILD=${FLUTTER_VERSION_BUILD}")

# Disable Windows macros that collide with C++ standard library functions.
target_compile_definitions(${BINARY_NAME} PRIVATE "NOMINMAX")

# Add dependency libraries and include directories. Add any application-specific
# dependencies here.
target_link_libraries(${BINARY_NAME} PRIVATE flutter flutter_wrapper_app)
target_link_libraries(${BINARY_NAME} PRIVATE "dwmapi.lib")
target_include_directories(${BINARY_NAME} PRIVATE "${CMAKE_SOURCE_DIR}")

# Whole-program optimization for the runner target ONLY.
# INTERPROCEDURAL_OPTIMIZATION maps to /GL (compiler) + /LTCG (linker) for
# MSVC Release builds, letting the linker inline across translation units.
# This is intentionally scoped to the app runner — plugins keep their own
# flags (apply_standard_settings is shared and stays untouched).
set_target_properties(${BINARY_NAME} PROPERTIES
  INTERPROCEDURAL_OPTIMIZATION_RELEASE TRUE
)

# Linker COMDAT folding + dead-code elimination on Release.
# /OPT:REF drops unreferenced functions/data, /OPT:ICF merges identical
# code. Both are already ON by default in MSVC Release link lines, but we
# pin them explicitly so the optimization is guaranteed even if a future
# Flutter template changes the default.
#
# `target_link_options(...)` with genexes did NOT reach the linker on the
# Visual Studio generator in this Flutter template (verified in the
# generated .vcxproj), so use the classic per-config LINK_FLAGS property,
# which MSBuild always appends to the link line.
set_target_properties(${BINARY_NAME} PROPERTIES
  LINK_FLAGS_RELEASE "/OPT:REF /OPT:ICF"
)

# Run the Flutter tool portions of the build. This must not be removed.
add_dependencies(${BINARY_NAME} flutter_assemble)
