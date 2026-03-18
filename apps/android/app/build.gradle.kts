plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
}

android {
    namespace = "com.nexusvpn.app"
    compileSdk = 34

    defaultConfig {
        minSdk = 26
        targetSdk = 34
        versionCode = 1
        versionName = "1.0"
    }

    // Здесь мы задаем измерение для брендов
    flavorDimensions += "brand"

    productFlavors {
        create("nebula") {
            dimension = "brand"
            applicationIdSuffix = ".nebula" // установится как com.nexusvpn.app.nebula
        }
        create("pepewatafa") {
            dimension = "brand"
            applicationIdSuffix = ".pepewatafa" // установится как com.nexusvpn.app.pepewatafa
        }
    }
}

dependencies {
    implementation("androidx.core:core-ktx:1.12.0")
    implementation("androidx.compose.ui:ui:1.6.0")
    implementation("androidx.compose.material3:material3:1.2.0")
    
    // Link gomobile exported AAR (Android Archive) containing our compiled Go Core SDK
    implementation(files("libs/core.aar"))
}
