#!/usr/bin/env bash


# ----- Prelude

# Usual bash flags
set -euo pipefail   # Exit on 1/ nonzero exit code 2/ unassigned variable 3/ pipe error
shopt -s nullglob   # Allow null globs
#set -o xtrace      # Show xtrace  

source $wd/config.sh
source $wd/utils/f.sh


# ----- mkinitcpio

if ! [[ $(grep 'archzfs' /etc/pacman.conf) ]]
then 
  f.append "/etc/pacman.conf" \
    "\n\n" \
    "\n#   ZFS Repo" \
    "\n[archzfs]" \
    "\nServer = http://archzfs.com/\$repo/x86_64" \
    "\nSigLevel = Optional TrustAll"
fi

# Ugly receive key
(yes || true) | pacman -Sy

pacman -S --noconfirm zfs-linux-lts

f.replaceLine "/etc/mkinitcpio.conf" \
  "HOOKS=(" \
  "HOOKS=(base udev autodetect modconf block keyboard zfs filesystems fsck)"
mkinitcpio -P


# ----- Mount ZFS pools at boot

# For some reason works without:
# https://wiki.archlinux.org/index.php/Install_Arch_Linux_on_ZFS#Configure_systemd_ZFS_mounts


# ----- Bootloader

# Only grub allows /boot in zpool, so we use grub

pacman -S --noconfirm grub efibootmgr

# !! important
export ZPOOL_VDEV_NAME_PATH=1 

grub-install \
  --target=x86_64-efi \
  --efi-directory=/boot/EFI \
  --bootloader-id=GRUB

# Disable incompatible entries
mkdir -p /etc/grub.d/disabled
mv "/etc/grub.d/10_"* "/etc/grub.d/20_"* "/etc/grub.d/30_"* \
  "/etc/grub.d/disabled"

# Add our GRUB/ZFS compatible entry
cp -a "/etc/grub.d/40_custom" "/etc/grub.d/10_arch_linux_zfs"
f.append "/etc/grub.d/10_arch_linux_zfs" \
  "\nmenuentry \"Arch Linux ZFS\" {" \
  "\n  linux /rootfs/@/boot/vmlinuz-linux-lts zfs=zroot/rootfs rw" \
  "\n  initrd /rootfs/@/boot/initramfs-linux-lts.img" \
  '\n}'

grub-mkconfig \
   -o /boot/grub/grub.cfg

