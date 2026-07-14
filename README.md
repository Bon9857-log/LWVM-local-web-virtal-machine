# LWVM - Local Web Virtual Machine

ChromeOS-first VM platform built with Flutter.

## Features

- Desktop support: Windows, macOS, Linux
- Android support for ChromeOS ARCVM
- QEMU binaries for all platforms

## Building

### Prerequisites

- Flutter SDK 3.24+
- Android NDK r27+ (for Android QEMU builds)
- Xcode 15+ (for macOS)
- Visual Studio 2022 (for Windows)

### Initialization

```bash
# Initialize Flutter project with all platforms
flutter create --platforms=android,windows,macos,linux .
```

### Build Commands

```bash
# Android QEMU cross-compile
export ANDROID_NDK_HOME=/path/to/ndk
./scripts/build_qemu_android.sh

# Flutter builds
flutter pub get
flutter build apk --release
flutter build linux --release
flutter build windows --release
flutter build macos --release
```

## Project Structure

```
lwvm/
├── lib/              # Flutter Dart code
├── android/          # Android app (ChromeOS ARCVM)
├── windows/          # Windows runner
├── macos/            # macOS runner
├── linux/            # Linux runner
├── scripts/
│   └── build_qemu_android.sh   # QEMU Android NDK cross-compile script
├── assets/qemu/      # QEMU binaries per platform
│   └── android/
│       ├── arm64/
│       └── x86_64/
└── .github/workflows/
    ├── ci.yml      # Matrix build for all platforms
    └── release.yml # Release artifacts (APK + MSIX + DMG + AppImage)
```

## CI/CD

GitHub Actions builds on all platforms:
- Linux: AppImage
- macOS: DMG
- Windows: MSIX
- Android: APK (arm64, x86_64)