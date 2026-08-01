# ProGuard Rules for G.A - Song
# These rules preserve necessary classes and methods for reflection, serialization, and native interop.

# ─── Keep Flutter/Dart Core ─────────────────────────────────────────────────
-keep class io.flutter.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugin.** { *; }

# ─── Keep Riverpod ──────────────────────────────────────────────────────────
-keep class com.google.dart.** { *; }
-keep class com.google.riverpod.** { *; }
-keepclassmembers class * {
    @riverpod.* *;
}

# ─── Keep Drift Database ────────────────────────────────────────────────────
-keep class com.simplest.drift.** { *; }
-keep class com.simplest.drift.** { *; }
-keep class dev.drift.** { *; }
-keepclassmembers class * extends dev.drift.DriftDatabase {
    <init>(...);
    *;
}
-keepclassmembers class * {
    @dev.drift.** *;
}

# ─── Keep Freezed/JSON Serializable ─────────────────────────────────────────
-keep class * implements freezed.** { *; }
-keep class * implements com.google.gson.** { *; }
-keepclassmembers class * {
    @com.google.gson.annotations.** *;
    @com.google.gson.annotations.SerializedName *;
}

# ─── Keep Audio Service ─────────────────────────────────────────────────────
-keep class com.ryanheise.audioservice.** { *; }
-keep class com.ryanheise.audioservice.** { *; }
-keep class com.ryanheise.just_audio.** { *; }
-keep class com.ryanheise.just_audio.** { *; }

# ─── Keep SoLoud ────────────────────────────────────────────────────────────
-keep class com.soloud.** { *; }
-keep class com.soloud.FlutterSoLoudPlugin { *; }

# ─── Keep Drift/SQLite ──────────────────────────────────────────────────────
-keep class org.sqlite.** { *; }
-keep class net.sqlcipher.** { *; }

# ─── Keep Drift Runtime ────────────────────────────────────────────────────
-keep class dev.drift.internal.** { *; }
-keep class dev.drift.runtime.** { *; }

# ─── Keep Path Provider ─────────────────────────────────────────────────────
-keep class io.flutter.plugins.pathprovider.** { *; }

# ─── Keep Shared Preferences ────────────────────────────────────────────────
-keep class io.flutter.plugins.sharedpreferences.** { *; }

# ─── Keep Audio Service ─────────────────────────────────────────────────────
-keep class com.ryanheise.audioservice.** { *; }
-keep class com.ryanheise.audioservice.MediaNotification.** { *; }

# ─── Keep Just Audio ────────────────────────────────────────────────────────
-keep class com.ryanheise.just_audio.** { *; }
-keep class com.ryanheise.just_audio.BackgroundIsolate.** { *; }

# ─── Keep Audio Session ─────────────────────────────────────────────────────
-keep class com.ryanheise.audio_session.** { *; }

# ─── Keep Flutter Local Notifications ───────────────────────────────────────
-keep class com.dexterous.flutterlocalnotifications.** { *; }

# ─── Keep Uni Links ──────────────────────────────────────────────────────────
-keep class io.flutter.plugins.unilinks.** { *; }

# ─── Keep Window Manager ────────────────────────────────────────────────────
-keep class io.github.window_manager.** { *; }

# ─── Keep System Tray ───────────────────────────────────────────────────────
-keep class com.leanflutter.system_tray.** { *; }

# ─── Keep Hotkey Manager ────────────────────────────────────────────────────
-keep class com.leanflutter.hotkey_manager.** { *; }

# ─── Keep SMTC ──────────────────────────────────────────────────────────────
-keep class com.ghitatruongle.smtc.** { *; }
-keep class com.ghitatruongle.smtc_windows.** { *; }

# ─── Keep Audio Tags ────────────────────────────────────────────────────────
-keep class com.kyanite.audiotags.** { *; }

# ─── Keep Image Package ─────────────────────────────────────────────────────
-keep class dart.image.** { *; }

# ─── Keep Palette Generator ─────────────────────────────────────────────────
-keep class com.google.android.libraries.palette.** { *; }

# ─── Keep Path Provider ─────────────────────────────────────────────────────
-keep class io.flutter.plugins.pathprovider.** { *; }

