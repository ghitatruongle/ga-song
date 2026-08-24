plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android Gradle plugin.
    id("dev.flutter.flutter-gradle-plugin")
}

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
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.gasong.ga_song"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 24  // Tăng từ 21 → 24 (Android 7.0+) để hỗ trợ SoLoud native tốt hơn
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // ABI splits are handled by `flutter build apk --split-per-abi` so the
    // classic `splits {}` block is not used here — it conflicts with
    // `flutter build appbundle` (AGP issue 402800800).

    buildTypes {
        release {
            // Bật R8 full mode + resource shrinking để giảm APK size
            isMinifyEnabled = true
            isShrinkResources = true

            // Hỗ trợ cả arm64-v8a và armeabi-v7a (cho thiết bị 32-bit như SM J610F)
            ndk {
                // "full" embeds full native debug symbols in the
                // release APK (bloats every ABI). No crash-symbolication
                // pipeline is wired yet, so strip them for smaller artifacts.
                debugSymbolLevel = "none"
            }

            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")

            // ProGuard/R8 optimization
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }

        debug {
            // Tắt R8 trong debug build để tăng tốc độ biên dịch và thử nghiệm
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }

    // Bundle config — tối ưu native libs cho Play Store
    bundle {
        language {
            enableSplit = true
        }
        density {
            enableSplit = true
        }
    }

    // Packaging — loại bỏ native libs và metadata không cần thiết
    packaging {
        resources {
            excludes += setOf(
                "META-INF/{AL2.0,LGPL2.1}",
                "META-INF/DEPENDENCIES",
                "META-INF/LICENSE*",
                "META-INF/NOTICE*"
            )
        }
        // Bật native lib compression — giảm APK size
        jniLibs {
            useLegacyPackaging = false
        }
    }

    // AAPT options — tránh nén lại native libs (.so)
    // Note: aaptOptions is deprecated in AGP 8.11+, use androidResources in build script instead
    // noCompress is handled by default for .so files in modern AGP
}

flutter {
    source = "../.."
}
