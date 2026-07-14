#!/bin/sh
set -e

# Alpine Linux 3.20 minimal auto-install for LWVM
# This script runs in the Alpine live environment and builds a minimal disk image

# Enable network
echo "Configuring network..."
ip link set eth0 up 2>/dev/null || true
udhcpc -i eth0 2>/dev/null || true

# Wait for network to be ready
sleep 5

# Install required tools
apk add --no-cache util-linux parted qemu-guest-agent openssh

# Create disk layout
echo "Creating disk partitions..."
sgdisk -Z /dev/vda
sgdisk -o /dev/vda
sgdisk -n 1:0:0 -t 1:8300 /dev/vda
partprobe /dev/vda || sleep 2

# Format and mount
echo "Formatting disk..."
mkfs.ext4 -F /dev/vda1
mkdir -p /mnt

# Mount and bootstrap
mount /dev/vda1 /mnt

# Install base system to disk
echo "Installing base system..."
setup-alpine -q -d /mnt << 'ANSWERS'

us
us
us
lwvm-alpine
127.0.0.1
255.255.255.0
10.0.2.15
10.0.2.2
lwvm
lwvm
password
2
no
ANSWERS

# Copy APK config
cp /etc/apk/repositories /mnt/etc/apk/

# Configure SSH
echo "Configuring SSH..."
echo "PermitRootLogin yes" >> /mnt/etc/ssh/sshd_config
echo "PasswordAuthentication yes" >> /mnt/etc/ssh/sshd_config

# Create default user in installed system
echo "Creating default user..."
chroot /mnt adduser -D -s /bin/sh -G wheel lwvm || true
chroot /mnt sh -c 'echo "lwvm:password" | chpasswd' || true
echo 'lwvm ALL=(ALL) NOPASSWD: ALL' >> /mnt/etc/sudoers

# Enable services
echo "Enabling services..."
chroot /mnt rc-update add devfs sysinit
chroot /mnt rc-update add dmesg sysinit
chroot /mnt rc-update add mdev sysinit
chroot /mnt rc-update add hwdrivers sysinit
chroot /mnt rc-update add modules boot
chroot /mnt rc-update add sysctl boot
chroot /mnt rc-update add hostname boot
chroot /mnt rc-update add networking boot
chroot /mnt rc-update add sshd default

# Install packages to disk
echo "Installing packages..."
chroot /mnt apk add --no-cache qemu-guest-agent openssh vim curl

# Clean up
umount /mnt

echo "Installation complete, powering off..."
poweroff