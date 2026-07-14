#!/bin/bash
# Helper script for ORAS authentication

set -e

# Get ORAS version
get_oras() {
    local version=$(curl -s https://api.github.com/repos/oras-project/oras/releases/latest | grep '"tag_name"' | cut -d '"' -f 4)
    curl -LO "https://github.com/oras-project/oras/releases/download/${version}/oras_${version}_linux_amd64.tar.gz"
    tar -zxvf "oras_${version}_linux_amd64.tar.gz" oras
    sudo mv oras /usr/local/bin/
}

# Authenticate with GHCR
auth_ghcr() {
    if [ -z "$GITHUB_TOKEN" ]; then
        echo "GITHUB_TOKEN not set"
        return 1
    fi
    echo "$GITHUB_TOKEN" | oras login ghcr.io -u "$USER" --password-stdin
}

# Push image to GHCR
push_image() {
    local image_path=$1
    local tag=$2
    local desc=$3
    
    oras push ghcr.io/${USER}/lwvm-images/${tag} \
        --annotation org.opencontainers.image.title="${USER} LWVM ${tag}" \
        --annotation org.opencontainers.image.description="${desc}" \
        --annotation org.opencontainers.image.type="virtual-machine" \
        "${image_path}"
}

echo "ORAS helper functions loaded. Source this file to use."