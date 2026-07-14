#!/bin/sh
set -e

# Minimal Linux auto-install for LWVM
# BusyBox + dropbear SSH (~100MB)

# Enable network
echo "Configuring network..."
ip link set eth0 up 2>/dev/null || true
udhcpc -i eth0 2>/dev/null || true

sleep 5

# Install required tools for installation
apk add --no-cache util-linux parted qemu-guest-agent curl

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

mount /dev/vda1 /mnt

# Install minimal base system
echo "Installing minimal system..."
setup-alpine -q -d /mnt << 'ANSWERS'

us
us
us
lwvm-minimal
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

cp /etc/apk/repositories /mnt/etc/apk/

# Configure SSH
echo "Configuring SSH..."
echo "PermitRootLogin yes" >> /mnt/etc/ssh/sshd_config
echo "PasswordAuthentication yes" >> /mnt/etc/ssh/sshd_config

# Create minimal user
echo "Creating default user..."
chroot /mnt adduser -D -s /bin/sh lwvm || true
chroot /mnt sh -c 'echo "lwvm:password" | chpasswd' || true

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

# Install minimal packages: BusyBox + dropbear SSH
echo "Installing minimal packages..."
chroot /mnt apk add --no-cache \
  qemu-guest-agent \
  dropbear \
  tinyssh

# Enable dropbear
chroot /mnt rc-update add dropbear default

# Clean up
umount /mnt

echo "Installation complete, powering off..."
poweroff