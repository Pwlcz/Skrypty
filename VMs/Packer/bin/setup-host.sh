#!/bin/bash
# setup-host.sh - Bootstraps HashiCorp tools and plugins for local development

set -euo pipefail

echo "==> Starting Host Environment Setup"

# 1. Detect OS and Install Core Tools (Packer & Vagrant)
if command -v apt-get &> /dev/null; then
    echo "==> Detected Debian/Ubuntu/Mint system."
    
    if ! command -v packer &> /dev/null || ! command -v vagrant &> /dev/null; then
        echo "==> Adding HashiCorp APT repository..."
        sudo apt-get update && sudo apt-get install -y gnupg software-properties-common curl
        
        wget -O- https://apt.releases.hashicorp.com/gpg | \
            gpg --dearmor | \
            sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg > /dev/null

        source /etc/os-release
        if [[ "${ID}" == "linuxmint" ]]; then
            REPO_CODENAME=${UBUNTU_CODENAME}
        else
            REPO_CODENAME=${VERSION_CODENAME:-$(lsb_release -cs 2>/dev/null)}
        fi
            
        echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
            https://apt.releases.hashicorp.com ${REPO_CODENAME} main" | \
            sudo tee /etc/apt/sources.list.d/hashicorp.list
            
        echo "==> Installing Packer and Vagrant..."
        sudo apt-get update
        sudo apt-get install -y packer vagrant
    else
        echo "==> Packer and Vagrant are already installed. Skipping APT setup."
    fi

elif command -v pacman &> /dev/null; then
    echo "==> Detected Arch Linux system."
    echo "==> Installing Packer and Vagrant via pacman..."
    sudo pacman -S --needed --noconfirm packer vagrant
else
    echo "Error: Unsupported package manager. Please install Packer and Vagrant manually."
    exit 1
fi

# 2. Install Global Vagrant Plugins
echo "==> Installing Vagrant Plugins..."

VAGRANT_PLUGINS=(
    "vagrant-libvirt"
    "vagrant-proxmox"
)

for plugin in "${VAGRANT_PLUGINS[@]}"; do
    if vagrant plugin list | grep -q "${plugin}"; then
        echo "  -> ${plugin} is already installed."
    else
        echo "  -> Installing ${plugin}..."
        vagrant plugin install "${plugin}"
    fi
done

# 3. Setup Project-Level Packer Plugins
echo "==> Setting up Packer Plugins..."

PACKER_PLUGINS_FILE="plugins.pkr.hcl"

if [[ ! -f "${PACKER_PLUGINS_FILE}" ]]; then
    echo "  -> Creating ${PACKER_PLUGINS_FILE} for required plugins..."
    cat <<EOF > "${PACKER_PLUGINS_FILE}"
packer {
  required_plugins {
    qemu = {
      version = "~> 1.1"
      source  = "github.com/hashicorp/qemu"
    }
    proxmox = {
      version = "~> 1.1"
      source  = "github.com/hashicorp/proxmox"
    }
  }
}
EOF
else
    echo "  -> ${PACKER_PLUGINS_FILE} already exists."
fi

echo "  -> Initializing Packer plugins in the current directory..."
packer init "${PACKER_PLUGINS_FILE}"

echo "==> Host Setup Complete!"
echo "You can now run 'vagrant up' or execute your Packer builds."