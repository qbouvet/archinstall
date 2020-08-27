#!/usr/bin/env bash


## Setup
##
    # Error codes
set -o nounset      # exit on unassigned variable
set -o errexit      # exit on error
set -o pipefail     # exit on pipe fail

    # Acquire root
[ "$UID" -eq 0 ] || exec sudo bash "$0" "$@";

    # Set execution director
export __dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)";
pushd $__dir;

    # Source variables
source 0-config.sh




## Verify block device path
##
lsblk
printf "\n
 ( ! )  Selected block device is $blockdev. 
 ( ! )  Is this correct ? \n"; read; 
printf "\
 ( ! )  U sure ? "; read;




## Partition SD card
##
ask_go "[Unmount / Create / Format / Remount partitions]"; 
if [ "$ask_go_go" == "true" ] ; then 

        # Unmount
    printf "Unmounting ...\n"
        # shenanigan at the end in order to not exit on grep returning 1 if not mounted
    mountpoints=$(cat /proc/mounts | grep "$blockdev"  | awk '{print  $2; }' || [ $? == 1 ])
    echo "$mountpoints"
    if [ "$mountpoints" != "" ] ; then
        mountpoint=""
        echo "$mountpoints" | while read mountpoint ; do 
            echo "    unmounting $mountpoint"
            umount "$mountpoint"
        done;
    fi
    sleep 1s; lsblk; printf "... Done\n\n";
    
        # Create
    printf "Creating partition table...\n"
    parted --script "$blockdev" \
        mklabel msdos \
        mkpart primary fat16 2048s 206847s \
        mkpart primary ext4 "${rootfs_start}" "${rootfs_end}" \
        set 1 boot on ;
    printf "... Done\n\n"
    
        # Format
    printf "Formatting...\n"
    echo "y\n" | sudo mkfs.vfat "${blockdev}1";
    echo "y\n" | sudo mkfs.ext4 "${blockdev}2";
    printf "... Done\n\n"
    
        # Remount
    printf "Mounting...\n"
    mkdir -p "$__boot";
    mkdir -p "$__root";
    mount "${blockdev}1" "$__boot";
    mount "${blockdev}2" "$__root";
    printf "... Done\n\n"
fi




## Copy and extract file system
##
ask_go "[Extract filesystems]"
if [ "$ask_go_go" == "true" ] ; then 
        
        # Check parameters
    if [ ! -f "$alarm_archive" ] ; then
        echo "Arch linux ARM archive not found, exiting"; exit 1
    fi

        # Extract root file system
    echo "Extracting root file system"
    pushd "$__root";
        # redirect stderr to allow grep to filter error messages
    tar -xf ../"$alarm_archive" 2>&1 | grep -v 'SCHILY.fflags'
    popd;

        # Populate boot partition
    echo "populating /boot"
    mv "$__root"/boot/* "$__boot"/;

    echo "Flushing IO"
    sync;
fi 




## Wifi-at-boot setup
## cf https://ladvien.com/installing-arch-linux-raspberry-pi-zero-w/
## 
ask_go "[ setup wifi-at-boot & SSH ]"
if [ "$ask_go_go" == "true" ] ; then 
        # configure wifi
    systemd_network_wlan0=$(printf "\
        [Match]
        Name=wlan0
        
        [Network]
        DHCP=yes" \
    | sed 's|    ||g')
    echo "$systemd_network_wlan0" > ${__root}/etc/systemd/network/wlan0.network
    wpa_passphrase "${wifi_ssid}" "${wifi_wpapass}" > ${__root}/etc/wpa_supplicant/wpa_supplicant-wlan0.conf
    ln -s \
       ${__root}/usr/lib/systemd/system/wpa_supplicant@.service \
       ${__root}/etc/systemd/system/multi-user.target.wants/wpa_supplicant@wlan0.service && true
    
        # Hostname
    printf "$hostname" > "$__root"/etc/hostname;
    
        # Configure SSH
    mkdir -p "$__root"/etc/systemd/system/sshd.socket.d/
    printf "[Socket]\nListenStream=\nListenStream=$ssh_port\n" \
        > "$__root"/etc/systemd/system/sshd.socket.d/override.conf
    sed 's|PermitRootLogin|#PermitRootLogin|' -i "$__root"/etc/ssh/sshd_config
    echo "sshd : ALL : allow" > "$__root"/etc/hosts.allow;
    sed 's|#X11Forwarding|X11Forwarding|' -i "$__root"/etc/ssh/sshd_config
fi




## Copy over networkmanager connection profiles
##
ask_go "[Copy over NetworkManager profiles]"
if [ "$ask_go_go" == "true" ] ; then 
    
    mkdir -p "${__root}/etc/NetworkManager/system-connections/";
    cp "${nm_profiles_dir}"/* "$__root"/etc/NetworkManager/system-connections/;
    
        # Mac addresses of the connection profiles must be changed to match the wifi chip's mac address
    for f in "$__root"/etc/NetworkManager/system-connections/* ; do 
        sed -i.bak "s/mac-address=..:..:..:..:..:../mac-address=$wifi_mac_addr/" "$f";
    done
    rm "$__root"/etc/NetworkManager/system-connections/*.bak;
    
        # Fix permissions 
    chown -R root:root "$__root"/etc/NetworkManager/system-connections/;
    chmod 700 "$__root"/etc/NetworkManager/system-connections;
    chmod -R 600 "$__root"/etc/NetworkManager/system-connections/*;
fi



ask_go "Setup ssh" 
if [ "$ask_go_go" == "true" ] ; then 
        # Hostname
    printf "$hostname" > "$__dir"/mnt-rootfs/etc/hostname;    
        # Allow SSH from everywhere
    echo "sshd : ALL : allow" > "$__root"/etc/hosts.allow;
        # Disallow root ssh login
    sed -i 's/#PermitRootLogin/PermitRootLogin/' "$__root"/etc/ssh/sshd_config;
    sed -i 's/PermitRootLogin [a-z\-]*/PermitRootLogin no/' "$__root"/etc/ssh/sshd_config;
