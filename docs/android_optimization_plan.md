# 📱 KẾ HOẠCH TỐI ƯU HÓA ANDROID — G.A - Song

**Phiên bản:** 1.0  
**Ngày tạo:** 2026-07-23  
**Trạng thái:** Đã phân tích, chờ thực thi  
**Phạm vi:** Tối ưu Android (APK, native, performance, UX)  
**Dự án cha:** [Refined Polish Design Spec](superpowers/specs/2026-07-01-refined-polish-design.md)

---

## 1. TỔNG QUAN DỰ ÁN

### 1.1. Dự án là gì?

**G.A - Song** là một ứng dụng phát nhạc đa nền tảy (cross-platform) được xây dựng bằng Flutter, hỗ trợ:
- Phát nhạc local với SoLoud engine (C++ native)
- Equalizer 5-band, audio effects (bass boost, pitch shift, reverb, compressor)
- Visualizer thời gian thực (particle/starfield)
- Chế độ KTV (karaoke), lyrics sync (LRC/SRT)
- Quản lý playlist, cover art caching (3-tier: memory → disk → source)
- Tích hợp hệ thống (system tray, global hotkeys, media keys, SMTC)
- Hỗ trợ Android, Windows, Linux (macOS/iOS/Web một phần)

### 1.2. Cấu trúc Android hiện tại

```
android/
├── app/
│   ├── build.gradle.kts          # Cấu hình build (AGP 8.11.1, compileSdk từ Flutter)
│   ├── proguard-rules.pro        # R8/ProGuard rules (đã có, chi tiết)
│   ├── src/
│   │   ├── debug/AndroidManifest.xml    # Chỉ có INTERNET
│   │   ├── main/AndroidManifest.xml     # Quyền: WAKE_LOCK, FOREGROUND_SERVICE
│   │   ├── profile/AndroidManifest.xml  # Chỉ có INTERNET
│   │   ├── main/kotlin/com/gasong/ga_song/MainActivity.kt  # PiP support
│   │   └── main/res/
│   │       ├── drawable*/launch_background.xml  # Splash (trắng)
│   │       ├── mipmap-*/ic_launcher.png          # Icon
│   │       └── values*/styles.xml                # Theme (NoTitleBar)
├── build.gradle.kts             # Project-level (Gradle 8.14, Kotlin)
├── gradle.properties            # JVM args, useAndroidX, Kotlin 2.2.20
└── settings.gradle.kts          # AGP 8.11.1
```

### 1.3. Phiên bản & cấu hình

| Thành phần | Giá trị |
|-----------|---------|
| Flutter | 3.32.0 |
| Dart SDK | ^3.11.4 |
| AGP (Android Gradle Plugin) | 8.11.1 |
| Gradle | 8.14 |
| Kotlin | 2.2.20 (built-in) |
| compileSdk | Từ Flutter config |
| minSdk | 21 (từ flutter_launcher_icons config) |
| targetSdk | Từ Flutter config |
| Java | 17 (sourceCompatibility + targetCompatibility) |
| Application ID | `com.gasong.ga_song` |
| Version | 0.1.1+1 |

### 1.4. Dependencies Android liên quan

| Package | Version | Mục đích trên Android |
|---------|---------|----------------------|
| `flutter_soloud` | 4.0.5 | Audio engine C++ (native) |
| `audio_service` | 0.18.18 | Media notification, MediaBrowserService |
| `sqflite` | 2.4.2 | SQLite (local DB) |
| `shared_preferences` | 2.5.5 | Settings persistence |
| `file_picker` | 11.0.2 | File picker (permission storage) |
| `audiotags` | 1.4.5 | Tag extraction |
| `youtube_player_iframe` | 5.2.2 | YouTube playback (WebView) |
| `path_provider` | 2.1.5 | File system paths |

---

## 2. PHÂN TÍCH VẤN ĐỀ ANDROID HIỆN TẠI

### 2.1. Vấn đề cấu hình build (🔴 Cao)

| # | Vấn đề | Mô tả | Tác động |
|---|--------|-------|----------|
| B1 | **minSdk = 21** | Quá thấp — thiết bị cũ (Android 5.0) gây crash với SoLoud/native libs | Crash rate tăng trên thiết bị cũ |
| B2 | **Release signing debug key** | `signingConfig = signingConfigs.getByName("debug")` — không bao giờ dùng release key | Không thể publish lên Play Store |
| B3 | **Không có split APK / ABI splits** | APK đơn chứa tất cả native libs (arm64-v8a, armeabi-v7a, x86, x86_64) | APK lớn, tải về không cần thiết |
| B4 | **Không có resource shrinking** | `minifyEnabled` và `shrinkResources` chưa bật ở release | APK lớn hơn mức cần thiết |
| B5 | **Không có vector drawables** | Chỉ có PNG mipmaps — không tối ưu cho các mật độ màn hình | APK lớn, chất lượng thấp trên màn hình đặc biệt |
| B6 | **Kotlin incremental = false** | `kotlin.incremental=false` trong gradle.properties | Build chậm hơn |

