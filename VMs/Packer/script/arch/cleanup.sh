#!/usr/bin/bash -x

echo "==> cleanup.sh: Cleaning pacman cache.."
/usr/bin/arch-chroot /mnt /usr/bin/pacman -Scc --noconfirm

echo "==> cleanup.sh: Writing zeros to improve virtual disk compaction.."
zerofile=$(/usr/bin/mktemp /mnt/zerofile.XXXXX)
/usr/bin/dd if=/dev/zero of="${zerofile}" bs=1M || true
/usr/bin/rm -f "${zerofile}"
/usr/bin/sync
