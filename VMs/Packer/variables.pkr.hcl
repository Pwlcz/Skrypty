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

##############
# VARIABLES
##############

### VM variables ###

variable "cpus" {
  type        = number
  description = "Number of CPUs"
  default     = 2
}

variable "memory" {
  type        = number
  description = "Memory in MB"
  default     = 4096
}

variable "disk_size" {
  type        = number
  description = "Disk size in MB"
  default     = 65536
}

variable "headless" {
  type        = bool
  description = "Run Installation vm in headless mode"
  default     = false
}

variable "vm_name" {
  type        = string
  description = "Name of the virtual machine"
}

### ISO variables ###

variable "iso_checksum_type" {
  type        = string
  description = "Type of checksum (sha256, md5, file, etc)"
  default     = "sha256"
}

variable "iso_checksum" {
  type        = string
  description = "Checksum of the ISO file"
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

### Installation variables ###

variable "boot_command_prefix" {
  type        = string
  description = "Boot command prefix for unattended installation"
}

### Vagrant variables ###

variable "vagrantfile_template" {
  type        = string
  description = "Path to Vagrantfile template"
}

variable "box_tag" {
  type        = string
  description = "Vagrant Cloud box tag (org/name)"
  default     = "pwlcz/arch"
}

variable "version" {
  type        = string
  description = "Box version"
}

variable "version_description" {
  type        = string
  description = "Box version description"
}

variable "hcp_client_id" {
  type        = string
  description = "HCP Service Principal Client ID"
  sensitive   = true
}

variable "hcp_client_secret" {
  type        = string
  description = "HCP Service Principal Client Secret"
  sensitive   = true
}

### SSH variables ###

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

variable "ssh_timeout" {
  type    = string
  default = "30m"
}

variable "hostname" {
  type        = string
  description = "Hostname for the VM"
  default     = "vagrant"
}

locals {
  # Determines the build suffix
  build_date = formatdate("YYYY.MM.DD", timestamp())
}