### 2.2. Vấn đề AndroidManifest (🔴 Cao)

| # | Vấn đề | Mô tả | Tác động |
|---|--------|-------|----------|
| M1 | **Thiếu quyền truy cập bộ nhớ** | Không có `READ_EXTERNAL_STORAGE` / `READ_MEDIA_AUDIO` | File picker có thể thất bại trên Android 10+ |
| M2 | **Thiếu POST_NOTIFICATIONS** | Android 13+ yêu cầu runtime permission cho notification | Media notification không hiện trên Android 13+ |
| M3 | **Thiếu FOREGROUND_SERVICE_DATA_SYNC** | Nếu có background sync | Background service bị giới hạn |
| M4 | **Không có exact alarm permission** | Nếu có sleep timer | Sleep timer không hoạt động trên Android 12+ |
| M5 | **Theme dùng hệ thống cũ** | `Theme.Light.NoTitleBar` / `Theme.Black.NoTitleBar` | Không hỗ trợ Material 3, splash không mượt |
| M6 | **Không có splash screen API** | Android 12+ có SplashScreen API riêng | Splash cũ, không mượt, không branded |
| M7 | **Không có android:exported trên service** | `AudioService` có `exported="true"` nhưng không có intent-filter đầy đủ | Có thể gây warning trên Android 12+ |

### 2.3. Vấn đề MainActivity / Native (🟡 Trung bình)

| # | Vấn đề | Mô tả | Tác động |
|---|--------|-------|----------|
| A1 | **MethodChannel chưa dispose** | `PipService` tạo MethodChannel nhưng không có cơ chế dispose | Memory leak nhỏ |
| A2 | **Không có error handling cho PiP** | `enterPictureInPictureMode` có thể ném exception | Crash tiềm ẩn |
| A3 | **Không override onNewIntent** | `launchMode="singleTop"` nhưng không xử lý intent mới | Deep link không hoạt động |
| A4 | **Không có lifecycle-aware cleanup** | Không có `onDestroy` cleanup cho MethodChannel | Leak khi activity bị destroy |
| A5 | **Không có AndroidX Activity Result API** | File picker dùng cách cũ qua MethodChannel | Cần cập nhật để hỗ trợ Android 13+ |

### 2.4. Vấn đề hiệu năng Android (🔴 Cao)

| # | Vấn đề | Mô tả | Tác động |
|---|--------|-------|----------|
| P1 | **Không có ABI splits** | APK chứa tất cả native libs | APK ~30MB+ (vượt budget 30MB) |
| P2 | **SoLoud native libs không được tối ưu** | C++ libs được biên dịch cho tất cả architectures | APK lớn, RAM không tối ưu |
| P3 | **Không có RAM tuning** | Không cấu hình `android:largeHeap` hoặc memory class | OOM trên thiết bị RAM thấp |
| P4 | **Position timer 500ms** | `PlatformCapabilities.positionTimerInterval` = 500ms trên Android | Độ trễ hiển thị position |
| P5 | **Visualizer particle count = 80** | `maxParticleCount = 80` trên Android | Có thể giảm xuống 50-60 cho thiết bị yếu |
| P6 | **Không có adaptive bitrate** | Audio luôn chạy ở chất lượng gốc | Tốn RAM/battery trên thiết bị yếu |
| P7 | **Không có background audio optimization** | Foreground service chưa tối ưu | Battery drain khi chạy nền |

### 2.5. Vấn đề UX Android (🟡 Trung bình)

| # | Vấn đề | Mô tả | Tác động |
|---|--------|-------|----------|
| U1 | **Splash không branded** | Chỉ có màu trắng, không logo | Trải nghiệm kém |
| U2 | **Không có haptic feedback** | Đã có `safeHaptic` nhưng chưa wiring đầy đủ trên Android | Cảm giác kém |
| U3 | **Không tối ưu PiP** | PiP chỉ hỗ trợ 16:9 cố định | Không linh hoạt |
| U4 | **Notification channel chưa tối ưu** | Chỉ có 1 channel, không có channel grouping | UX kém trên Android 8+ |
| U5 | **Không có media browser service đầy đủ** | MediaBrowserService chưa hỗ trợ browse, search | Không tích hợp với Android Auto |

### 2.6. Vấn đề CI/CD Android (🟡 Trung bình)

| # | Vấn đề | Mô tả | Tác động |
|---|--------|-------|----------|
| C1 | **Chỉ build APK** | CI chỉ build APK, không có App Bundle (AAB) | Không tối ưu cho Play Store |
| C2 | **Không có APK signature verification** | Không kiểm tra signature | Bảo mật thấp |
| C3 | **Không có size check chi tiết** | Chỉ kiểm tra tổng size, không phân tích | Khó tối ưu |
| C4 | **Không có device test matrix** | Chỉ build trên Ubuntu, không test trên thiết bị thật | Bug không phát hiện |

