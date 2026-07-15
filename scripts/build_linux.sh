#!/bin/bash
# Build script for Linux AppImage with bundled QEMU

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "Building LWVM Linux distributions..."

# Check KVM permissions and warn if needed
check_kvm_permissions() {
    if command -v getent &> /dev/null; then
        if ! getent group kvm > /dev/null 2>&1; then
            echo "Warning: 'kvm' group not found. KVM may not work on this system."
        else
            if ! groups $USER | grep -q kvm; then
                echo "Warning: User '$USER' not in 'kvm' group. Run: sudo usermod -a -G kvm $USER"
            fi
        fi
    fi
}

# Check hugepages availability
check_hugepages() {
    if [ -f /proc/meminfo ]; then
        huge_total=$(awk '/HugePages_Total/ {print $3}' /proc/meminfo 2>/dev/null || echo 0)
        if [ "$huge_total" -eq 0 ] 2>/dev/null; then
            echo "Note: Hugepages not configured. Consider enabling for better performance:"
            echo "  echo 2048 | sudo tee /proc/sys/vm/nr_hugepages"
        fi
    fi
}

check_kvm_permissions
check_hugepages

# Build Flutter Linux app
flutter config --enable-linux-desktop
flutter pub get
flutter build linux --release

# Install linux-deploy if not present
if ! command -v linuxdeploy &> /dev/null; then
    echo "Installing linux-deploy..."
    wget -O linuxdeploy https://github.com/linuxdeploy/linuxdeploy/releases/download/continuous/linuxdeploy-x86_64.AppImage
    chmod +x linuxdeploy
fi

# Download QEMU static binaries
QEMU_VERSION="${QEMU_VERSION:-9.0.0}"
QEMU_URL="https://github.com/qemu/qemu/releases/download/v${QEMU_VERSION}/qemu-system-x86_64-static"

download_qemu() {
    local dest_dir="$1"
    mkdir -p "$dest_dir"
    echo "Downloading QEMU $QEMU_VERSION..."
    wget -O "$dest_dir/qemu-system-x86_64" "$QEMU_URL" 2>/dev/null || {
        echo "QEMU download failed, using system QEMU if available"
        command -v qemu-system-x86_64 && cp $(command -v qemu-system-x86_64) "$dest_dir/" || true
    }
    chmod +x "$dest_dir/qemu-system-x86_64" 2>/dev/null || true
}

# Create AppImage with QEMU bundled
create_appimage() {
    local build_dir="$PROJECT_ROOT/build/linux/x64/release/bundle"
    local dest_dir="$build_dir/extra/bin"
    
    download_qemu "$dest_dir"
    
    cd "$build_dir"
    
    # Create AppDir structure
    mkdir -p usr/bin
    cp -r * usr/
    cp -r extra usr/
    
    echo "Creating AppImage..."
    ARCH=x86_64 ../linuxdeploy --appdir appdir \
        --output appimage \
        --icon-file "$PROJECT_ROOT/assets/icon.png" \
        --executable usr/lwvm \
        --desktop-file "$PROJECT_ROOT/linux/lwvm.desktop" \
        --output-dir "$PROJECT_ROOT/build/" 2>/dev/null || echo "AppImage creation requires manual intervention"
}

# Create Flatpak
create_flatpak() {
    echo "Flatpak manifest available at linux/com.example.lwvm.yaml"
    flatpak-builder --user --install --force-clean build-dir linux/com.example.lwvm.yaml
}

# Main build
case "${1:-appimage}" in
    appimage)
        create_appimage
        ;;
    flatpak)
        create_flatpak
        ;;
    *)
        echo "Usage: $0 [appimage|flatpak]"
        exit 1
        ;;
esac

echo "Build complete!"