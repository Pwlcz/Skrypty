#!/bin/bash
set -e

echo "==> Installing Xorg, SPICE tools, and Cinnamon DE..."
pacman -S --noconfirm xorg-server qemu-guest-agent spice-vdagent cinnamon lightdm lightdm-gtk-greeter

echo "==> Enabling system services..."
systemctl enable qemu-guest-agent.service
systemctl enable spice-vdagentd.service
systemctl enable lightdm.service

echo "==> Desktop environment provisioning complete!"