#!/bin/bash -eux

echo '==> Post-Install: Configuring sudo for Vagrant..'

echo 'Defaults env_keep += \"SSH_AUTH_SOCK\"' > /mnt/etc/sudoers.d/10_vagrant
echo 'vagrant ALL=(ALL) NOPASSWD: ALL' >> /mnt/etc/sudoers.d/10_vagrant
chmod 0440 /mnt/etc/sudoers.d/10_vagrant