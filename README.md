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

### Base Images

Pre-built VM images are available on GitHub Container Registry:

| Image | Description | Size |
|-------|-------------|------|
| `alpine:3.20` | Minimal Alpine Linux | ~500MB |
| `alpine-dev:3.20` | Alpine with dev tools (git, vim, python, node, go, docker-cli) | ~500MB |
| `minimal-linux:3.20` | Minimal Linux with BusyBox + SSH | ~100MB |
| `ubuntu:24.04-minimal` | Ubuntu Server 24.04 | ~3GB |
| `ubuntu-webdev:24.04` | Ubuntu with Docker, VSCode, Node, Python | ~3GB |
| `ubuntu-datasci:24.04` | Ubuntu with Jupyter, PyTorch, Pandas | ~4GB |
| `zorin-os:17` | **Premium Desktop** - Polished Zorin OS 17 desktop experience | ~2.5GB (amd64), ~3GB (arm64) |

Pull images with:
```bash
# Login to GHCR
echo $GITHUB_TOKEN | oras login ghcr.io -u $USERNAME --password-stdin

# Pull specific architecture
oras pull ghcr.io/<owner>/lwvm-images/zorin-os:17-amd64
```