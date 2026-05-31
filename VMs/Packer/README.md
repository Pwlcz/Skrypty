# Multi-OS Homelab Image Builder

An IaC pipeline for automatically building and provisioning base operating system images. This project uses **Packer** to simultaneously bake local **Vagrant boxes** (via QEMU/KVM) and remote **Proxmox Templates** from a single source of truth.

Currently supported operating systems:

* **Arch Linux** (Automated via `archinstall` and `arch-chroot`)
* **Linux Mint** (Automated via preseed/cloud-init and `apt`)

I based my packer config on:

* <https://github.com/elasticdog/packer-arch>
* <https://github.com/ajxb/packer-linuxmint>

---

## Project Architecture

This repository is built around a modular, directory-based execution model to keep OS-specific logic isolated while sharing common hypervisor variables.

```text
.
├── variables.pkr.hcl             # Single source of truth for global variables
├── arch.pkr.hcl                  # Arch-specific build logic (QEMU + Proxmox)
├── mint.pkr.hcl                  # Mint-specific build logic (QEMU + Proxmox)
├── arch.pkrvars.hcl              # Variable values for Arch
├── mint.pkrvars.hcl              # Variable values for Mint
├── scripts/                      # Provisioning scripts
│   ├── arch/                     # Arch-specific scripts (pacman, chroot)
│   └── mint/                     # Mint-specific scripts (apt, systemd)
├── templates/                    # Shared configs
│   └── Vagrantfile.tpl           # Universal Libvirt Vagrantfile 
├── setup-host.sh                 # Host environment bootstrapper
└── mkbox                         # Ad-hoc build wrapper script
```

## Environment Setup

### 1. Bootstrapping the Host

If you are running this on a fresh Linux workstation (Debian/Ubuntu/Mint or Arch), run the bootstrap script to automatically install Packer, Vagrant, and the required HashiCorp plugins.

```bash
chmod +x setup-host.sh
./setup-host.sh
```

### 2. Managing Secrets

Proxmox API tokens and other sensitive credentials should never be committed in plaintext to .pkrvars.hcl files.

Create a .env file or export the variables directly. The mkbox script will automatically attempt to decrypt and source a GPG-encrypted environment file if one exists:

```bash
# Example contents of hcp-env.sh
export PKR_VAR_proxmox_api_url="[https://10.0.0.100:8006/api2/json](https://10.0.0.100:8006/api2/json)"
export PKR_VAR_proxmox_username="root@pam"
export PKR_VAR_proxmox_token="your-secret-token"

# Encrypt it for the pipeline
gpg -c --cipher-algo AES256 hcp-env.sh
```

## How to Use

Do not run standard packer build commands against individual files, although you can. Use the provided mkbox wrapper script, which safely locks the directory, formats the code, and passes the correct flags.

### Basic Build

To build an OS using its default variables:

```bash
./mkbox arch
# or
./mkbox mint
```

This will output a .box file in output/libvirt/ and immediately add it to your local Vagrant environment, while simultaneously pushing a template to your Proxmox cluster.

### Overriding Variables (Testing)

If you want to build a test variation without altering the default .pkrvars.hcl file, you can pass a custom variable file using the -v flag:

```bash
./mkbox arch -v experimental-k8s.pkrvars.hcl
```

## Local Development with Vagrant

The built Vagrant boxes use a custom Vagrantfile.erb optimized for libvirt/KVM.

* The default rsync synced folder is disabled to prevent boot crashes.
* SSH tunnels to the local libvirt socket are bypassed for instant connectivity.

To spin up a newly built box:

```bash
mkdir my-project && cd my-project
vagrant init arch-2023.10.01  # Use the box name outputted by mkbox
vagrant up --provider=libvirt
```

## Troubleshooting

### Packer fails to connect to the Proxmox API (x509: certificate signed by unknown authority)

* Fix: Ensure insecure_skip_tls_verify = true is set in the proxmox-iso builder block if you are using self-signed certificates on your Proxmox node.

### Vagrant throws a "Permission denied" or "Failed to connect to socket" error

* Fix: Ensure your host user is a member of the libvirt and kvm groups.

```bash
sudo usermod -aG libvirt,kvm $USER
newgrp libvirt
```

### setup-host.sh fails on Linux Mint with an APT 404 error

* Fix: This occurs if HashiCorp does not have a repository matching Mint's custom codename. The setup-host.sh script sources /etc/os-release to map Mint codenames to Ubuntu upstream codenames automatically. Ensure you are running the latest version of the setup script.
