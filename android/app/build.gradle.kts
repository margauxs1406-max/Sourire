import java.util.Properties
import java.io.FileInputStream

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.margauxsilva.sourire"
    compileSdk = 36 // <-- PASSE À 36 POUR LE LOGICIEL DE COMPILATION
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.margauxsilva.sourire"
        minSdk = flutter.minSdkVersion
        targetSdk = 36 // Mis à jour : conformité à l'exigence Google Play du 31/08/2026 (Android 16)
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
    }

    signingConfigs {
        create("release") {
            // Lecture TOLÉRANTE des propriétés de signature.
            //
            // Avec `as String`, l'absence de key.properties faisait échouer
            // jusqu'à une simple compilation debug, sur une erreur de
            // transtypage nul qui ne dit rien du vrai problème. Le projet doit
            // rester compilable sans le fichier de signature — lequel ne doit,
            // lui, jamais être versionné.
            keyAlias = keystoreProperties["keyAlias"] as String?
            keyPassword = keystoreProperties["keyPassword"] as String?
            storeFile = (keystoreProperties["storeFile"] as String?)?.let { file(it) }
            storePassword = keystoreProperties["storePassword"] as String?
        }
    }

    buildTypes {
        release {
            // Sans key.properties, on signe en debug plutôt que d'échouer :
            // l'AAB produit ne sera pas publiable, mais le projet se compile.
            signingConfig = if (keystorePropertiesFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }
}

flutter {
    source = "../.."
}

// AJOUT : On crée le bloc dependencies manquant tout en bas pour injecter la bibliothèque de desugaring
dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.2")
}