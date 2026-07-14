packer {
  required_version = ">= 1.10.0"
  required_plugins {
    qemu = {
      source  = "github.com/hashicorp/qemu"
      version = ">= 1.10.0"
    }
  }
}

variable "ubuntu_version" {
  type    = string
  default = "24.04"
}

variable "ubuntu_arch" {
  type = string
}

variable "ubuntu_iso_url" {
  type = string
}

variable "ubuntu_iso_checksum" {
  type = string
}

variable "qemu_cpu_type" {
  type = string
  default = "host"
}

source "qemu" "ubuntu" {
  iso_url           = var.ubuntu_iso_url
  iso_checksum      = "sha256:${var.ubuntu_iso_checksum}"
  output_directory  = "output-ubuntu-${var.ubuntu_arch}"
  vm_name           = "lwvm-ubuntu-${var.ubuntu_version}-${var.ubuntu_arch}-minimal"
  format            = "qcow2"
  accelerator       = "tcg"
  qemuargs = [
    ["-machine", "q35"],
    ["-cpu", "${var.qemu_cpu_type}"]
  ]
  ssh_username      = "lwvm"
  ssh_password      = "password"
  ssh_timeout       = "60m"
  http_directory    = "http"
  boot_wait         = "10s"
  boot_command = [
    "<esc><wait5>",
    "linux auto-install=no<enter>"
  ]
  shutdown_command   = "poweroff"
  disk_interface     = "virtio"
  net_device         = "virtio"
}

build {
  name = "ubuntu-${var.ubuntu_arch}"
  sources = ["source.qemu.ubuntu"]

  provisioner "shell" {
    pause_before = "5m"
    inline = [
      "sudo cloud-init clean",
      "sudo rm -rf /var/log/cloud-init*",
      "sudo truncate -s 0 /etc/machine-id"
    ]
  }

  post-processor "shell" {
    inline = [
      "qemu-img convert -O qcow2 -c output-ubuntu-${var.ubuntu_arch}/lwvm-ubuntu-${var.ubuntu_version}-${var.ubuntu_arch}-minimal output-ubuntu-${var.ubuntu_arch}/lwvm-ubuntu-${var.ubuntu_version}-${var.ubuntu_arch}-minimal-compressed.qcow2 || true"
    ]
  }
}