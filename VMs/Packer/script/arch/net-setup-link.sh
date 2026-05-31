#!/bin/bash -eux

echo '==> Post-Install: Reverting to traditional interface names (eth0)..'
ln -s /dev/null /mnt/etc/udev/rules.d/80-net-setup-link.rules