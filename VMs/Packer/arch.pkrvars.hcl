# Arch variables for QEMU/libvirt
# Build with: packer build --var-file=arch.pkrvars.hcl core_template.pkr.hcl
# Ensure QEMU/KVM and libvirt are installed on your system

# VM configuration
cpus      = 2
memory    = 4096
disk_size = 20480
headless  = true
vm_name   = "arch"

# ISO configuration
iso_checksum_type = "file"
iso_checksum      = "https://archlinux.org/iso/latest/sha256sums.txt"
iso_urls = [
  "https://ftp.icm.edu.pl/pub/Linux/dist/archlinux/iso/latest/archlinux-x86_64.iso",
  "https://fastly.mirror.pkgbuild.com/iso/latest/archlinux-x86_64.iso"
]
iso_target_path = "/tmp/archlinux-x86_64.iso"

# Installation configuration
boot_command_prefix = "<enter><wait80>"

# Vagrant configuration
vagrantfile_template = "templates/vagrantfile-base.erb"
box_tag              = "pwlcz/arch"
version              = "0.0.0"
version_description  = "Arch Linux installation box built on $(date +%Y-%m-%d)"
#hcp_client_id        = ""
#hcp_client_secret    = ""
#ssh_username         = "vagrant"
#ssh_password         = "vagrant"
ssh_timeout = "20m"
#hostname             = "vagrant"