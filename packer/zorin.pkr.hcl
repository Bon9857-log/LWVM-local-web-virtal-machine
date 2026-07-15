packer {
  required_version = ">= 1.10.0"
  required_plugins {
    qemu = {
      source  = "github.com/hashicorp/qemu"
      version = ">= 1.10.0"
    }
  }
}

variable "zorin_version" {
  type    = string
  default = "17"
}

variable "zorin_arch" {
  type = string
}

variable "zorin_iso_url" {
  type = string
}

variable "zorin_iso_checksum" {
  type = string
}

variable "qemu_cpu_type" {
  type    = string
  default = "host"
}

variable "build_arm64" {
  type    = bool
  default = false
}

locals {
  is_arm64 = var.zorin_arch == "arm64"
}

source "qemu" "zorin" {
  iso_url           = var.zorin_iso_url
  iso_checksum      = "sha256:${var.zorin_iso_checksum}"
  output_directory  = "output-zorin-${var.zorin_arch}"
  vm_name           = "lwvm-zorin-${var.zorin_version}-${var.zorin_arch}"
  format            = "qcow2"
  accelerator       = "tcg"
  qemuargs = [
    ["-machine", "q35"],
    ["-cpu", "${var.qemu_cpu_type}"]
  ]
  ssh_username      = "lwvm"
  ssh_password      = "password"
  ssh_timeout       = "90m"
  http_directory    = "http"
  boot_wait         = "10s"
  boot_command = [
    "<esc><wait5>",
    "linux auto-install=no http://{{.HTTPIP}}:{{.HTTPPort}}/zorin-user-data<enter>"
  ]
  shutdown_command   = "poweroff"
  disk_interface     = "virtio"
  net_device         = "virtio"
}

build {
  name = "zorin-${var.zorin_arch}"
  sources = ["source.qemu.zorin"]

  provisioner "shell" {
    pause_before = "5m"
    inline = [
      "sudo cloud-init clean || true",
      "sudo truncate -s 0 /etc/machine-id || true"
    ]
  }

  provisioner "shell" {
    execute_command = "sudo sh -c '{{ inline_script }}'"
    inline = [
      "apt-get update",
      "apt-get install -y qemu-guest-agent spice-vdagent",
      "systemctl enable qemu-guest-agent || true",
      "systemctl enable spice-vdagent || true",
      "apt-get purge -y calamares ubiquity || true",
      "apt-get install -y --install-recommends linux-generic-hwe-24.04 || true",
      "apt-get install -y cloud-init || true",
      "apt-get install -y flatpak || true",
      "flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo || true",
      "apt-get install -y libreoffice firefox || true"
    ]
  }

  provisioner "shell" {
    execute_command = "sudo sh -c '{{ inline_script }}'"
    inline = [
      "mkdir -p /etc/gdm3",
      "printf '[daemon]\\nAutomaticLoginEnable = true\\nAutomaticLogin = lwvm\\n' > /etc/gdm3/custom.conf",
      "su lwvm -c 'DISPLAY=:0 dbus-launch gsettings set org.gnome.desktop.screensaver lock-enabled false' || true",
      "su lwvm -c 'DISPLAY=:0 dbus-launch gsettings set org.gnome.desktop.interface enable-animations false' || true",
      "su lwvm -c 'DISPLAY=:0 dbus-launch gsettings set org.zorin.desktop color-scheme \"blue\"' || true",
      "su lwvm -c 'DISPLAY=:0 dbus-launch gsettings set org.gnome.desktop.interface gtk-theme \"ZorinBlue-Dark\"' || true",
      "apt-get autoremove -y || true",
      "apt-get clean || true",
      "rm -rf /var/log/* || true"
    ]
  }

  provisioner "shell" {
    execute_command = "sudo sh -c '{{ inline_script }}'"
    inline = [
      "# ARM64: Add Zorin APT repos and install desktop packages",
      "apt-get update || true",
      "wget -q -O /tmp/zorin-keyring.gpg https://packages.zorinos.com/keyring.gpg || true",
      "gpg --dearmor -o /usr/share/keyrings/zorin-archive-keyring.gpg /tmp/zorin-keyring.gpg || true",
      "echo 'deb [signed-by=/usr/share/keyrings/zorin-archive-keyring.gpg] https://packages.zorinos.com/core jammy main' > /etc/apt/sources.list.d/zorin.list || true",
      "apt-get update || true",
      "apt-get install -y zorin-desktop-core zorin-appearance zorin-icons zorin-os-packages || apt-get install -y yaru-theme-gtk yaru-theme-icon || true"
    ]
    only = ["zorin-arm64"]
  }

  post-processor "shell" {
    inline = [
      "qemu-img convert -O qcow2 -c output-zorin-${var.zorin_arch}/lwvm-zorin-${var.zorin_version}-${var.zorin_arch} output-zorin-${var.zorin_arch}/lwvm-zorin-${var.zorin_version}-compressed-${var.zorin_arch}.qcow2 || true"
    ]
  }
}