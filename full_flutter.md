# Flutter Android Modernization Specification

## Objective

Convert this project into a clean, fully modern Flutter project.

The project is new and has no legacy support requirements.

Do not preserve obsolete Android code, Gradle configurations, generated files, or compatibility layers.

Target:

* Latest stable Flutter
* Latest Android Gradle Plugin supported by Flutter
* Kotlin-based Android entry point
* Flutter-managed plugin registration
* No legacy embedding APIs
* No manually maintained generated files

---

# Migration Rules

## Rule 1: Android Is Infrastructure

Treat everything inside:

```text
android/
```

as generated infrastructure unless it contains project-specific configuration.

Rebuild Android scaffolding from a fresh Flutter template whenever possible.

Preserve only:

* applicationId
* package name
* signing configuration
* version information
* Firebase configuration
* permissions
* deep links
* custom AndroidManifest entries
* custom native integrations actually used by the application

Everything else may be regenerated.

---

# Rule 2: Remove Legacy Flutter Android Code

Delete any legacy Flutter Android embedding code.

Search for:

```java
io.flutter.app.FlutterActivity
io.flutter.app.FlutterApplication
io.flutter.plugin.common.PluginRegistry
registerWith
GeneratedPluginRegistrant.registerWith
```

Remove all occurrences.

Only modern embedding is allowed.

MainActivity must resemble:

```kotlin
package com.example.app

import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity()
```

No additional registration code.

---

# Rule 3: Remove GeneratedPluginRegistrant

Delete:

```text
android/app/src/main/java/io/flutter/plugins/GeneratedPluginRegistrant.java
```

Delete any manually committed:

```text
GeneratedPluginRegistrant.*
```

Flutter must generate plugin registration automatically.

No source-controlled generated registrant files are allowed.

---

# Rule 4: Use Kotlin Only

If Java and Kotlin coexist unnecessarily:

* migrate MainActivity to Kotlin
* remove unused Java activity files

Target:

```text
android/app/src/main/kotlin/
```

as the primary Android source location.

---

# Rule 5: Modern Gradle Plugins

Use plugin DSL only.

Avoid old:

```gradle
apply plugin:
```

style configuration.

Preferred:

```gradle
plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("dev.flutter.flutter-gradle-plugin")
}
```

---

# Rule 6: Remove Deprecated Gradle Logic

Search and remove:

```gradle
apply from:
flutter.gradle
```

legacy Flutter loading mechanisms.

Flutter Gradle Plugin must manage integration.

---

# Rule 7: Remove Dead Native Code

Inspect:

```text
android/app/src/main/
```

Remove any native classes not referenced.

Examples:

* unused Activities
* unused Services
* unused BroadcastReceivers
* unused helper classes

If a native component is not required by Flutter plugins or app functionality, delete it.

---

# Rule 8: Rebuild Android Folder

Create a temporary fresh Flutter project using the same Flutter version.

Compare:

```text
android/
```

with the project's Android folder.

Adopt the fresh template structure wherever possible.

Preserve only project-specific settings.

---

# Rule 9: Validate Android Manifest

Review:

```text
android/app/src/main/AndroidManifest.xml
```

Remove:

* duplicate permissions
* obsolete permissions
* unused providers
* unused receivers
* unused services

Keep only permissions actually required by dependencies and app features.

---

# Rule 10: Validate Dependencies

Inspect:

```yaml
pubspec.yaml
```

For each package:

1. confirm it is used
2. confirm it supports latest Flutter
3. confirm Android embedding v2 compatibility

Remove unused packages.

Replace abandoned packages with maintained alternatives.

---

# Rule 11: Clean Build System

After migration execute:

```bash
flutter clean

rm -rf .dart_tool
rm -rf build
rm -rf android/.gradle
rm -rf android/build

flutter pub get
```

---

# Rule 12: Regenerate Flutter Artifacts

Run:

```bash
flutter create .
```

if Android scaffolding is inconsistent.

Preserve application source code.

Regenerate infrastructure.

---

# Rule 13: Release Build Verification

The migration is complete only if all succeed:

```bash
flutter doctor -v
```

```bash
flutter analyze
```

```bash
flutter test
```

```bash
flutter build apk --release
```

```bash
flutter build appbundle --release
```

---

# Rule 14: Forbidden

Do NOT:

* add compatibility hacks
* add temporary workarounds
* suppress build errors
* downgrade Flutter unnecessarily
* keep legacy Android embedding code
* keep generated source files in Git
* preserve unused native code "just in case"

If a component is obsolete and unused, remove it.

---

# Final Deliverables

Provide:

1. List of deleted files
2. List of migrated files
3. List of regenerated files
4. Dependency changes
5. Android configuration changes
6. Final successful release build output
7. Remaining technical debt (if any)

Goal: A clean Flutter project that behaves like a freshly generated Flutter application while preserving only the business logic and required Android-specific configuration.
