# based on https://github.com/elasticdog/packer-arch
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
  # default = "https://mirrors.kernel.org/archlinux/iso/latest/sha256sums.txt"
}

variable "iso_url" {
  type    = string
  default = "https://ftp.icm.edu.pl/pub/Linux/dist/archlinux/iso/latest/archlinux-x86_64.iso"
  # default = "https://mirrors.kernel.org/archlinux/iso/latest/archlinux-x86_64.iso"
}

variable "ssh_timeout" {
  type    = string
  default = "20m"
}

variable "write_zeros" {
  type    = string
  default = "true"
}

variable "install_desktop" {
  type    = bool
  default = false
}

locals {
  # Determines the build suffix
  build_date     = formatdate("YYYY.MM.DD", timestamp())
  desktop_suffix = var.install_desktop ? ".desktop" : ""
}

source "qemu" "arch" {
  boot_command = ["<enter><wait10><wait10><wait10><wait10><wait10><wait10>",
    "/usr/bin/curl -O http://{{ .HTTPIP }}:{{ .HTTPPort }}/enable-ssh.sh<enter><wait5>",
    "/usr/bin/curl -O http://{{ .HTTPIP }}:{{ .HTTPPort }}/poweroff.timer<enter><wait5>",
  "/usr/bin/bash ./enable-ssh.sh<enter>"]
  boot_wait        = "5s"
  shutdown_command = "sudo systemctl start poweroff.timer"
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
  sources = ["source.qemu.arch"]

  provisioner "shell" {
    execute_command   = "{{ .Vars }} COUNTRY=${var.country} sudo -E -S bash '{{ .Path }}'"
    expect_disconnect = true
    script            = "scripts/install-base.sh"
  }

  provisioner "shell" {
    execute_command = "{{ .Vars }} WRITE_ZEROS=${var.write_zeros} sudo -E -S bash '{{ .Path }}'"
    script          = "scripts/cleanup.sh"
  }

  dynamic "provisioner" {
    for_each = var.install_desktop ? [1] : []
    labels   = ["shell"]

    content {
      execute_command = "{{ .Vars }} sudo -E -S bash '{{ .Path }}'"
      script          = "scripts/desktop-addons.sh"
    }
  }

  post-processor "vagrant" {
    output = "output/packer_arch_{{ .Provider }}-${local.build_date}${local.desktop_suffix}.box"
  }
}
