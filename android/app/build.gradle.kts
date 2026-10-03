import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Optional local signing config used only by the compatibility build.
// Credentials stay in the supplied properties file, never in the repository.
val upgradeSigning = Properties()
val upgradeSigningPath = System.getenv("HUIKE_UPGRADE_SIGNING_PROPERTIES")
if (upgradeSigningPath != null) {
    file(upgradeSigningPath).inputStream().use { upgradeSigning.load(it) }
}

android {
    namespace = "com.huike.huike_timetable"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.huike.huike_timetable"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (upgradeSigningPath != null) {
            create("legacyUpgrade") {
                keyAlias = upgradeSigning.getProperty("keyAlias")
                keyPassword = upgradeSigning.getProperty("keyPassword")
                storeFile = file(upgradeSigning.getProperty("storeFile"))
                storePassword = upgradeSigning.getProperty("storePassword")
            }
        }
    }

    flavorDimensions += "distribution"
    productFlavors {
        create("huike") {
            dimension = "distribution"
            signingConfig = signingConfigs.getByName("debug")
        }
        create("legacyUpgrade") {
            dimension = "distribution"
            applicationId = "cn.edu.ncpu.timetable.ncpu_timetable"
            // Greater than legacy universal and ABI-split version codes.
            versionCode = 10006
            versionName = "1.1.0"
            signingConfig = if (upgradeSigningPath != null) {
                signingConfigs.getByName("legacyUpgrade")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }

    buildTypes {
        getByName("debug") {
            // Signing belongs to the flavor, including debug-mode upgrades.
            signingConfig = null
        }
        release {
            signingConfig = null
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
