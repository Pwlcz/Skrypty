#!/bin/bash -eux

echo '==> Post-Install: Installing Vagrant SSH keys..'

arch-chroot /mnt install --directory --owner=vagrant --group=vagrant --mode=0700 /home/vagrant/.ssh
curl --output /mnt/home/vagrant/.ssh/authorized_keys --location https://raw.github.com/hashicorp/vagrant/master/keys/vagrant.pub
arch-chroot /mnt chown vagrant:vagrant /home/vagrant/.ssh/authorized_keys
arch-chroot /mnt chmod 0600 /home/vagrant/.ssh/authorized_keys