---

## 3. KẾ HOẠCH TỐI ƯU ANDROID

### 3.1. Chiến lược tổng thể

**Phương pháp:** Tuần tự, từng giai đoạn, mỗi gia đoạn có thể build & test độc lập.

**Nguyên tắc:**
1. **Backward compatible** — không phá vỡ dữ liệu người dùng
2. **Incremental** — mỗi commit đều build được
3. **Measurable** — mỗi tối ưu đều có metric đo lường
4. **Platform-aware** — tận dụng tối đa tính năng Android

### 3.2. Các giai đoạn tối ưu

| Giai đoạn | Thời gian | Mục tiêu | Độ ưu tiên |
|-----------|-----------|----------|------------|
| **Giai đoạn 1** | 1 ngày | Cấu hình build & manifest | 🔴 Cao |
| **Giai đoạn 2** | 2 ngày | Native code & MainActivity | 🟡 Trung bình |
| **Giai đoạn 3** | 3 ngày | Hiệu năng & APK size | 🔴 Cao |
| **Giai đoạn 4** | 2 ngày | UX & Material 3 | 🟡 Trung bình |
| **Giai đoạn 5** | 1 ngày | CI/CD & testing | 🟢 Thấp |

---

## 4. GIAI ĐOẠN 1: CẤU HÌNH BUILD & MANIFEST

### 4.1. Cập nhật `android/app/build.gradle.kts`

**Mục tiêu:** Tối ưu APK size, bảo mật, và build performance.

```kotlin
android {
    namespace = "com.gasong.ga_song"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    defaultConfig {
        applicationId = "com.gasong.ga_song"
        minSdk = 24          // TĂNG từ 21 → 24 (Android 7.0+)
        targetSdk = 35       // CẬP NHẬT target SDK mới nhất
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // ABI splits — chỉ giữ lại architectures cần thiết
        ndk {
            abiFilters += listOf("armeabi-v7a", "arm64-v8a")
        }
    }

    buildTypes {
        release {
            // BẬT R8 full mode + resource shrinking
            isMinifyEnabled = true
            isShrinkResources = true
            isStripDebugSymbols = true    // Bỏ debug symbols (giảm ~30%)
            isRemoveUnusedCode = true     // R8 full mode

            // Signing config — sử dụng release key
            signingConfig = signingConfigs.getByName("release")

            // ProGuard/R8 optimization
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )

            // APK v2/v3 signature
            isSigningV2Enabled = true
            isSigningV3Enabled = true
        }

        debug {
            isMinifyEnabled = false
            isShrinkResources = false
            isDebuggable = true
        }
    }

    // Bundle config — tối ưu native libs
    bundle {
        language {
            enableSplit = true
        }
        density {
            enableSplit = true
        }
    }

    // Packaging — loại bỏ native libs không cần thiết
    packaging {
        resources {
            excludes += setOf(
                "META-INF/{AL2.0,LGPL2.1}",
                "META-INF/DEPENDENCIES",
                "META-INF/LICENSE*",
                "META-INF/NOTICE*"
            )
        }
    }
}

flutter {
    source = "../.."
}
```

### 4.2. Cập nhật `android/build.gradle.kts`

```kotlin
allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Thêm Kotlin options cho toàn bộ subprojects
subprojects {
    plugins.withId("org.jetbrains.kotlin.android") {
        extensions.configure<org.jetbrains.kotlin.gradle.dsl.KotlinAndroidProjectExtension>("kotlin") {
            jvmToolchain(17)
        }
    }
}
```

### 4.3. Cập nhật `android/gradle.properties`

```properties
org.gradle.jvmargs=-Xmx8G -XX:MaxMetaspaceSize=4G -XX:ReservedCodeCacheSize=512m -XX:+HeapDumpOnOutOfMemoryError -XX:+UseG1GC
android.useAndroidX=true
kotlin.incremental=true                         # BẬT incremental compilation
android.builtInKotlin=true
flutter.kotlinVersion=2.2.20
android.newDsl=false

# Tối ưu R8
android.enableR8.fullMode=true
android.enableR8.lint.violations=false

# Tối ưu build cache
org.gradle.caching=true
org.gradle.parallel=true
org.gradle.daemon=true

# Tối ưu resource shrinking
android.experimental.enableNewResourceShrinker=true
```

