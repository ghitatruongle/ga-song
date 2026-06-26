# ============================================================================
# ProGuard rules for GA Song Android release builds
# ============================================================================

# --- flutter_soloud (native C++ audio engine via FFI) ---
-keep class com.google.android.** { *; }
-keepclassmembers class * {
    native <methods>;
}

# --- Isar database (native bindings) ---
-keep class dev.isar.** { *; }
-keep class * extends io.flutter.plugins.GeneratedPluginRegistrant { *; }

# --- audio_service (MediaBrowserService) ---
-keep class com.ryanheise.audioservice.** { *; }
-keep class com.ryanheise.audio_session.** { *; }
-keep class android.media.session.** { *; }
-keep class android.support.v4.media.** { *; }
-keep class androidx.media.** { *; }

# --- WebView (youtube_player_iframe) ---
-keep class android.webkit.** { *; }
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}

# --- File picker ---
-keep class com.mr.flutter.plugin.filepicker.** { *; }

# --- Shared preferences ---
-keep class io.flutter.plugins.sharedpreferences.** { *; }

# --- Audiotags ---
-keep class com.erikas.audiotags.** { *; }

# --- Flutter general ---
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# --- Prevent stripping Flutter's GeneratedPluginRegistrant ---
-keep class io.flutter.plugins.GeneratedPluginRegistrant { *; }

# --- Kotlin serialization / reflection ---
-keepattributes *Annotation*
-keepattributes SourceFile,LineNumberTable
-keep public class * extends java.lang.Exception

# --- Suppress warnings for known-safe classes ---
-dontwarn android.webkit.**
-dontwarn androidx.**
-dontwarn javax.annotation.**

# --- Google Play Core (fix R8 missing classes) ---
-dontwarn com.google.android.play.core.splitcompat.SplitCompatApplication
-dontwarn com.google.android.play.core.splitinstall.SplitInstallException
-dontwarn com.google.android.play.core.splitinstall.SplitInstallManager
-dontwarn com.google.android.play.core.splitinstall.SplitInstallManagerFactory
-dontwarn com.google.android.play.core.splitinstall.SplitInstallRequest$Builder
-dontwarn com.google.android.play.core.splitinstall.SplitInstallRequest
-dontwarn com.google.android.play.core.splitinstall.SplitInstallSessionState
-dontwarn com.google.android.play.core.splitinstall.SplitInstallStateUpdatedListener
-dontwarn com.google.android.play.core.tasks.OnFailureListener
-dontwarn com.google.android.play.core.tasks.OnSuccessListener
-dontwarn com.google.android.play.core.tasks.Task