fi




ask_go "Copy over additionnal setup data"
if [ "$ask_go_go" == "true" ] ; then 
    mkdir -p ${__root}/install
    cp -a *.sh ${__root}/install
    cp -a data-* ${__root}/install
fi




ask_go "Unmount sdcard"
if [ "$ask_go_go" == "true" ] ; then 
    umount "$__boot"; rmdir "$__boot";
    umount "$__root"; rmdir "$__root";
    lsblk
fi



## Unmount and exit
##
popd
printf "\n\n
A base arch image has been installed to sdcard. Connect the board to power, then : 

    (1)     nmap -sP 192.168.1.1/24
    (2)     ssh alarm@xxx.xxx.xxx.xxx
                > alarm
    (3)     cd /install; su
                > root
    (4)     ./2-setup-system.sh


Default credentials are : 
    alarm : alarm
    root  :  root
\n";


exit 0  ;




























########################################################################
#######################    LEGACY CODE    ##############################
########################################################################
## For reference later


echo "You've reached deprecated code";
exit 0;


function chrootman_2 {
    pacman  --sysroot ${__root} \
            --arch armv6h \
            --config ${__root}/etc/pacman.conf \
            --cachedir ${__root}/var/cache/pacman/pkg \
            --dbpath ${__root}/var/lib/pacman \
            --gpgdir ${__root}/etc/pacman.d/gnupg \
            --hookdir ${__root}/etc/pacman.d/hooks \
            $@
#            --skippgpcheck 
}

function chrootman {
    pacman  --root ${__root} \
            --arch armv6h \
            --config ${__root}/etc/pacman.conf \
            --cachedir ${__root}/var/cache/pacman/pkg \
            --dbpath ${__root}/var/lib/pacman \
            --gpgdir ${__root}/etc/pacman.d/gnupg \
            $@
#            --hookdir ${__root}/etc/pacman.d/hooks \
#            --skippgpcheck 
}

function chrootman-key {
    pacman-key \
        --config ${__root}/etc/pacman.conf \
        --gpgdir ${__root}/etc/pacman.d/gnupg \
        $@
}

ask_go "[ setup wifi-at-boot ( !! : this will move around /etc/pacman.d/mirrorlist) ]"
if [ "$ask_go_go" == "true" ] ; then 

        # Modify temporarily the siglevel for the guest system
    sed 's|SigLevel    = .*|SigLevel    = Never|' -i ${__root}/etc/pacman.conf
    
        # We need the arch linux arm mirrorlist 
    bakfile=/etc/pacman.d/mirrorlist.$(timestamp).bak
    cp /etc/pacman.d/mirrorlist "$bakfile"
    cp ${__root}/etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist
    
        # Install networkmanager
    chrootman -Sy
    chrootman -S  wpa_actiond
    
        # autostart on boot
    ln -sf ${__root}/usr/lib/systemd/system/netctl-auto@.service ${__root}/etc/systemd/system/netctl-auto@wlan0.service
    
    
    wifi_profile=$(echo "\
        Description='WiFi - SSID'
        Interface=wlan0
        Connection=wireless
        Security=none
        ESSID=Livebox-3970
        IP=dhcp" \
    | sed 's|    ||')
    
    echo "$wifi_profile" > root/etc/netctl/wlan0-SSID
    
        # Restore
    cp "$bakfile" /etc/pacman.d/mirrorlist
    sed 's|SigLevel    = .*|SigLevel    = Required DatabaseOptionali|' -i ${__root}/etc/pacman.conf
fi 
