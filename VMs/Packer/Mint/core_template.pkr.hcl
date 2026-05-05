# based on https://github.com/ajxb/packer-linuxmint
packer {
  required_version = ">= 1.7.0"
  required_plugins {
    qemu = {
      version = ">= 1.0.0"
      source  = "github.com/hashicorp/qemu"
    }
    vagrant = {
      source  = "github.com/hashicorp/vagrant"
      version = "~> 1"
    }
  }
}

variable "vm_name" {
  type        = string
  description = "Name of the virtual machine"
}

variable "iso_urls" {
  type        = list(string)
  description = "URLs to the ISO file"
}
variable "iso_target_path" {
  type        = string
  description = "Local cache path for ISO file"
  default     = ""
}

variable "iso_checksum" {
  type        = string
  description = "Checksum of the ISO file"
}

variable "iso_checksum_type" {
  type        = string
  description = "Type of checksum (sha256, md5, etc)"
  default     = "sha256"
}

variable "ssh_username" {
  type        = string
  description = "SSH username for provisioning"
  default     = "vagrant"
}

variable "ssh_password" {
  type        = string
  description = "SSH password for provisioning"
  default     = "vagrant"
  sensitive   = true
}

variable "headless" {
  type        = bool
  description = "Run Installation vm in headless mode"
  default     = false
}

variable "boot_command_prefix" {
  type        = string
  description = "Boot command prefix for unattended installation"
}

variable "preseed" {
  type        = string
  description = "Preseed filename for unattended installation"
}

variable "disk_size" {
  type        = number
  description = "Disk size in MB"
  default     = 65536
}

variable "memory" {
  type        = number
  description = "Memory in MB"
  default     = 4096
}

variable "cpus" {
  type        = number
  description = "Number of CPUs"
  default     = 2
}

variable "vagrantfile_template" {
  type        = string
  description = "Path to Vagrantfile template"
}

variable "version" {
  type        = string
  description = "Box version"
}

variable "version_description" {
  type        = string
  description = "Box version description"
}

variable "box_tag" {
  type        = string
  description = "Vagrant Cloud box tag (org/name)"
}

variable "cloud_token" {
  type        = string
  description = "Vagrant Cloud API token"
  sensitive   = true
  default     = ""
}

variable "hostname" {
  type        = string
  description = "Hostname for the VM"
  default     = "vagrant"
}

variable "ssh_fullname" {
  type        = string
  description = "Full name for SSH user"
  default     = "vagrant"
}

source "qemu" "linux" {
  vm_name              = var.vm_name
  http_directory       = "http"
  iso_urls             = var.iso_urls
  iso_checksum         = "${var.iso_checksum_type}:${var.iso_checksum}"
  iso_target_path      = var.iso_target_path
  ssh_username         = var.ssh_username
  ssh_password         = var.ssh_password
  ssh_wait_timeout     = "10000s"
  headless             = var.headless
  disk_size            = var.disk_size
  shutdown_command     = "echo '${var.ssh_password}' | sudo -S shutdown -P now"
  shutdown_timeout     = "1m"
  
  boot_wait = "5s"
  boot_command = [
    var.boot_command_prefix,
    "/casper/vmlinuz ",
    "url=http://{{ .HTTPIP }}:{{ .HTTPPort }}/${var.preseed} ",
    "boot=casper ",
    "initrd=/casper/initrd.lz ",
    "debug-ubiquity ",
    "automatic-ubiquity ",
    "quiet ",
    "splash ",
    "noprompt ",
    "-- <enter>"
  ]

  qemu_binary          = "qemu-system-x86_64"
  accelerator          = "kvm"
  disk_interface       = "virtio"
  format          = "qcow2"
  memory               = var.memory
  cpus                 = var.cpus
  net_device           = "virtio-net"
  machine_type         = "pc"
  use_backing_file     = false
  vnc_port_min         = 5900
  vnc_port_max         = 6000
}

build {
  name = "linux-mint"
  sources = [
    "source.qemu.linux"
  ]

  provisioner "shell" {
    execute_command = "echo '${var.ssh_password}' | {{.Vars}} sudo -E -S bash '{{.Path}}'"
    scripts = [
      "script/rc_local.sh",
      "script/apt.sh",
      "script/sshd.sh"
    ]
  }

  provisioner "shell" {
    execute_command   = "echo '${var.ssh_password}' | {{.Vars}} sudo -E -S bash '{{.Path}}'"
    expect_disconnect = true
    pause_before      = "0s"
    scripts = [
      "script/update.sh",
      "script/reboot.sh"
    ]
  }

  provisioner "shell" {
    execute_command = "echo '${var.ssh_password}' | {{.Vars}} sudo -E -S bash '{{.Path}}'"
    pause_before    = "60s"
    scripts = [
      "script/libvirt.sh",
      "script/vagrant.sh",
      "script/motd.sh",
      "script/cleanup.sh"
    ]
  }

  post-processor "vagrant" {
    compression_level      = 9
    keep_input_artifact    = false
    output                 = "output/{{.Provider}}/${var.vm_name}-${var.version}.box"
    vagrantfile_template   = var.vagrantfile_template
  }
}