### 4.4. Cập nhật `AndroidManifest.xml` (main)

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:tools="http://schemas.android.com/tools">

    <!-- Permissions -->
    <uses-permission android:name="android.permission.WAKE_LOCK" />
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE_MEDIA_PLAYBACK" />

    <!-- Android 13+ notification permission -->
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS" />

    <!-- Android 10+ media access -->
    <uses-permission android:name="android.permission.READ_MEDIA_AUDIO" />
    <uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />

    <!-- Android 9+ storage access (fallback) -->
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"
        android:maxSdkVersion="32" />

    <!-- Exact alarm for sleep timer (Android 12+) -->
    <uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM" />

    <application
        android:label="ga_song"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher"
        android:requestLegacyExternalStorage="false"
        android:usesCleartextTraffic="false"
        android:networkSecurityConfig="@xml/network_security_config">

        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:launchMode="singleTop"
            android:taskAffinity=""
            android:theme="@style/LaunchTheme"
            android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
            android:hardwareAccelerated="true"
            android:windowSoftInputMode="adjustResize"
            android:supportsPictureInPicture="true"
            android:resizeableActivity="true">
            <meta-data
                android:name="io.flutter.embedding.android.NormalTheme"
                android:resource="@style/NormalTheme" />
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
            <!-- Deep link support -->
            <intent-filter>
                <action android:name="android.intent.action.VIEW" />
                <category android:name="android.intent.category.DEFAULT" />
                <category android:name="android.intent.category.BROWSABLE" />
                <data android:scheme="ga-song" android:host="play" />
            </intent-filter>
        </activity>

        <meta-data
            android:name="flutterEmbedding"
            android:value="2" />

        <!-- Audio service -->
        <service
            android:name="com.ryanheise.audioservice.AudioService"
            android:foregroundServiceType="mediaPlayback"
            android:exported="true">
            <intent-filter>
                <action android:name="android.media.browse.MediaBrowserService" />
            </intent-filter>
        </service>

        <!-- Media button receiver -->
        <receiver
            android:name="com.ryanheise.audioservice.MediaButtonReceiver"
            android:exported="true">
            <intent-filter>
                <action android:name="android.intent.action.MEDIA_BUTTON" />
            </intent-filter>
        </receiver>

        <!-- Notification channels (Android 8+) -->
        <receiver
            android:name=".AudioNotificationReceiver"
            android:exported="false" />

    </application>

    <queries>
        <intent>
            <action android:name="android.intent.action.PROCESS_TEXT" />
            <data android:mimeType="text/plain" />
        </intent>
    </queries>
</manifest>
```

### 4.5. Tạo `network_security_config.xml`

```xml
<?xml version="1.0" encoding="utf-8"?>
<network-security-config xmlns:android="http://schemas.android.com/apk/res/android">
    <!-- Cho phép clear text cho localhost (debug) -->
    <domain-config cleartextTrafficPermitted="true">
        <domain includeSubdomains="true">localhost</domain>
    </domain-config>
</network-security-config>
```

### 4.6. Cập nhật `styles.xml` (Material 3)

**values/styles.xml (light):**
```xml
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <style name="LaunchTheme" parent="Theme.Material3.DayNight.NoActionBar">
        <item name="android:windowBackground">@drawable/launch_background</item>
        <item name="android:statusBarColor">@android:color/transparent</item>
    </style>

    <style name="NormalTheme" parent="Theme.Material3.DayNight.NoActionBar">
        <item name="android:windowBackground">?android:colorBackground</item>
        <item name="colorPrimary">@color/seed_primary</item>
        <item name="colorOnPrimary">@color/on_primary</item>
    </style>
</resources>
```

**values-night/styles.xml (dark):**
```xml
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <style name="LaunchTheme" parent="Theme.Material3.DayNight.NoActionBar">
        <item name="android:windowBackground">@drawable/launch_background</item>
        <item name="android:statusBarColor">@android:color/transparent</item>
    </style>

    <style name="NormalTheme" parent="Theme.Material3.DayNight.NoActionBar">
        <item name="android:windowBackground">?android:colorBackground</item>
    </style>
</resources>
```

### 4.7. Cập nhật `launch_background.xml` (branded splash)

```xml
<?xml version="1.0" encoding="utf-8"?>
<layer-list xmlns:android="http://schemas.android.com/apk/res/android">
    <item android:drawable="@color/seed_primary" />
    <item>
        <bitmap
            android:gravity="center"
            android:src="@mipmap/ic_launcher_round" />
    </item>
</layer-list>
```

### 4.8. Tạo `colors.xml`

```xml
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="seed_primary">#6750A4</color>
    <color name="on_primary">#FFFFFF</color>
    <color name="seed_secondary">#625B71</color>
    <color name="on_secondary">#FFFFFF</color>
    <color name="seed_tertiary">#7D5260</color>
    <color name="on_tertiary">#FFFFFF</color>
