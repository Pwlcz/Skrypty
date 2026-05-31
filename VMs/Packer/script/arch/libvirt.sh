#!/bin/bash -eux

echo '==> Installing QEMU guest agents and Spice vdagent for better integration with the host'
/usr/bin/arch-chroot /mnt /usr/bin/pacman -Syu --noconfirm spice-vdagent qemu-guest-agent curl

echo '==> Enabling and starting qemu-guest-agent service'
/usr/bin/arch-chroot /mnt /usr/bin/systemctl enable qemu-guest-agent
/usr/bin/arch-chroot /mnt /usr/bin/systemctl start qemu-guest-agent || true

echo '==> Enabling and starting spice-vdagent service'
/usr/bin/arch-chroot /mnt /usr/bin/systemctl enable spice-vdagent
/usr/bin/arch-chroot /mnt /usr/bin/systemctl start spice-vdagent || true