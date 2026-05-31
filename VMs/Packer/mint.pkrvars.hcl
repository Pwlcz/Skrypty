# Linux Mint 22.3 Cinnamon variables for QEMU/libvirt
# Build with: packer build --var-file=mint-cinnamon-22.3.pkrvars.hcl core_template.pkr.hcl
# Ensure QEMU/KVM and libvirt are installed on your system

# VM configuration
cpus = 2

memory = 4096

disk_size = 60000

headless = false

vm_name = "mint-cinnamon-22.3"

# ISO configuration
iso_checksum_type = "file"

iso_checksum = "https://mirrors.edge.kernel.org/linuxmint/stable/22.3/sha256sum.txt"

iso_urls = [
  "https://ftp.icm.edu.pl/pub/Linux/dist/linuxmint/isos/stable/22.3/linuxmint-22.3-cinnamon-64bit.iso",
  "https://pub.linuxmint.io/stable/22.3/linuxmint-22.3-cinnamon-64bit.iso"
]

iso_target_path = "/tmp/linuxmint-22.3-cinnamon-64bit.iso"

# Installation configuration
boot_command_prefix = "<esc><wait10>"

preseed = "mint-22.3.seed"

# Vagrant configuration
vagrantfile_template = "templates/vagrantfile-base.erb"

box_tag = "pwlcz/mint-cinnamon-22.3"

version = "1.0.0"

version_description = "Linux Mint 22.3 QEMU/libvirt box with Cinnamon desktop environment, built on $(date +%Y-%m-%d)"
