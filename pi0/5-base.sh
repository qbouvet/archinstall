 #!/bin/bash

if [ $# -gt 0 ] && { [ "$1" == "-h" ] || [ "$1" == "--help" ] ;} ; then
printf "
    Download and cache the Arch Linux ARM ISO
"
return 0
fi


# ----- Prelude

set -euo pipefail   # Exit on 1/ nonzero exit code 2/ unassigned variable 3/ pipe error
shopt -s nullglob   # Allow null globs
#set -o xtrace      # Show xtrace  


# ----- Imports

pushd /install/pi0/
wd=$(pwd)   # Needed ? 

# Variables don't need to be re-sourced, but functions do ???
source "${wd}/config.sh"                     # <- This is not needed ? 
source "${wd}/../common/utils/f.sh"          # <- But this is ? 
#source "${wd}/../common/utils/indent.sh"     # <- But this is ? 
#source "${wd}/../common/utils/report.sh"     # <- But this is ? 
bash --version


# ----- Sanity checks

if [[ $(grep "armv7" < <(uname -a)) ]] 
then 
    printf "Running inside chroot on armv7 ISA with qemu\n"
else 
    printf "Running without qemu-arm chroot.\n"
    printf "Exiting."
    exit 1
fi

exit 1


# ----- Pacman 

f.uncomment "/etc/pacman.conf" "Color"
pacman-key --init
pacman-key --populate archlinuxarm
pacman --noprogressbar --noconfirm -Syu
pacman --noprogressbar --noconfirm -S pacutils

# Install packages, empty cache
#pacinstall --noconfirm --install "${packages[@]}" 
#pacman --noconfirm -Scc 
# ^ TODO


# ----- Time, locale, hostname

ln -sf "$timezone" /etc/localtime
timedatectl set-ntp true

pacman --noconfirm -S ntp fake-hwclock
systemctl enable ntpd.service
systemctl enable fake-hwclock

f.uncomment "/etc/locale.gen"  "en_US.UTF-8 UTF-8"
f.overwrite "/etc/locale.conf" "LANG=en_US.UTF-8"
#localectl set-locale LANG=en_US.UTF-8                  # <<< DELETE ?
locale-gen

f.overwrite "/etc/hostname" "${hostname}"

report.append "\
Time: 
  Enabled NTP
  Enabled fake-hwclock
\n"


# ----- Users

report.append("\n\nUsers: ")

# Set default root password
printf "Set root password\n"
printf "root\nroot" | passwd "root"
report.append("  * Default root password is 'root'. Change it !!!")

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
report.append("  * Default users created: ${users[@]}. Change their passwords !!!")

# Delete default user
printf "Delete user 'alarm'"
ret=0; 
id -u alarm &> /dev/null || ret=$?
if [[ $ret -eq 0 ]]; then 
    userdel alarm;
    rm -rf /home/alarm;
    report.append "  * Default user removed: alarm"
fi 

# Enable sudo
printf "Enable sudo"
pacman --noconfirm -S sudo
f.uncomment "/etc/sudoers"  " %wheel ALL=(ALL) ALL"
report.append "  * Sudo enabled for all users"


# ----- Network and SSH

report.append("\n\nNetwork")

function NetworkWithNetworkManager () {
    pacman --noconfirm -S networkmanager
    systemctl enable NetworkManager
}

function NetworkWithSystemdNetworkd () {
    f.overwrite "/etc/systemd/network/wlan0.network" "\
        [Match]
        Name=wlan0
        [Network]
        DHCP=yes
    "
    systemctl enable wpa_supplicant@wlan0.service 2>&1 | indent 2
    report.append "
    network:
        1.  Hostname is ${hostname}
        2.  Wireless networks are handled by wpa_supplicant/systemd-networkd: 
            $(ls /etc/wpa_supplicant/)
    \n"
}

NetworkWithNetworkManager
report.append " * Handled by NetworkManager"

# SSH
pacman --noconfirm -S openssh

# Forbid root login
f.append    "/etc/ssh/sshd_config" "\n\n PermitRootLogin no"

# All other users can login
f.overwrite "/etc/host.allow"      "sshd : ALL : allow"

# Change the default port
mkdir -p "/etc/systemd/system/sshd.socket.d/"
f.overwrite "/etc/systemd/system/sshd.socket.d/override.conf" "\
[Socket]
ListenStream=
ListenStream=${ssh_port}
"

report.append " \
  * SSH via port ${ssh_port}
  * SSH root login disbled
  * All other users can use SSH
"


# -----  Swap

report.append("\n\nSWAP: ")

touch    "/etc/sysctl.d/99-sysctl.conf"
f.append "/etc/sysctl.d/99-sysctl.conf" "\nvm.swappiness=30"
f.append "/etc/sysctl.d/99-sysctl.conf" "\nvm.vfs_cache_pressure=$vfs_cache_pressure"
f.append "/etc/sysctl.d/99-sysctl.conf" "\nvm.dirty_background_ratio=1"
f.append "/etc/sysctl.d/99-sysctl.conf" "\nvm.dirty_ratio=50"

if [[ "$use_systemd_swap" == "true" ]]
then 
  pacman --noconfirm -S systemd-swap
  mkdir -p /var/lib/systemd-swap/swapfc
  systemctl enable systemd-swap
  report.append "  * systemd-swap enabled"
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