</resources>
```

### 4.9. Checklist Giai đoạn 1

```markdown
- [ ] Cập nhật `build.gradle.kts` (minSdk 24, targetSdk 35, ABI splits, R8)
- [ ] Cập nhật `gradle.properties` (R8 full mode, incremental, cache)
- [ ] Cập nhật `AndroidManifest.xml` (permissions, deep link, network security)
- [ ] Tạo `network_security_config.xml`
- [ ] Cập nhật `styles.xml` (Material 3)
- [ ] Cập nhật `launch_background.xml` (branded splash)
- [ ] Tạo `colors.xml`
- [ ] Thêm signing config cho release
- [ ] Verify: `flutter build apk --release` thành công
- [ ] Verify: APK size < 30MB
- [ ] Commit: "chore(android): optimize build config, manifest, and resources"
```

---

## 5. GIAI ĐOẠN 2: NATIVE CODE & MAINACTIVITY

### 5.1. Cập nhật `MainActivity.kt`

```kotlin
package com.gasong.ga_song

import android.app.PictureInPictureParams
import android.content.Intent
import android.content.res.Configuration
import android.os.Build
import android.util.Rational
import android.view.WindowInsetsController
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.ryanheise.audioservice.AudioServicePlugin

class MainActivity : FlutterActivity() {

    private val CHANNEL = "com.gasong.ga_song/pip"

    override fun provideFlutterEngine(context: android.content.Context): FlutterEngine? {
        return AudioServicePlugin.getFlutterEngine(context)
    }

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "enterPiP" -> {
                        try {
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                                val aspectRatio = Rational(16, 9)
                                val params = PictureInPictureParams.Builder()
                                    .setAspectRatio(aspectRatio)
                                    .build()
                                val success = enterPictureInPictureMode(params)
                                result.success(success)
                            } else {
                                result.error("UNSUPPORTED", "PiP requires Android 8.0+", null)
                            }
                        } catch (e: Exception) {
                            result.error("PIP_ERROR", e.localizedMessage, null)
                        }
                    }
                    "isPiPSupported" -> {
                        result.success(Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
                    }
                    "setStatusBarColor" -> {
                        val color = call.argument<Int>("color") ?: 0
                        window.statusBarColor = color
                        val controller = window.insetsController
                        if (controller != null) {
                            controller.isAppearanceLightStatusBars = (color == 0xFFFFFFFF.toInt())
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        // Handle deep links
        if (intent.action == Intent.ACTION_VIEW) {
            val data = intent.data
            if (data?.scheme == "ga-song" && data?.host == "play") {
                val songId = data.getQueryParameter("id")
                if (songId != null) {
                    MethodChannel(
                        flutterEngine?.dartExecutor?.binaryMessenger
                            ?: return,
                        CHANNEL
                    ).invokeMethod("onDeepLink", songId)
                }
            }
        }
    }

    override fun onPictureInPictureModeChanged(
        isInPictureInPictureMode: Boolean,
        newConfig: Configuration
    ) {
        super.onPictureInPictureModeChanged(isInPictureInPictureMode, newConfig)

        flutterEngine?.dartExecutor?.binaryMessenger?.let { messenger ->
            MethodChannel(messenger, CHANNEL)
                .invokeMethod("onPiPChanged", mapOf("isInPiP" to isInPictureInPictureMode))
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        // Cleanup MethodChannel handler
        flutterEngine?.dartExecutor?.binaryMessenger?.let { messenger ->
            MethodChannel(messenger, CHANNEL).setMethodCallHandler(null)
        }
    }
}
```

### 5.2. Tạo `AudioNotificationReceiver.kt`

```kotlin
package com.gasong.ga_song

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build

class AudioNotificationReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        // Handle notification action clicks
        val action = intent.action
        if (action != null) {
            // Forward to Flutter via MethodChannel or broadcast
        }
    }

    companion object {
        fun createNotificationChannels(context: Context) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val audioChannel = NotificationChannel(
                    "com.ghitatruongle.gasong.channel.audio",
                    "GA Song Playback",
                    NotificationManager.IMPORTANCE_LOW
                )
                audioChannel.description = "Audio playback controls"

                val manager = context.getSystemService(NotificationManager::class.java)
                manager.createNotificationChannel(audioChannel)
            }
        }
    }
}
```

### 5.3. Cập nhật `PipService` (Dart) — thêm dispose

```dart
// lib/core/pip_service.dart
void dispose() {
  if (!_isAndroid) return;
  _channel.setMethodCallHandler(null); // Cleanup handler
  isInPipNotifier.dispose();
}
```

### 5.4. Checklist Giai đoạn 2

```markdown
- [ ] Cập nhật `MainActivity.kt` (deep link, error handling, dispose)
- [ ] Tạo `AudioNotificationReceiver.kt`
- [ ] Cập nhật `PipService` (dispose handler)
- [ ] Verify: PiP hoạt động trên Android 8+
- [ ] Verify: Deep link hoạt động
- [ ] Commit: "feat(android): improve MainActivity with deep links and cleanup"
```

---

## 6. GIAI ĐOẠN 3: HIỆU NĂNG & APK SIZE

### 6.1. ABI Splits & APK Size Optimization

**Mục tiêu:** Giảm APK size xuống < 20MB (từ ~30MB+).

```kotlin
// build.gradle.kts — thêm vào defaultConfig
splits {
    abi {
        enable true
        reset()
        include "armeabi-v7a", "arm64-v8a"
        // Bỏ qua x86/x86_64 (ít dùng trên mobile)
    }
}
```

### 6.2. Native Lib Optimization

**SoLoud C++ tuning:**
- Biên dịch với `-O3 -DNDEBUG` cho release
- Loại bỏ debug symbols: `android:stripDebugSymbols="true"`
- Chỉ giữ lại `armeabi-v7a` và `arm64-v8a`

### 6.3. RAM & Memory Tuning

**Cập nhật `AndroidManifest.xml`:**
```xml
<application
    android:largeHeap="true"
    android:hardwareAccelerated="true"
    android:usesCleartextTraffic="false"
    android:networkSecurityConfig="@xml/network_security_config">
