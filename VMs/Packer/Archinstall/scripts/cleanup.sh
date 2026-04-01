#!/usr/bin/bash -x

# Clean the pacman cache
echo ">>>> cleanup.sh: Cleaning pacman cache.."
/usr/bin/arch-chroot /mnt /usr/bin/pacman -Scc --noconfirm

# Write zeros to improve virtual disk compaction.
if ${WRITE_ZEROS:-false}; then
  echo ">>>> cleanup.sh: Writing zeros to improve virtual disk compaction.."
  zerofile=$(/usr/bin/mktemp /mnt/zerofile.XXXXX)
  /usr/bin/dd if=/dev/zero of="${zerofile}" bs=1M || true
  /usr/bin/rm -f "${zerofile}"
  /usr/bin/sync
fi