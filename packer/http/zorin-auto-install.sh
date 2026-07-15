#!/bin/bash
# Zorin OS auto-install for LWVM
# This script runs after Zorin OS installation to configure VM-specific settings

set -e

# Remove installer packages
apt-get purge -y calamares ubiquity || true

# Install additional VM packages
apt-get install -y qemu-guest-agent spice-vdagent || true
systemctl enable qemu-guest-agent || true
systemctl enable spice-vdagent || true

# Install HWE kernel for better hardware support
apt-get install -y --install-recommends linux-generic-hwe-24.04 || true

# Install Flatpak and enable Flathub
apt-get install -y flatpak || true
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo || true

# Pre-install applications
apt-get install -y libreoffice firefox || true

# Configure auto-login for GDM
cat > /etc/gdm3/custom.conf << 'EOF'
[daemon]
AutomaticLoginEnable = true
AutomaticLogin = lwvm
EOF

# Disable screen lock for VM use
su lwvm -c "DISPLAY=:0 dbus-launch gsettings set org.gnome.desktop.screensaver lock-enabled false" || true

# Reduce animations for better VM performance
su lwvm -c "DISPLAY=:0 dbus-launch gsettings set org.gnome.desktop.interface enable-animations false" || true

# Set Zorin Blue/Dark theme
su lwvm -c "DISPLAY=:0 dbus-launch gsettings set org.zorin.desktop color-scheme 'blue'" || true
su lwvm -c "DISPLAY=:0 dbus-launch gsettings set org.gnome.desktop.interface gtk-theme 'ZorinBlue-Dark'" || true

# Clean up
apt-get autoremove -y || true
apt-get clean || true
rm -rf /var/log/* || true

echo "Zorin OS post-install configuration complete"