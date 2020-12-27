#!/usr/bin/env bash


# ----- Prelude

# Usual bash flags
set -euo pipefail   # Exit on 1/ nonzero exit code 2/ unassigned variable 3/ pipe error
shopt -s nullglob   # Allow null globs
#set -o xtrace      # Show xtrace  
 
source $wd/config.sh
source $wd/utils/f.sh

export LANG=C # locale errors when building mandb


# ----- Pacman

pacman-key --init
pacman-key --populate archlinux 
pacman -Sy
pacman --noprogressbar --noconfirm -Syu
pacman --noprogressbar --noconfirm -S pacutils


# ----- Time

ln -sf "$timezone" /etc/localtime
timedatectl set-ntp true
pacman --noconfirm -S ntp
systemctl enable ntpd.service
f.uncomment "/etc/locale.gen" \
  "en_US.UTF-8 UTF-8"
f.overwrite "/etc/locale.conf" \
  "LANG=en_US.UTF-8"
locale-gen


# ----- Hostname 

f.overwrite "/etc/hostname" "${hostname}"


# ----- Users

printf "root\nroot" | passwd "root"

for user in ${users[@]}
do 
  if ! [[ "$(grep "$user" /etc/passwd)" ]] 
  then 
    useradd -m -g users -G wheel "$user"
  fi 
  printf "$user\n$user" | passwd "$user"
done 
f.uncomment "/etc/sudoers" \
  " %wheel ALL=(ALL) ALL"


# ----- Network

pacman --noconfirm -S networkmanager
systemctl enable NetworkManager


# ----- SSH

pacman --noconfirm -S openssh

f.append "/etc/ssh/sshd_config" \
  "\n\n PermitRootLogin no"

f.overwrite "/etc/host.allow" \
  "sshd : ALL : allow"

systemctl enable sshd


# ----- Swap

pacman --noconfirm -S systemd-swap
mkdir -p /var/lib/systemd-swap/swapfc
systemctl enable systemd-swap
f.overwrite "/etc/sysctl.d/99-sysctl.conf" \
  "vm.swappiness=30"
#f.append "/etc/sysctl.d/99-sysctl.conf" \
#  "\nvm.vfs_cache_pressure=$vfs_cache_pressure"
f.append "/etc/sysctl.d/99-sysctl.conf" \
  "\nvm.dirty_background_ratio=1"
f.append "/etc/sysctl.d/99-sysctl.conf" \
  "\nvm.dirty_ratio=50"