#!/bin/bash
set -e

QEMU_VERSION="9.2.0"
API_LEVEL="24"
OUTPUT_DIR="${OUTPUT_DIR:-$(pwd)/assets/qemu/android}"
NDK_ROOT="${NDK_ROOT:-$ANDROID_NDK_HOME}"

if [ -z "$NDK_ROOT" ]; then
    echo "ERROR: ANDROID_NDK_HOME not set. Install Android NDK r27+"
    exit 1
fi

mkdir -p "$OUTPUT_DIR/arm64" "$OUTPUT_DIR/x86_64"

download_qemu() {
    if [ ! -d "qemu-$QEMU_VERSION" ]; then
        wget -q "https://download.qemu.org/qemu-$QEMU_VERSION.tar.xz"
        tar -xf "qemu-$QEMU_VERSION.tar.xz"
    fi
}

build_target() {
    local ARCH="$1"
    local ANDROID_ARCH="$2"
    local QEMU_TARGET="$3"
    
    echo "Building QEMU $QEMU_VERSION for Android $ARCH (API $API_LEVEL)..."
    
    cd "qemu-$QEMU_VERSION"
    
    rm -rf build-android-$ARCH
    mkdir -p build-android-$ARCH
    cd build-android-$ARCH
    
    "$NDK_ROOT/ndk-build" --version > /dev/null 2>&1 || true
    
    PATH="$NDK_ROOT/toolchains/llvm/prebuilt/linux-x86_64/bin:$PATH"
    
    CC="${ANDROID_ARCH}-linux-android${API_LEVEL}-clang" \
    CXX="${ANDROID_ARCH}-linux-android${API_LEVEL}-clang++" \
    ../configure \
        --host="$QEMU_TARGET" \
        --target-list="x86_64-softmmu,aarch64-softmmu" \
        --enable-tcg \
        --disable-kvm \
        --disable-xen \
        --disable-hvf \
        --disable-whpx \
        --disable-virglrenderer \
        --disable-opengl \
        --disable-sdl \
        --disable-gtk \
        --disable-vnc \
        --disable-spice \
        --disable-libusb \
        --disable-usb-redir \
        --disable-libiscsi \
        --disable-libnfs \
        --disable-rbd \
        --disable-pngx \
        --disable-virtiofs \
        --disable-seccomp \
        --disable-cap-ng \
        --disable-attr \
        --disable-brlapi \
        --disable-curses \
        --disable-iconv \
        --disable-mpath \
        --disable-libudev \
        --disable-lzfse \
        --disable-snappy \
        --disable-zstd \
        --without-default-libs \
        --extra-cflags="--sysroot=$NDK_ROOT/toolchains/llvm/prebuilt/linux-x86_64/sysroot -I$NDK_ROOT/toolchains/llvm/prebuilt/linux-x86_64/sysroot/usr/include" \
        --extra-ldflags="--sysroot=$NDK_ROOT/toolchains/llvm/prebuilt/linux-x86_64/sysroot -L$NDK_ROOT/toolchains/llvm/prebuilt/linux-x86_64/lib/gcc/${ANDROID_ARCH}/${API_LEVEL}/../../.."
    
    make -j$(nproc) qemu-system-x86_64 qemu-system-aarch64
    
    cp qemu-system-x86_64 "$OUTPUT_DIR/$ARCH/"
    cp qemu-system-aarch64 "$OUTPUT_DIR/$ARCH/"
    
    echo "Built QEMU for Android $ARCH"
    cd ../..
}

main() {
    download_qemu
    
    build_target "arm64" "aarch64" "aarch64-linux-android"
    build_target "x86_64" "x86_64" "x86_64-linux-android"
    
    echo "QEMU Android build complete. Binaries in $OUTPUT_DIR/"
}

main "$@"