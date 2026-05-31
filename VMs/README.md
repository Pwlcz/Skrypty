# Virtual Environment

Vagrant environments and Packer templates to build vagrant boxes. Currently only for qemu/libvirt.

* **Packer** dir contains templates and creation pipeline. More info inside.

* Other dirs contain vagrant environments.

## Setup

If you are running this on a fresh Linux workstation (Debian/Ubuntu/Mint or Arch), run the bootstrap script to automatically install Packer, Vagrant, and the required HashiCorp plugins.

```bash
chmod +x setup-host.sh
./setup-host.sh
```

* Set libvirt as default provider

```bash
export VAGRANT_DEFAULT_PROVIDER=libvirt
```

* add SPICE config to vagrantfile

```ruby
# Enable SPICE graphics and a virtual GPU
domain.graphics_type = "spice"
domain.video_type = "virtio"
domain.video_vram = 256

# Enable the SPICE channel for clipboard sharing and dynamic resizing
domain.channel type: "spicevmc", target_name: "com.redhat.spice.0", target_type: "virtio"
```


## Troubleshooting vagrant

### vagrant up hangs on nfs setup

<https://github.com/vagrant-libvirt/vagrant-libvirt/issues/735>

<https://ostechnix.com/vagrant-up-hangs-when-mounting-nfs-shared-folders-how-to-fix/>

Default synced_folder config may be broken for libvirt, change it, like example below, or check links.

```ruby
config.vm.synced_folder ".", "/vagrant", type: "nfs", nfs_udp: false, nfs_version: 4, mount_options: ["tcp", "nolock", "actimeo=2"]
```

### [fog][WARNING] Unrecognized arguments: libvirt_ip_command

Minor annoyance, quick fix:

1. open

```text
~/.vagrant.d/gems/<ruby_version>/gems/vagrant-libvirt-<version>/lib/vagrant-libvirt/driver.rb
```

2. edit

```ruby
conn_attr = {
  provider: 'libvirt',
  libvirt_uri: uri,
  libvirt_ip_command: ip_command,  <------------------Delete / Comment this line
}
```

3. Spam gone

Updating the plugin may make this spam appear again.
