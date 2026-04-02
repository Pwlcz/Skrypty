# based on https://github.com/elasticdog/packer-arch, changed to use archinstall configs for easier config swap
packer {
  required_plugins {
    qemu = {
      source  = "github.com/hashicorp/qemu"
      version = "~> 1"
    }
    vagrant = {
      source  = "github.com/hashicorp/vagrant"
      version = "~> 1"
    }
  }
}

variable "version" {
  type    = string
  default = "0.0.0"
}

variable "country" {
  type    = string
  default = "PL"
}

variable "headless" {
  type    = string
  default = "true"
}

variable "iso_checksum_url" {
  type    = string
  default = "https://ftp.icm.edu.pl/pub/Linux/dist/archlinux/iso/latest/sha256sums.txt"
}

variable "iso_url" {
  type    = string
  default = "https://ftp.icm.edu.pl/pub/Linux/dist/archlinux/iso/latest/archlinux-x86_64.iso"
}

variable "ssh_timeout" {
  type    = string
  default = "20m"
}

variable "write_zeros" {
  type    = string
  default = "true"
}

locals {
  # Determines the build suffix
  build_date = formatdate("YYYY.MM.DD", timestamp())
}

source "qemu" "archinstall" {
  boot_command = ["<enter><wait10><wait10><wait10><wait10><wait10><wait10><wait10><wait10><wait10>",
    "/usr/bin/curl -O http://{{ .HTTPIP }}:{{ .HTTPPort }}/enable-ssh.sh<enter><wait5>",
  "/usr/bin/bash ./enable-ssh.sh<enter>"]
  boot_wait        = "5s"
  shutdown_command = "sudo poweroff"
  headless         = "${var.headless}"
  cpus             = 1
  memory           = 1024
  disk_size        = 20480
  http_directory   = "srv"
  iso_checksum     = "file:${var.iso_checksum_url}"
  iso_url          = "${var.iso_url}"
  ssh_timeout      = "${var.ssh_timeout}"
  ssh_password     = "vagrant"
  ssh_username     = "vagrant"
}

build {
  sources = ["source.qemu.archinstall"]

  provisioner "file" {
    source      = "scripts/archinstall/"
    destination = "/tmp/"
  }

  provisioner "shell" {
    execute_command = "{{ .Vars }} COUNTRY=${var.country} sudo -E -S bash -c '{{ .Path }}'"
    inline = [
      "echo 'Running archinstall in unattended mode...'",
      "archinstall --config /tmp/user_configuration.json --creds /tmp/user_credentials.json --silent"
    ]
  }

  provisioner "shell" {
    execute_command = "{{ .Vars }} sudo -E -S bash -c '{{ .Path }}'"
    inline = [
      "echo '>>>> Post-Install: Configuring sudo for Vagrant..'",
      "echo 'Defaults env_keep += \"SSH_AUTH_SOCK\"' > /mnt/etc/sudoers.d/10_vagrant",
      "echo 'vagrant ALL=(ALL) NOPASSWD: ALL' >> /mnt/etc/sudoers.d/10_vagrant",
      "chmod 0440 /mnt/etc/sudoers.d/10_vagrant",

      "echo '>>>> Post-Install: Configuring SSHD for Vagrant..'",
      "sed -i 's/#UseDNS yes/UseDNS no/' /mnt/etc/ssh/sshd_config",

      "echo '>>>> Post-Install: Reverting to traditional interface names (eth0)..'",
      "ln -s /dev/null /mnt/etc/udev/rules.d/80-net-setup-link.rules",

      "echo '>>>> Post-Install: Installing Vagrant SSH keys..'",
      "arch-chroot /mnt install --directory --owner=vagrant --group=vagrant --mode=0700 /home/vagrant/.ssh",
      "curl --output /mnt/home/vagrant/.ssh/authorized_keys --location https://raw.github.com/hashicorp/vagrant/master/keys/vagrant.pub",
      "arch-chroot /mnt chown vagrant:vagrant /home/vagrant/.ssh/authorized_keys",
      "arch-chroot /mnt chmod 0600 /home/vagrant/.ssh/authorized_keys"
    ]
  }

  provisioner "shell" {
    execute_command = "{{ .Vars }} WRITE_ZEROS=${var.write_zeros} sudo -E -S bash '{{ .Path }}'"
    script          = "scripts/cleanup.sh"
  }

  post-processor "vagrant" {
    output = "output/packer_arch_{{ .Provider }}-${local.build_date}.box"
  }
}