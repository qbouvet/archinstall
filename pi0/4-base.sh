 #!/bin/bash

if [ $# -gt 0 ] && { [ "$1" == "-h" ] || [ "$1" == "--help" ] ;} ; then
printf "
    Perform the base configuration of the linux system. 
      * pacman setup
      * packages installation
      * SSH setup
      * Network setup 
      * Users setup
      * time, date, hostname, ...
"
return 0
fi


# ----- Prelude

set -euo pipefail   # Exit on 1/ nonzero exit code 2/ unassigned variable 3/ pipe error
shopt -s nullglob   # Allow null globs
#set -o xtrace      # Show xtrace  


# ----- Imports

pushd /install/pi0/ 2>&1 >/dev/null
wd=$(pwd)   # Needed ? 

# Variables don't need to be re-sourced, but functions do ???
source "${wd}/config.sh"                  # <- This is not needed ? 
source "${wd}/../common/utils/f.sh"       # <- But this is ? 
source "${wd}/../common/utils/indent.sh"  # <- But this is ? 
source "${wd}/../common/utils/report.sh"  # <- But this is ? 
source "${wd}/../common/dropin.sh"        # <- But this is ? 
di_setsrcdir "${wd}/drop-in/"


# ----- Sanity checks

if [[ $(grep "armv" < <(uname -a)) ]] 
then 
    printf "Running inside chroot on ARM ISA with qemu\n"
else 
    printf "Running without qemu-arm chroot.\n"
    printf "Exiting."
    exit 1
fi


# ----- Pacman 

f_uncomment "/etc/pacman.conf" "Color"
pacman-key --init
pacman-key --populate archlinuxarm
pacman --noprogressbar --noconfirm -Syu
pacman --noprogressbar --noconfirm -S pacutils

# Install packages
pacman --noprogressbar --noconfirm -S $("${wd}/../common/pkgs.sh" pi0 pizero)
# Empty cache
#pacman --noconfirm -Scc 


# ----- SSH

pacman --noconfirm -S openssh
systemctl enable sshd

# Forbid root login
f_append    "/etc/ssh/sshd_config" "\n\nPermitRootLogin no"

# All other users can login
f_overwrite "/etc/hosts.allow"     "sshd: ALL"
f_overwrite "/etc/hosts.deny"      ""

# Change the default port
mkdir -p "/etc/systemd/system/sshd.socket.d/"
f_overwrite "/etc/systemd/system/sshd.socket.d/override.conf" "\
[Socket]
ListenStream=
ListenStream=${ssh_port}
"

report_append " \
  * SSH via port ${ssh_port}
  * SSH root login disbled
  * All other users can use SSH
"


# ----- Network

report_append "\n\nNetwork"

#    USB-gadget ethernet configuration
#
# Inspired from (and modified) : 
#   * https://medium.com/@dwilkins/usb-gadget-mode-with-arch-linux-and-the-raspberry-pi-zero-e70a0f17730a
# But see also (simpler version that worked previously and didn't this time): 
#   * https://blog.gbaman.info/?p=791n
f_overwrite "/boot/config.txt" "\
    # /boot/config.txt
    # See /boot/overlays/README for all available options
    gpu_mem=64
    dtoverlay=dwc2
"
f_overwrite "/etc/modules-load.d/raspberrypi.conf" "\
    # /etc/modules-load.d/raspberrypi.conf
    # TODO: Not sure this is entirely necessary
    # TODO: At least, this could probably go into /boot/cmdline.txt
    bcm2708-rng
    snd-bcm2835
    dwc2
    g_ether
"
f_overwrite "/etc/modprobe.d/g_ether.conf" "\
    # /etc/modprobe.d/g_ether.conf
    # TODO: This could probably be configurable
    options g_ether host_addr=12:a5:cf:42:92:fd dev_addr=5e:bc:ca:27:92:b1 idVendor=1317 idProduct=42146
"

function use_netctl () {
  pacman --noconfirm -S netctl
  systemctl enable dhcpcd
  # Wired network over usb-gadget-ethernet
  f_overwrite "/etc/netctl/usb-gadget-eth" "\
    # /etc/netctl/usb-gadget-eth
    Description='pizero g_ether gadget'
    Interface=usb0
    Connection=ethernet
    IP=dhcp
  "
  netctl enable usb-gadget-eth
  # Multiple wireless networks with automatic switching
  #   * Wireless profiles:  https://wiki.archlinux.org/index.php/netctl#Wireless_(WPA-PSK)
  #   * Systemd service:    https://wiki.archlinux.org/index.php/netctl#Wireless
  di_drop "netctl-wlan0-profiles" "/"
  systemctl enable netctl-auto@wlan0.service
  report_append "
    network:
      1.  Wired networks are handled by netctl and use dhcpcd
      2.  Wireless networks are handled by netctl + wpa_supplicant: 
          $(ls /etc/wpa_supplicant/)
  \n"
}

use_netctl

function use_systemdnetworkd () {
  #
  #   KEPT FOR REFERENCE
  #
  #   This doesn't configure the wired interface and 
  #   has not been tested. 
  #
  f_overwrite "/etc/systemd/network/wlan0.network" "\
    [Match]
    Name=wlan0
    [Network]
    DHCP=yes
  "
  di_drop "systemd-networkd-wpa-supplicant-secrets" "/"
  systemctl enable wpa_supplicant@wlan0.service | indent 2
  report_append "
    network:
      1.  Hostname is ${hostname}
      2.  Wireless networks are handled by systemd-networkd + wpa_supplicant: 
          $(ls /etc/wpa_supplicant/)
  \n"
}

function use_networkmanager () {
  #
  #   KEPT FOR REFERENCE
  #
  # Right now this is shit
  pacman --noconfirm -S networkmanager
  # Need to configure the networks. Either: 
  #  * connect to predefined networks
  #  * create a predefined hotspot
  systemctl enable NetworkManager
}


# ----- Time, locale, hostname

ln -sf "$timezone" /etc/localtime
timedatectl set-ntp true

pacman --noconfirm -S ntp fake-hwclock
systemctl enable ntpd.service
systemctl enable fake-hwclock fake-hwclock-save.timer

f_uncomment "/etc/locale.gen"  "en_US.UTF-8 UTF-8"
f_overwrite "/etc/locale.conf" "LANG=en_US.UTF-8"
locale-gen

f_overwrite "/etc/hostname" "${hostname}"

report_append "\
Time: 
  Enabled NTP
  Enabled fake-hwclock
\n"


# ----- Users

report_append "\n\nUsers: "

# Set default root password
printf "Set root password\n"
printf "root\nroot" | passwd "root"
report_append "  * Default root password is 'root'. Change it !!!"

# Create new users
printf "Create users:\n"
for user in ${users[@]}
do 
  printf "  * ${user}\n"
  if ! [[ "$(grep "$user" /etc/passwd)" ]] 
  then 
    useradd -m -g users -G wheel "$user"
  fi 
  printf "$user\n$user" | passwd "$user"
done 
report_append "  * Default users created: ${users[@]}. Change their passwords !!!"

# Delete default user
printf "Delete user 'alarm'"
ret=0; 
id -u alarm &> /dev/null || ret=$?
if [[ $ret -eq 0 ]]; then 
    userdel alarm;
    rm -rf /home/alarm;
    report_append "  * Default user removed: alarm"
fi 

# Enable sudo
printf "Enable sudo"
pacman --noconfirm -S sudo
f_uncomment "/etc/sudoers"  " %wheel ALL=(ALL) ALL"
report_append "  * Sudo enabled for all users"


# -----  Swap

report_append "\n\nSWAP: "

touch    "/etc/sysctl.d/99-sysctl.conf"
f_append "/etc/sysctl.d/99-sysctl.conf" "\nvm.swappiness=30"
f_append "/etc/sysctl.d/99-sysctl.conf" "\nvm.vfs_cache_pressure=$vfs_cache_pressure"
f_append "/etc/sysctl.d/99-sysctl.conf" "\nvm.dirty_background_ratio=1"
f_append "/etc/sysctl.d/99-sysctl.conf" "\nvm.dirty_ratio=50"

if [[ "$use_systemd_swap" == "true" ]]
then 
  pacman --noconfirm -S systemd-swap
  mkdir -p /var/lib/systemd-swap/swapfc
  systemctl enable systemd-swap
  report_append "  * systemd-swap enabled"
fi

# Swap
  #pushd "/" > /dev/null
  #dd if=/dev/zero of=swap_1G bs=1MiB count="$swapfile_size_mib"
  #chmod 600 "$swapfile_path";
  #mkswap "$swapfile_path" 2>&1 | indent 2;
  #popd > /dev/null
# fstab  
  #newline="$swapfile_path \tnone \tswap \tdefaults \t0 \t0 \n"
  #ret=0
  #grep "$newline" /etc/fstab || ret=$?
  #[[ ret -ne 0 ]] && fAppend /etc/fstab "$newline"
  #echo "  Fstab:"
  #cat "/etc/fstab"
