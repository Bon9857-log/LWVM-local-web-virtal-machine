packer {
  required_version = ">= 1.10.0"
  required_plugins {
    qemu = {
      source  = "github.com/hashicorp/qemu"
      version = ">= 1.10.0"
    }
  }
}

variable "alpine_version" {
  type    = string
  default = "3.20.0"
}

variable "alpine_arch" {
  type = string
}

variable "alpine_iso_url" {
  type = string
}

variable "alpine_iso_checksum" {
  type = string
}

variable "qemu_machine_type" {
  type = string
}

variable "qemu_cpu_type" {
  type = string
}

source "qemu" "minimal_linux" {
  iso_url           = var.alpine_iso_url
  iso_checksum      = "sha256:${var.alpine_iso_checksum}"
  output_directory  = "output-minimal-linux-${var.alpine_arch}"
  vm_name           = "lwvm-minimal-linux-${var.alpine_version}-${var.alpine_arch}"
  format            = "qcow2"
  accelerator       = "tcg"
  qemuargs = [
    ["-machine", "${var.qemu_machine_type}"],
    ["-cpu", "${var.qemu_cpu_type}"]
  ]
  ssh_username      = "root"
  ssh_password      = "alpine"
  ssh_timeout       = "30m"
  http_directory    = "http"
  boot_wait         = "10s"
  boot_command = [
    "root<enter><wait5>",
    "wget http://{{.HTTPIP}}:{{.HTTPPort}}/minimal-linux-auto-install.sh -O /tmp/auto-install.sh<enter><wait10>",
    "chmod +x /tmp/auto-install.sh<enter>",
    "/tmp/auto-install.sh<enter><wait1200"
  ]
  shutdown_command   = "poweroff"
  disk_interface     = "virtio"
  net_device         = "virtio"
}

build {
  name = "minimal-linux-${var.alpine_arch}"
  sources = ["source.qemu.minimal_linux"]

  provisioner "shell" {
    pause_before = "5m"
    inline = [
      "apk update",
      "apk add busybox dropbear tinyssh",
      "echo 'PermitRootLogin yes' >> /etc/ssh/sshd_config",
      "echo 'Port 22' >> /etc/ssh/sshd_config",
      "rc-update add dropbear default",
      "truncate -s 0 /etc/machine-id"
    ]
  }

  post-processor "shell" {
    inline = [
      "qemu-img convert -O qcow2 -c output-minimal-linux-${var.alpine_arch}/lwvm-minimal-linux-${var.alpine_version}-${var.alpine_arch} output-minimal-linux-${var.alpine_arch}/lwvm-minimal-linux-${var.alpine_version}-compressed-${var.alpine_arch}.qcow2 || true"
    ]
  }
}