```

**PlatformCapabilities tuning (Dart):**
```dart
// lib/core/platform_capabilities.dart — cập nhật cho Android
int get maxParticleCount {
  if (isAndroid) {
    // Giảm từ 80 → 60 cho thiết bị yếu
    if (deviceTier == DeviceTier.low) return 40;
    return 60;
  }
  return 150;
}

int get maxStarCount {
  if (isAndroid) {
    if (deviceTier == DeviceTier.low) return 60;
    return 80;  // Giảm từ 100
  }
  return 200;
}

int get maxAudioSourceCacheEntries {
  if (isAndroid) {
    if (deviceTier == DeviceTier.low) return 10;
    return 20;
  }
  return 50;
}

int get maxCoverArtCacheEntries {
  if (isAndroid) {
    if (deviceTier == DeviceTier.low) return 12;
    return 24;
  }
  return 60;
}

Duration get positionTimerInterval {
  if (isAndroid) {
    if (deviceTier == DeviceTier.low) return const Duration(milliseconds: 750);
    return const Duration(milliseconds: 500);
  }
  return const Duration(milliseconds: 250);
}
```

### 6.4. Foreground Service Optimization

**Cập nhật `AudioServiceConfig` (Dart):**
```dart
// lib/main.dart — tối ưu foreground service
AudioServiceConfig(
  androidNotificationChannelId: 'com.ghitatruongle.gasong.channel.audio',
  androidNotificationChannelName: 'GA Song Playback',
  androidNotificationOngoing: true,
  androidNotificationClickAction: 'ga_song.action.MEDIA_PLAYBACK',
  androidStopForegroundOnPause: false,
  androidResumeOnClick: true,
)
```

### 6.5. Battery Optimization

**Tạo `battery_optimization.xml` (guide for user):**
```xml
<!-- Res guide for battery optimization exemption -->
<string name="battery_optimization_message">
    GA Song cần được loại trừ khỏi tối ưu pin để phát nhạc nền liên tục.
</string>
```

### 6.6. Checklist Giai đoạn 3

```markdown
- [ ] Cấu hình ABI splits (armeabi-v7a, arm64-v8a)
- [ ] Cập nhật PlatformCapabilities (Android tier tuning)
- [ ] Tối ưu foreground service config
- [ ] Thêm battery optimization guide
- [ ] Verify: APK size < 20MB
- [ ] Verify: Memory usage < 180MB (idle), < 300MB (playback)
- [ ] Verify: 60fps visualizer trên thiết bị Android trung cấp
- [ ] Commit: "perf(android): optimize APK size, memory, and performance"
```

---

## 7. GIAI ĐOẠN 4: UX & MATERIAL 3

### 7.1. Material 3 Theme Integration

**Tạo `themes.xml`:**
```xml
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <style name="Theme.GASong" parent="Theme.Material3.DayNight.NoActionBar">
        <item name="colorPrimary">@color/seed_primary</item>
        <item name="colorOnPrimary">@color/on_primary</item>
        <item name="colorSecondary">@color/seed_secondary</item>
        <item name="colorOnSecondary">@color/on_secondary</item>
        <item name="colorTertiary">@color/seed_tertiary</item>
        <item name="colorOnTertiary">@color/on_tertiary</item>
        <item name="windowLightStatusBar">true</item>
        <item name="windowLightNavigationBar">true</item>
    </style>
</resources>
```

### 7.2. Splash Screen API (Android 12+)

**Tạo `splash_screen.xml`:**
```xml
<?xml version="1.0" encoding="utf-8"?>
<androidx.core.splashscreen.SplashScreen xmlns:android="http://schemas.android.com/apk/res/android">
    <item android:drawable="@drawable/launch_background" />
