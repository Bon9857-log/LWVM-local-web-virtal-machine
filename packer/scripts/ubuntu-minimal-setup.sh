#!/bin/bash
set -e

# Ubuntu 24.04 minimal VM setup for LWVM

# Install QEMU guest agent and other packages
apt-get update
apt-get install -y qemu-guest-agent cloud-init openssh-server linux-virtual vim curl

# Enable services
systemctl enable qemu-guest-agent
systemctl enable ssh

# Configure SSH
echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config
echo "PermitRootLogin yes" >> /etc/ssh/sshd_config

# Create default user
useradd -m -s /bin/bash lwvm
echo 'lwvm:password' | chpasswd
echo 'lwvm ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers

# Configure cloud-init for growpart
cat > /etc/cloud/cloud.cfg.d/99-growpart.cfg << 'EOF'
growpart:
  mode: auto_resize
  devices: ["/"]
  ignore_gfio: false
EOF

# Clean up
cloud-init clean
rm -rf /var/log/cloud-init*

# Shutdown
poweroff