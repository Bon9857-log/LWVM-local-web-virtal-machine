# Packer Base Images

Build minimal VM images for LWVM using HashiCorp Packer.

## Images

- **alpine.pkr.hcl** - Alpine 3.20 minimal (~100MB compressed)
  - Packages: qemu-guest-agent, openssh, vim, curl
  - Init: OpenRC
  - Default user: `lwvm` / `password`

- **ubuntu-minimal.pkr.hcl** - Ubuntu 24.04 minimal (~500MB compressed)
  - Packages: qemu-guest-agent, cloud-init, openssh-server, linux-virtual
  - Default user: `lwvm` / `password`

## Prerequisites

```bash
# Install Packer
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt-get update && sudo apt-get install packer

# Install QEMU plugin
packer plugin install github.com/hashicorp/qemu

# Install QEMU for cross-arch builds
sudo apt-get install qemu-system-x86 qemu-system-aarch64 qemu-utils
```

## Building Images

### Alpine AMD64

```bash
packer init alpine.pkr.hcl
packer build \
  -var='alpine_version=3.20.0' \
  -var='alpine_arch=amd64' \
  -var='alpine_iso_url=https://dl-cdn.alpinelinux.org/alpine/v3.20/releases/x86_64/alpine-virt-3.20.0-x86_64.iso' \
  -var='alpine_iso_checksum=<sha256>' \
  -var='qemu_machine_type=q35' \
  -var='qemu_cpu_type=host' \
  alpine.pkr.hcl
```

### Alpine ARM64

```bash
packer build \
  -var='alpine_arch=arm64' \
  -var='alpine_iso_url=https://dl-cdn.alpinelinux.org/alpine/v3.20/releases/aarch64/alpine-virt-3.20.0-aarch64.iso' \
  -var='qemu_machine_type=virt' \
  -var='qemu_cpu_type=cortex-a72' \
  alpine.pkr.hcl
```

### Ubuntu AMD64

```bash
packer init ubuntu-minimal.pkr.hcl
packer build \
  -var='ubuntu_version=24.04' \
  -var='ubuntu_arch=amd64' \
  -var='ubuntu_iso_url=https://releases.ubuntu.com/24.04/ubuntu-24.04-live-server-amd64.iso' \
  -var='ubuntu_iso_checksum=<sha256>' \
  ubuntu-minimal.pkr.hcl
```

### Ubuntu ARM64

```bash
packer build \
  -var='ubuntu_arch=arm64' \
  -var='ubuntu_iso_url=https://cdimage.ubuntu.com/releases/24.04/release/ubuntu-24.04-live-server-arm64.iso' \
  -var='ubuntu_iso_checksum=<sha256>' \
  ubuntu-minimal.pkr.hcl
```

## Publishing to GHCR

```bash
# Install ORAS
VERSION=$(curl -s https://api.github.com/repos/oras-project/oras/releases/latest | grep '"tag_name"' | cut -d '"' -f 4)
curl -LO "https://github.com/oras-project/oras/releases/download/${VERSION}/oras_${VERSION}_linux_amd64.tar.gz"
tar -zxvf "oras_${VERSION}_linux_amd64.tar.gz" oras
sudo mv oras /usr/local/bin/

# Login
echo $GITHUB_TOKEN | oras login ghcr.io -u $USER --password-stdin

# Push Alpine
oras push ghcr.io/$USER/lwvm-images/alpine:3.20-amd64 output-alpine-amd64/lwvm-alpine-3.20-compressed-amd64.qcow2

# Create manifest
oras manifest create ghcr.io/$USER/lwvm-images/alpine:3.20
oras manifest annotate ghcr.io/$USER/lwvm-images/alpine:3.20 ghcr.io/$USER/lwvm-images/alpine:3.20-amd64 --arch amd64
oras manifest push ghcr.io/$USER/lwvm-images/alpine:3.20
```

## CI/CD

GitHub Actions workflow in `.github/workflows/build-images.yml` builds all 4 images and pushes to GHCR on every push to main.