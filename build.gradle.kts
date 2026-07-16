// AGP/Kotlin versions bumped from the plan's 8.5.2/1.9.24 to 8.9.1/2.0.21 for compatibility with the local JDK; jvmTarget bumped 17->21 to match in app/build.gradle.kts.
// Gradle wrapper version bumped to 8.12 (gradle/wrapper/gradle-wrapper.properties) because AGP 8.9.1 requires Gradle >= 8.11.1.
plugins {
    id("com.android.application") version "8.9.1" apply false
    id("org.jetbrains.kotlin.android") version "2.0.21" apply false
}
