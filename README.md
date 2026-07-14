# LWVM - Local Web Virtual Machine

ChromeOS-first VM platform built with Flutter.

## Features

- Desktop support: Windows, macOS, Linux
- Android support for ChromeOS ARCVM
- QEMU binaries for all platforms

## Linux KVM Optimizations

LWVM automatically detects and enables KVM optimizations on Linux:

### KVM Detection

The app checks `/dev/kvm` for read/write permissions and falls back to TCG if unavailable.

### HugePages

When hugepages are configured (`/proc/meminfo` shows `HugePages_Total > 0`), LWVM uses:
```bash
-object memory-backend-file,id=mem,size=4G,mem-path=/dev/hugepages,share=on,prealloc=on
-numa node,memdev=mem
```

### VirGL 3D Acceleration

Detects `libvirglrenderer.so` via `ldconfig -p` and enables:
```bash
-device virtio-gpu-pci,virgl=on
```

### VirtIO-FS Shared Folders

On kernel 5.4+, detects support and enables VirtIO-FS for host-guest file sharing:
```bash
-fsdev local,id=fsdev0,path=/host/path,security_model=mapped-xattr
-device virtio-fs-pci,fsdev=fsdev0,mount_tag=host_shared,queue-size=1024
```

### Installation Requirements

Enable KVM and HugPages on Linux:
```bash
# Add user to kvm group
sudo usermod -a -G kvm $USER

# Setup hugepages (example for 4GB)
echo 2048 | sudo tee /proc/sys/vm/nr_hugepages
echo mount -t hugetlbfs none /dev/hugepages >> /etc/fstab

# Install virgl for 3D acceleration
sudo apt install libvirglrenderer0
```

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