</androidx.core.splashscreen.SplashScreen>
```

### 7.3. Notification Channel Optimization

**Dart — tối ưu notification:**
```dart
// lib/core/services/audio_handler_service.dart
// Thêm notification channel grouping
static const String channelGroupKey = 'ga_song_audio';
static const String channelGroupName = 'Audio Playback';
```

### 7.4. Haptic Feedback Enhancement

**Cập nhật `haptic_helper.dart`:**
```dart
// lib/ui/utils/haptic_helper.dart
enum HapticType { light, medium, heavy, selection, success, warning, error }

Future<void> safeHaptic(HapticType type) async {
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    switch (type) {
      case HapticType.light:
        HapticFeedback.lightImpact();
      case HapticType.medium:
        HapticFeedback.mediumImpact();
      case HapticType.heavy:
        HapticFeedback.heavyImpact();
      case HapticType.selection:
        HapticFeedback.selectionClick();
      case HapticType.success:
        HapticFeedback.lightImpact();
      case HapticType.warning:
        HapticFeedback.mediumImpact();
      case HapticType.error:
        HapticFeedback.heavyImpact();
    }
  }
}
```

### 7.5. PiP Enhancement

**Cập nhật `MainActivity.kt` — PiP với nhiều aspect ratios:**
```kotlin
"enterPiP" -> {
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
        val aspectRatios = listOf(
            Rational(16, 9),  // Standard
            Rational(4, 3),   // Alternative
            Rational(1, 1)    // Square
        )
        val params = PictureInPictureParams.Builder()
            .setAspectRatio(aspectRatios[0])
            .setActions(listOf()) // Add custom actions
            .build()
        enterPictureInPictureMode(params)
    }
}
```

### 7.6. Checklist Giai đoạn 4

```markdown
- [ ] Tích hợp Material 3 theme
- [ ] Cập nhật splash screen (Android 12+ API)
- [ ] Tối ưu notification channels
- [ ] Cập nhật haptic feedback
- [ ] Cải thiện PiP (multiple aspect ratios)
- [ ] Verify: Material 3 theme áp dụng trên Android
- [ ] Verify: Splash mượt, không bấp bênh
- [ ] Commit: "feat(android): Material 3 theme, splash, and UX improvements"
```

---

## 8. GIAI ĐOẠN 5: CI/CD & TESTING

### 8.1. Cập nhật CI workflow

**`.github/workflows/ci.yml` — thêm AAB build:**
```yaml
build-android-aab:
  name: Build Android App Bundle
  runs-on: ubuntu-latest
  needs: test
  steps:
    - uses: actions/checkout@v4
    - uses: actions/setup-java@v4
      with:
        distribution: 'zulu'
        java-version: '17'
    - uses: subosito/flutter-action@v2
      with:
        flutter-version: ${{ env.FLUTTER_VERSION }}
        channel: stable
    - run: flutter pub get
    - name: Build AAB
      run: flutter build appbundle --release
    - name: Check AAB size
      run: |
        AAB="build/app/outputs/bundle/release/app-release.aab"
        if [ -f "$AAB" ]; then
          SIZE_MB=$(du -m "$AAB" | cut -f1)
          echo "AAB size: ${SIZE_MB}MB"
          if [ "$SIZE_MB" -gt 15 ]; then
            echo "::warning::AAB ${SIZE_MB}MB exceeds 15MB target"
          fi
        fi
    - name: Upload AAB artifact
      uses: actions/upload-artifact@v4
      with:
        name: android-aab
        path: build/app/outputs/bundle/release/app-release.aab
```

### 8.2. APK Analysis Step

```yaml
analyze-apk:
  name: APK Analysis
  runs-on: ubuntu-latest
  needs: build-android
  steps:
    - uses: actions/checkout@v4
    - uses: actions/download-artifact@v4
      with:
        name: android-apk
        path: artifacts/
    - name: Analyze APK
      run: |
        # Install APK analyzer
        wget https://github.com/rednaga/apk-analyzer/releases/latest/download/apk-analyzer-linux.tar.gz
        tar -xzf apk-analyzer-linux.tar.gz
        ./apk-analyzer analyze artifacts/app-release.apk
```

### 8.3. Device Test Matrix (có thể thêm sau)

```yaml
test-android-device:
  name: Android Device Tests
  runs-on: macos-latest
  needs: build-android
  steps:
    - uses: actions/checkout@v4
    - uses: reactivecircus/android-emulator-runner@v2
      with:
        api-level: 33
        script: flutter test --flavor android
