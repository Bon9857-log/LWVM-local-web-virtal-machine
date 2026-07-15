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

source "qemu" "alpine_dev" {
  iso_url           = var.alpine_iso_url
  iso_checksum      = "sha256:${var.alpine_iso_checksum}"
  output_directory  = "output-alpine-dev-${var.alpine_arch}"
  vm_name           = "lwvm-alpine-dev-${var.alpine_version}-${var.alpine_arch}"
  format            = "qcow2"
  accelerator       = "tcg"
  qemuargs = [
    ["-machine", "${var.qemu_machine_type}"],
    ["-cpu", "${var.qemu_cpu_type}"]
  ]
  ssh_username      = "root"
  ssh_password      = "alpine"
  ssh_timeout       = "45m"
  http_directory    = "http"
  boot_wait         = "10s"
  boot_command = [
    "root<enter><wait5>",
    "wget http://{{.HTTPIP}}:{{.HTTPPort}}/alpine-dev-auto-install.sh -O /tmp/auto-install.sh<enter><wait10>",
    "chmod +x /tmp/auto-install.sh<enter>",
    "/tmp/auto-install.sh<enter><wait1800"
  ]
  shutdown_command   = "poweroff"
  disk_interface     = "virtio"
  net_device         = "virtio"
}

build {
  name = "alpine-dev-${var.alpine_arch}"
  sources = ["source.qemu.alpine_dev"]

  provisioner "shell" {
    pause_before = "5m"
    inline = [
      "apk update",
      "apk add git vim python3 nodejs go docker-cli docker-cli-compose openssh-client curl",
      "addgroup -S docker",
      "adduser -S -G docker developer",
      "echo 'developer:password' | chpasswd",
      "echo 'PermitRootLogin yes' >> /etc/ssh/sshd_config",
      "rc-update add devfs boot",
      "rc-update add dmesg boot",
      "rc-update add mdev boot",
      "cloud-init clean || true",
      "truncate -s 0 /etc/machine-id"
    ]
  }

  post-processor "shell" {
    inline = [
      "qemu-img convert -O qcow2 -c output-alpine-dev-${var.alpine_arch}/lwvm-alpine-dev-${var.alpine_version}-${var.alpine_arch} output-alpine-dev-${var.alpine_arch}/lwvm-alpine-dev-${var.alpine_version}-compressed-${var.alpine_arch}.qcow2 || true"
    ]
  }
}