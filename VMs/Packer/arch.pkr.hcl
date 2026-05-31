##############
# SOURCE
##############

source "qemu" "arch" {
  headless         = var.headless
  vm_name          = var.vm_name
  http_directory   = "http"
  iso_urls         = var.iso_urls
  iso_checksum     = "${var.iso_checksum_type}:${var.iso_checksum}"
  iso_target_path  = var.iso_target_path
  ssh_username     = var.ssh_username
  ssh_password     = var.ssh_password
  ssh_timeout      = var.ssh_timeout
  shutdown_command = "echo '${var.ssh_password}' | sudo -S shutdown -P now"
  shutdown_timeout = "1m"

  boot_wait = "5s"
  boot_command = [
    var.boot_command_prefix,
    "/usr/bin/curl -O http://{{ .HTTPIP }}:{{ .HTTPPort }}/arch/enable-ssh.sh<enter><wait5>",
    "/usr/bin/bash ./enable-ssh.sh<enter>"
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

# TODO: Proxmox source

##############
# BUILD
##############

build {
  name = "arch"
  sources = [
    "source.qemu.arch"
  ]

  provisioner "file" {
    source      = "http/arch/user_configuration.json"
    destination = "/tmp/user_configuration.json"
  }

  provisioner "file" {
    source      = "http/arch/user_credentials.json"
    destination = "/tmp/user_credentials.json"
  }

  provisioner "shell" {
    execute_command = "{{.Vars}} sudo -E -S bash -c '{{.Path}}'"
    inline = [
      "echo '==> Running archinstall in unattended mode...'",
      "archinstall --config /tmp/user_configuration.json --creds /tmp/user_credentials.json --silent"
    ]
  }

  provisioner "shell" {
    execute_command = "{{.Vars}} sudo -E -S bash '{{.Path}}'"
    scripts = [
      "script/arch/sudo.sh",
      "script/arch/sshd.sh",
      "script/arch/net-setup-link.sh",
      "script/arch/vagrant.sh",
      "script/arch/libvirt.sh"
    ]
  }

  provisioner "shell" {
    execute_command = "{{.Vars}} sudo -E -S bash '{{.Path}}'"
    script          = "script/arch/cleanup.sh"
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