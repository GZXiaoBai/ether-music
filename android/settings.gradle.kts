pluginManagement {
    val flutterSdkPath = run {
        val properties = java.util.Properties()
        val localPropertiesFile = file("local.properties")
        if (localPropertiesFile.exists()) {
            localPropertiesFile.inputStream().use { properties.load(it) }
        }
        val flutterSdkPath = properties.getProperty("flutter.sdk")
            ?: System.getenv("FLUTTER_HOME")
            ?: run {
                val process = ProcessBuilder("which", "flutter").start()
                val flutterPath = process.inputStream.bufferedReader().readLine()
                if (flutterPath != null && flutterPath.isNotBlank()) {
                    // flutter binary is usually at flutter/bin/flutter, we need flutter/
                    java.io.File(flutterPath).parentFile?.parentFile?.absolutePath
                } else {
                    null
                }
            }
        require(flutterSdkPath != null) { 
            "flutter.sdk not set in local.properties and FLUTTER_HOME env var is not set" 
        }
        flutterSdkPath
    }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.11.1" apply false
    id("org.jetbrains.kotlin.android") version "2.2.20" apply false
}

include(":app")
