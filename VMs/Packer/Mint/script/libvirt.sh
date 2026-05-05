#!/bin/bash -eux

echo '==> Installing QEMU guest agents and Spice vdagent for better integration with the host'
apt-get -y install spice-vdagent qemu-guest-agent curl

echo '==> Enabling and starting qemu-guest-agent service'
systemctl enable qemu-guest-agent
systemctl start qemu-guest-agent || true

echo '==> Enabling and starting spice-vdagent service'
systemctl enable spice-vdagent
systemctl start spice-vdagent || true

