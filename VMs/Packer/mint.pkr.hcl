variable "preseed" {
  type        = string
  description = "Preseed filename for unattended installation"
}

##############
# SOURCE
##############

source "qemu" "linux" {
  headless         = var.headless
  vm_name          = var.vm_name
  http_directory   = "http"
  iso_urls         = var.iso_urls
  iso_checksum     = "${var.iso_checksum_type}:${var.iso_checksum}"
  iso_target_path  = var.iso_target_path
  ssh_username     = var.ssh_username
  ssh_password     = var.ssh_password
  ssh_wait_timeout = var.ssh_timeout
  shutdown_command = "echo '${var.ssh_password}' | sudo -S shutdown -P now"
  shutdown_timeout = "1m"

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

  qemu_binary      = "qemu-system-x86_64"
  accelerator      = "kvm"
  disk_interface   = "virtio"
  format           = "qcow2"
  cpus             = var.cpus
  memory           = var.memory
  disk_size        = var.disk_size
  net_device       = "virtio-net"
  machine_type     = "pc"
  use_backing_file = false
  vnc_port_min     = 5900
  vnc_port_max     = 6000
}

##############
# BUILD
##############

build {
  name = "linux-mint"
  sources = [
    "source.qemu.linux"
  ]

  # Post-install cleanup
  provisioner "shell" {
    execute_command = "echo '${var.ssh_password}' | {{.Vars}} sudo -E -S bash '{{.Path}}'"
    scripts = [
      "script/mint/rc_local.sh",
      "script/mint/apt.sh",
      "script/mint/sshd.sh"
    ]
  }

  # Packages update
  provisioner "shell" {
    execute_command   = "echo '${var.ssh_password}' | {{.Vars}} sudo -E -S bash '{{.Path}}'"
    expect_disconnect = true
    pause_before      = "0s"
    scripts = [
      "script/mint/rm_apps.sh",
      "script/mint/update.sh",
      "script/mint/reboot.sh"
    ]
  }

  # Final provisioning after reboot
  provisioner "shell" {
    execute_command = "echo '${var.ssh_password}' | {{.Vars}} sudo -E -S bash '{{.Path}}'"
    pause_before    = "60s"
    scripts = [
      "script/mint/libvirt.sh",
      "script/mint/vagrant.sh",
      "script/mint/motd.sh",
      "script/mint/cleanup.sh"
    ]
  }

  post-processors {
    post-processor "vagrant" {
      compression_level    = 9
      keep_input_artifact  = false
      output               = "output/{{.Provider}}/${var.vm_name}-${local.build_date}.box"
      vagrantfile_template = var.vagrantfile_template
    }

    post-processor "vagrant-registry" {
      box_tag       = var.box_tag
      version       = var.version
      client_id     = var.hcp_client_id
      client_secret = var.hcp_client_secret
      architecture  = "amd64"
      no_release    = true
    }
  }
}