# ─── Keep File Picker ───────────────────────────────────────────────────────
-keep class com.mrnofilepicker.** { *; }
-keep class com.mrnofilepicker.FilePicker.** { *; }

# ─── Keep UUID ──────────────────────────────────────────────────────────────
-keep class io.flutter.plugins.uuid.** { *; }

# ─── Keep Audio Tags ────────────────────────────────────────────────────────
-keep class com.kyanite.audiotags.** { *; }

# ─── Keep Platform Channel ──────────────────────────────────────────────────
-keep class io.flutter.plugin.common.** { *; }
-keep class io.flutter.plugin.platform.** { *; }

# ─── Keep Drift Generated Code ──────────────────────────────────────────────
-keep class **.*$* {
    <init>(...);
    *;
}

# ─── Keep Annotations ───────────────────────────────────────────────────────
-keep @interface * {
    *;
}

# ─── Keep Enums ──────────────────────────────────────────────────────────────
-keepclassmembers enum * {
    **[] $VALUES;
    public *;
}

# ─── Keep Native Methods ────────────────────────────────────────────────────
-keepclasseswithmembernames class * {
    native <methods>;
}

# ─── Keep Native Libraries ──────────────────────────────────────────────────
-keep class ** { 
    native <methods>;
}

# ─── Keep Reflection ────────────────────────────────────────────────────────
-keepclassmembers class * {
    @androidx.annotation.Keep *;
    @androidx.annotation.NonNull *;
    @androidx.annotation.Nullable *;
}

# ─── Keep SoLoud Native ─────────────────────────────────────────────────────
-keep class com.soloud.FlutterSoLoudPlugin {
    *;
}

# ─── Keep Audio Engine ──────────────────────────────────────────────────────
-keep class com.ghitatruongle.gasong.core.audio.** { *; }

# ─── Keep Playlist Service ──────────────────────────────────────────────────
-keep class com.ghitatruongle.gasong.core.audio.PlaylistService { *; }

# ─── Keep Settings Manager ──────────────────────────────────────────────────
-keep class com.ghitatruongle.gasong.core.settings.SettingsManager { *; }

# ─── Keep Database ──────────────────────────────────────────────────────────
-keep class com.ghitatruongle.gasong.core.services.DatabaseServiceWrapper { *; }
-keep class com.ghitatruongle.gasong.core.database.** { *; }

# ─── Keep Model Classes ─────────────────────────────────────────────────────
-keep class com.ghitatruongle.gasong.models.** { *; }

# ─── Keep Services ──────────────────────────────────────────────────────────
-keep class com.ghitatruongle.gasong.core.services.** { *; }

# ─── Keep Providers ─────────────────────────────────────────────────────────
-keep class com.ghitatruongle.gasong.providers.** { *; }

# ─── Keep UI Components ─────────────────────────────────────────────────────
-keep class com.ghitatruongle.gasong.ui.** { *; }

# ─── Keep Widgets ───────────────────────────────────────────────────────────
-keep class com.ghitatruongle.gasong.ui.widgets.** { *; }

# ─── Keep Screens ───────────────────────────────────────────────────────────
-keep class com.ghitatruongle.gasong.ui.screens.** { *; }

# ─── Keep L10n ──────────────────────────────────────────────────────────────
-keep class * implements flutter.localizations.** { *; }

# ─── Allow Obfuscation of Non-Critical Code ─────────────────────────────────
# The following can be obfuscated safely:
# - Internal implementation classes not accessed via reflection
# - Private methods not called via reflection
# - BuildConfig and R classes

# ─── Optimization Settings ──────────────────────────────────────────────────
-optimizationpasses 5
-allowaccessmodification
-allowoptimization
-allowredefinition
-mergeinterfacesaggressively
-overloadaggressively
-repackageclasses ''
-optimize
-optimizations !code/simplification/arithmetic,!code/simplification/cast,!field/*,!class/merging/*

# ─── Verbose Output ─────────────────────────────────────────────────────────
-verbose
-printusage unused.txt
-printseeds seeds.txt
-printmapping mapping.txt