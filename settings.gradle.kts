pluginManagement {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }

    plugins {
        kotlin("multiplatform") version "2.0.0"
        kotlin("plugin.serialization") version "2.0.0"
        kotlin("android") version "2.0.0"
        id("org.jetbrains.kotlin.plugin.compose") version "2.0.0"
        id("com.android.library") version "8.5.2"
        id("com.android.application") version "8.5.2"
    }
}

dependencyResolutionManagement {
    repositories {
        google()
        mavenCentral()
    }
}

rootProject.name = "price-compare"
include(":app")
