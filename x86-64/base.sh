#!/usr/bin/env bash

source ${wd}/utils/f.sh

export LANG=C # locale errors when building mandb



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



# ----- Users

printf "root\nroot" | passwd "root"

user="quentin"
useradd -m -g users -G wheel "$user"
printf "$user\n$user" | passwd "$user"
f.uncomment "/etc/sudoers" \
  " %wheel ALL=(ALL) ALL"

useradd -M "installer"
f.append "/etc/sudoers" \
  "\n\ninstaller ALL=(ALL) NOPASSWD:ALL"



# ----- SSH

pacman --noconfirm -S openssh

f.append "/etc/ssh/sshd_config" \
  "\n\n PermitRootLogin no"

f.overwrite "/etc/host.allow" \
  "sshd : ALL : allow"



# ----- Swap

pacman --noconfirm -S systemd-swap
mkdir -p /var/lib/systemd-swap/swapfc
systemctl enable systemd-swap
f.overwrite "/etc/systctl.d/99-sysctl.conf" \
  "vm.swappiness=30"
#f.append "/etc/systctl.d/99-sysctl.conf" \
#  "\nvm.vfs_cache_pressure=$vfs_cache_pressure"
f.append "/etc/systctl.d/99-sysctl.conf" \
  "\nvm.dirty_background_ratio=1"
f.append "/etc/systctl.d/99-sysctl.conf" \
  "\nvm.dirty_ratio=50"



# ----- Packages

pacman-key --init
pacman-key --populate archlinux 
pacman --noprogressbar --noconfirm -Syu
pacman --noprogressbar --noconfirm -S pacutils

# yay
pushd /tmp
sudo -u installer git clone https://aur.archlinux.org/yay.git
cd yay 
pacman --noprogressbar --noconfirm -S go 
sudo -u quentin makepkg -s
pacman --noconfirm -U *.zst
popd

sudo -u installer yay -Syu --noconfirm --sudoloop --batchinstall \
  --removemake \
  --noredownload --norebuild \
  --answerdiff None --answerclean None --answeredit None --answerupgrade None \
  $($wd/pkgs.sh amd system)



# ----- Remove installer user

f.comment "/etc/sudoers" \
  "installer ALL=(ALL) NOPASSWD:ALL""

userdel installer