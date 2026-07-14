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

source "qemu" "ubuntu_datasci" {
  iso_url           = var.ubuntu_iso_url
  iso_checksum      = "sha256:${var.ubuntu_iso_checksum}"
  output_directory  = "output-ubuntu-datasci-${var.ubuntu_arch}"
  vm_name           = "lwvm-ubuntu-datasci-${var.ubuntu_version}-${var.ubuntu_arch}"
  format            = "qcow2"
  accelerator       = "tcg"
  qemuargs = [
    ["-machine", "q35"],
    ["-cpu", "${var.qemu_cpu_type}"]
  ]
  ssh_username      = "lwvm"
  ssh_password      = "password"
  ssh_timeout       = "120m"
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
  name = "ubuntu-datasci-${var.ubuntu_arch}"
  sources = ["source.qemu.ubuntu_datasci"]

  provisioner "shell" {
    pause_before = "5m"
    inline = [
      "sudo apt-get update",
      "sudo apt-get install -y python3 python3-pip python3-venv jupyter-notebook pandas numpy python3-torch python3-cuda || true",
      "pip3 install --break-system-packages torch --index-url https://download.pytorch.org/whl/cpu || true",
      "pip3 install --break-system-packages pandas numpy jupyter notebook || true",
      "sudo cloud-init clean || true",
      "sudo truncate -s 0 /etc/machine-id"
    ]
  }

  post-processor "shell" {
    inline = [
      "qemu-img convert -O qcow2 -c output-ubuntu-datasci-${var.ubuntu_arch}/lwvm-ubuntu-datasci-${var.ubuntu_version}-${var.ubuntu_arch} output-ubuntu-datasci-${var.ubuntu_arch}/lwvm-ubuntu-datasci-${var.ubuntu_version}-compressed-${var.ubuntu_arch}.qcow2 || true"
    ]
  }
}