#!/bin/bash -i 


## Init
##
__dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ ! -f "$__dir"/variables.sh ]; then 
    echo "0-config.sh not found, exiting"; 
fi
set -o nounset      # exit on unassigned variable
set -o errexit      # exit on error
source "$__dir"/0-config.sh
loadkeys fr_CH
pushd "$__dir"



## Précautions d'usage
##
echo " Have you partitionned your disk correctly ? " ; read
lsblk; printf "\n\n";
echo " Are you sure nothing important is on $dev_root ? "; read



ask_go " [ Wifi setup ] (skip if not using wifi)"
if [ "$ask_go_go" == "true" ] ; then 
    wifi-menu
    echo "sleeping 10s"; sleep 10s
fi



ping -c 3 google.com
ask_go "If the internet if not correctly configured, please stop"



ask_go " [ Mounting partitions - $dev_root]"
if [ "$ask_go_go" == "true" ] ; then 
    mkdir rootfs;
    mount "$dev_root" rootfs            # new system root partition
    lsblk
fi



ask_go " [ pacstrap & fstab ]"
if [ "$ask_go_go" == "true" ] ; then 
    pacstrap rootfs base base-devel
    genfstab -U rootfs >> rootfs/etc/fstab
fi



ask_go " [ Download scripts & dotfiles to new install ]"
if [ "$ask_go_go" == "true" ] ; then 
    pacman -Sy
    pacman -S git git-lfs

    mkdir -p rootfs/scripts
    pushd rootfs/scripts
    
    git init
    git remote add origin_https https://github.com/sgPepper/scripts.git
    git pull origin_https master
    chmod -R +x .
    
    pushd dotfiles
    git init
    git remote add origin_https https://github.com/sgPepper/dotfiles.git
    git pull origin_https master
    
    popd
    popd
fi



ask_go " [ chrooting ]"
if [ "$ask_go_go" == "true" ] ; then 
    mkdir -p "rootfs/install"
    cp *.sh "rootfs/install"
    printf "Press enter to enter chroot, and run /install/2-in-chroot.sh"; read;
    arch-chroot rootfs;
fi



# Chroot script runs here



ask_go " [ shutting off ]"
if [ "$ask_go_go" == "true" ] ; then 
    umount rootfs
    popd; 
    poweroff;
fi
