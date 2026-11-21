import java.util.Base64
import java.util.Properties

// Release signing: android/key.properties (never committed) points to the
// shared Joruri release key. Every APK given to users must be signed with
// that same key, otherwise phones refuse to install it as an update.
// Without key.properties, release builds fall back to the debug key so
// `flutter run --release` still works on any computer.
val keyProperties = Properties().apply {
    val f = rootProject.file("key.properties")
    if (f.exists()) f.inputStream().use { load(it) }
}

// Google Play build: flutter build appbundle --dart-define=PLAY_STORE=true
// Play delivers the updates, and does not allow an app to install updates
// itself, so that build leaves out the in-app updater's install permission
// (src/play/AndroidManifest.xml). Flutter passes the --dart-define values to
// Gradle base64-encoded in the "dart-defines" property.
val playStore = (project.findProperty("dart-defines") as String?)
    ?.split(",")
    ?.map { String(Base64.getDecoder().decode(it)) }
    ?.contains("PLAY_STORE=true") == true

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "bd.joruri.joruri_bd"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // flutter_local_notifications (disaster alerts) needs Java 8+ APIs on older Android.
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    defaultConfig {
        applicationId = "bd.joruri.joruri_bd"
        minSdk = 26
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (keyProperties.getProperty("storeFile") != null) {
            create("release") {
                storeFile = file(keyProperties.getProperty("storeFile"))
                storePassword = keyProperties.getProperty("storePassword")
                keyAlias = keyProperties.getProperty("keyAlias")
                keyPassword = keyProperties.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.findByName("release") ?: signingConfigs.getByName("debug")
        }
    }

    if (playStore) {
        sourceSets.getByName("release").manifest.srcFile("src/play/AndroidManifest.xml")
    }
}

kotlin {
    compilerOptions {
        jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_11)
    }
}

flutter {
    source = "../.."
}

dependencies {
    // FileProvider for in-app updates (MainActivity.installApk).
    implementation("androidx.core:core-ktx:1.13.1")
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