```

### 8.4. Checklist Giai đoạn 5

```markdown
- [ ] Thêm AAB build vào CI
- [ ] Thêm APK analysis step
- [ ] Cấu hình device test matrix (tùy chọn)
- [ ] Verify: CI build APK + AAB thành công
- [ ] Verify: APK size < 20MB, AAB < 15MB
- [ ] Commit: "ci(android): add AAB build and APK analysis"
```

---

## 9. METRICS & BENCHMARKS

### 9.1. Performance Targets (Android)

| Metric | Target | Measurement |
|--------|--------|-------------|
| APK size | ≤ 20MB | `du -m app-release.apk` |
| AAB size | ≤ 15MB | `du -m app-release.aab` |
| Cold startup | ≤ 2.0s | `flutter run --profile` |
| Memory (idle) | < 180MB | `dumpsys meminfo` |
| Memory (playback + visualizer) | < 300MB | `dumpsys meminfo` |
| Library scroll FPS | ≥ 58 avg | DevTools overlay |
| Visualizer FPS | ≥ 58 stable 5min | DevTools overlay |
| Jank frames | < 5% | DevTools "Slow frames" |
| Battery drain (1hr playback) | < 15% | Battery Historian |

### 9.2. Quality Gates

| Check | Tool | Fail condition |
|-------|------|----------------|
| APK size | CI step | > 20MB |
| AAB size | CI step | > 15MB |
| `flutter analyze` | CI | > 0 issues |
| Test coverage | CI | `lib/core/` < 70% |
| No debugPrint | grep | > 0 occurrences |
| No hardcoded colors | grep | > 0 in UI |

### 9.3. Device Test Matrix

| Device | Android | Tier | Notes |
|--------|---------|------|-------|
| Pixel 8 | 14 | High | Flagship |
| Samsung A52 | 13 | Mid | Popular mid-range |
| Xiaomi Redmi Note 10 | 12 | Mid | Popular in VN |
| Moto G50 | 11 | Low | Budget device |

---

## 10. RỦI RO & MITIGATION

| # | Rủi ro | Tác động | Giải pháp |
|---|--------|----------|-----------|
| R1 | Tăng minSdk từ 21→24 | Mất hỗ trợ thiết bị cũ | Kiểm tra analytics, chỉ số thiết bị < 24 |
| R2 | R8 full mode gây crash | Crash runtime | Test kỹ, có fallback disable R8 |
| R3 | ABI splits gây lỗi native | Crash native | Test trên cả 2 architectures |
| R4 | Material 3 theme conflict | UI lỗi | Test trên cả light/dark mode |
| R5 | PiP enhancement gây crash | Crash khi vào PiP | Test trên Android 8-14 |
| R6 | Notification permission fail | Không hiện notification | Graceful fallback, hướng dẫn user |
| R7 | Battery optimization gây stop service | Dừng phát nhạc nền | Guide user disable battery optimization |

---

## 11. CHECKLIST TỔNG THỂ

### 11.1. Giai đoạn 1 — Build & Manifest
```markdown
- [ ] Cập nhật build.gradle.kts
- [ ] Cập nhật gradle.properties
- [ ] Cập nhật AndroidManifest.xml
- [ ] Tạo network_security_config.xml
- [ ] Cập nhật styles.xml (Material 3)
- [ ] Cập nhật launch_background.xml
- [ ] Tạo colors.xml
- [ ] Thêm signing config
- [ ] Verify: build thành công, APK < 30MB
```

### 11.2. Giai đoạn 2 — Native Code
```markdown
- [ ] Cập nhật MainActivity.kt
- [ ] Tạo AudioNotificationReceiver.kt
- [ ] Cập nhật PipService (dispose)
- [ ] Verify: PiP, deep link hoạt động
```

### 11.3. Giai đoạn 3 — Performance
```markdown
- [ ] Cấu hình ABI splits
- [ ] Cập nhật PlatformCapabilities
- [ ] Tối ưu foreground service
- [ ] Thêm battery optimization guide
- [ ] Verify: APK < 20MB, memory < 300MB, 60fps
```

### 11.4. Giai đoạn 4 — UX
```markdown
- [ ] Material 3 theme
- [ ] Splash screen API
- [ ] Notification channels
- [ ] Haptic feedback
- [ ] PiP enhancement
- [ ] Verify: Material 3, splash mượt
```

### 11.5. Giai đoạn 5 — CI/CD
```markdown
- [ ] Thêm AAB build
- [ ] Thêm APK analysis
- [ ] Cấu hình device test (tùy chọn)
- [ ] Verify: CI build thành công
```

---

## 12. TÀI NGUYÊN THAM KHẢO

- [Android Developer — App Bundle](https2://developer.android.com/kotlin/android-bundle)
- [Android Developer — Splash Screen API](https2://developer.android.com/develop/ui/views/launch/splash-screen)
- [Android Developer — R8 Full Mode](https2://developer.android.com/r8/full-mode)
- [Android Developer — Foreground Service](https2://developer.android.com/guide/components/foreground-services)
- [Flutter — Android Build Release](https2://docs.flutter.dev/deployment/android)
- [Material 3 — Android](https2://m3.material.io/)

---

**Tác giả:** ZCode (phân tích & đề xuất tối ưu)  
**Ngày cập nhật:** 2026-07-23  
**Phiên bản:** 1.0