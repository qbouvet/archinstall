#!/usr/bin/env bash

source $wd/utils/f.sh



# ----- mkinitcpio

f.append "/etc/pacman.conf" \
  "\n\n" \
  "\n#   ZFS Repo" \
  "\n[archzfs]" \
  "\nServer = http://archzfs.com/\$repo/x86_64" \
  "\nSigLevel = Optional TrustAll"

# receive key
yes | pacman -Sy
pacman -S --noconfirm zfs-linux-lts

f.replaceLine "/etc/mkinitcpio.conf" \
  "HOOKS=(" \
  "HOOKS=(base udev autodetect modconf block keyboard zfs filesystems fsck)"
mkinitcpio -P



# ----- Bootloader

# Only grub allows to have /boot in the zpool, so we choose grub

pacman -S --noconfirm grub efibootmgr

# Format and mount /dev/sda1 to /boot/EFI

# /etc/default/grub
  # GRUB_CMDLINE_LINUX_DEFAULT="not quiet"
  # GRUB_CMDLINE_LINUX="root=ZFS=zpool/ROOT/default"

# !! important
export ZPOOL_VDEV_NAME_PATH=1 

grub-install \
  --target=x86_64-efi \
  --efi-directory=/boot/EFI \
  --bootloader-id=GRUB

grub-mkconfig \
   -o /boot/grub/grub.cfg

