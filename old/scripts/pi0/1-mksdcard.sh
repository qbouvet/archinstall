#!/usr/bin/env bash


  #
  #   Initial setup, imports, requires
  #
set -o nounset      # exit on unassigned variable
set -o errexit      # exit on error
set -o pipefail     # exit on pipe fail
# Acquire root
[ "$UID" -eq 0 ] || exec sudo bash "$0" "$@";
# Set execution directory
export __dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)";
pushd "$__dir";
# Source variables
source "${__dir}/0-config.sh"




  #  Report - Write throughout execution and print it at the end
  #
report="REPORT :"


  #  Verify block device path
  #
function verify_paths () {
    printf " \n
Please verify your target block device:\n
"
    lsblk | indent 8
    printf "
 ( ! )  Selected block device is ${blockdev}.
 ( ! )  [enter] to confirm \n ";
    read -r;
}
verify_paths




function download_image () {
    if [ -f "$alarm_archive" ] ; then
        printf "    Linux image found\n\n"
    else
        printf "    Linux image not found\n    ... downloading\n\n"
        wget http://os.archlinuxarm.org/os/ArchLinuxARM-rpi-latest.tar.gz | indent 8
        wget http://os.archlinuxarm.org/os/ArchLinuxARM-rpi-latest.tar.gz.md5 | indent 8
        #wget http://os.archlinuxarm.org/os/ArchLinuxARM-rpi-latest.tar.gz.sig
    fi
    if ! md5sum --status -c "${alarm_archive}.md5" ; then
        printf "    Linux image checksum doesn't match\n    exiting\n\n"
        exit 255
    else
        printf "    Checksum matches\n\n"
    fi
}
#ask_go "[Download linux image]" download_image;


function partition () {
  # Internal variables
    part1="${blockdev}p1" # !! mmcblk -> add p1 / p2
    part2="${blockdev}p2" # !! sdb    -> add 1  / 2
  # Unmount partitions from selected device, if mounted
    printf "    Unmounting...\n"
    mountpoints=$( \
        cat /proc/mounts \
        | grep "$blockdev" \
        | awk '{print  $2; }' \
        || [ $? == 1 ] \
    )   # [ $? == 1 ] === don't exit if grep returns 1
    if [ "$mountpoints" != "" ] ; then
        while read -r mountpoint ; do
            echo "        $mountpoint"
            umount "$mountpoint"
        done <<< "$mountpoints";
    fi
    printf "    Done\n\n";
  # Some feedack
    lsblk | indent 4;
    sleep 1s;
  # Create partitions
    printf "    Creating partition table... \n"
    parted --script "$blockdev" \
        mklabel msdos \
        mkpart primary fat16  "${boot_part_start}" "${boot_part_end}" \
        mkpart primary ext4 "${root_part_start}" "${root_part_end}" \
        set 1 boot on \
        | indent 8;
    printf "    Done\n\n"
  # Format partitions
    printf "    Formatting... \n"
    printf "        ${part1}... \n"
    echo "y" | sudo mkfs.vfat "${part1}" | indent 12 ;
    sleep 2s
    printf "        ${part2}...\n"
    echo "y" | sudo mkfs.ext4 "${part2}" 2>&1 | indent 12 ;
    printf "    Done\n"
  # Remount SD card
    printf "    Mounting... \n"
    mkdir -p "$__boot";
    mkdir -p "$__root";
    mount "${part1}" "$__boot";
    mount "${part2}" "$__root";
    printf "    Done\n"
  # Some feedback
    lsblk | indent 4;
    sleep 1s;
}
#ask_go "[Unmount / Partition / Format / Remount]" partition;


function extract_fs () {
  # Check parameters
    if [ ! -f "$alarm_archive" ] ; then
        echo "Arch linux ARM archive not found, exiting"; exit 1
    fi
  # Extract root file system
    echo "    Extracting root file system... "
    pushd "$__root" > /dev/null 2>&1;
  # redirect stderr to allow grep to filter error messages
    tar -xf "../${alarm_archive}" 2>&1 | grep -v 'SCHILY.fflags' | indent 8
    popd > /dev/null 2>&1;
  # Populate boot partition
    echo "    Populating /boot... "
    mv "${__root}/boot"/* "${__boot}/";
  # flush before return
    echo "    Flushing IO ($(timestamp))... "
    sync;
    echo "    Done ($(timestamp)) "
}
#ask_go "[Extract filesystems]" extract_fs;


  # All of the above
  #
function populate () {
    printf "    Download Arch Linux Arm image\n"
    download_image
    printf "    Partition SD card \n"
    partition
    printf "    Extract file system \n"
    extract_fs
}
ask_go "Format and populate SD card" populate;




function conf_eth_over_usb () {
    append "${__boot}/config.txt" "dtoverlay=dwc2"
    appendToLine "${__boot}/cmdline.txt" " modules-load=dwc2,g_ether"
    overwrite "${__root}/etc/systemd/network/usb0.network" "\
        [Match]
        Name=usb*
        \n[Network]
        #DHCP=yes               # Use either DHCP or Address/Gateway/DNS
        Address=10.0.0.101/24
        Gateway=10.0.0.1
        DNS=10.0.0.1            # Needed for internet connectivity
        DNS=8.8.8.8             #
    "
    overwrite "${__root}/etc/hostname" "$hostname";
    report="${report}\n
    Ethernet over USB:
        1.  Plug the micro-usb cable into the pi0 USB (not PWR) socket and the
            other end into your linux computer
        2.  Create a shared wired connection from your linux computer, where:
              - The network mask is 10.0.0.0/24
              - Your computer is 10.0.0.1/24
        3.  The pi0 is reachable at :
              - alarm@$hostname is your router resolves hostnames
              - alarm@10.0.0.1/24 if you're using the static ip configuration
              - if using DHCP, use 'nmap -sP 10.0.0.1/24' \
    "
}
#ask_go "[Ethernet over USB]" eth_over_usb


function conf_ssh () {
    mkdir -p "${__root}/etc/systemd/system/sshd.socket.d/"
    overwrite "${__root}/etc/systemd/system/sshd.socket.d/override.conf" "\
        [Socket]
        ListenStream=
        ListenStream=${ssh_port}
    "
    append    "${__root}/etc/ssh/sshd_config" "\n\nPermitRootLogin yes\n"
    uncomment "${__root}/etc/ssh/sshd_config" "X11Forwarding"
    overwrite "${__root}/etc/hosts.allow" "sshd : ALL : allow"
    report="${report}\n
    ssh:
        1.  ALL USERS ARE ALLOWED, INCLUDING ROOT
            Change this after running the setup-system.sh
        2.  Port is ${ssh_port} \
    "
}
#ask_go "[ssh]" ssh


function conf_wifi () {
  echo 1
    # https://ladvien.com/installing-arch-linux-raspberry-pi-zero-w/
    overwrite "${__root}/etc/hostname" "$hostname";
    overwrite "${__root}/etc/systemd/network/wlan0.network" "\
        [Match]
        Name=wlan0
        [Network]
        DHCP=yes
    "
    overwrite "${__root}/etc/wpa_supplicant/wpa_supplicant-wlan0.conf" "
        $(wpa_passphrase ${wifi_ssid} ${wifi_psk})
    "
    if [ ! -e "${__root}/etc/systemd/system/multi-user.target.wants/wpa_supplicant@wlan0.service" ]
    then
        ln -s \
            "${__root}/usr/lib/systemd/system/wpa_supplicant@.service" \
            "${__root}/etc/systemd/system/multi-user.target.wants/wpa_supplicant@wlan0.service"
    fi
    report="$report\n
    network:
        1.  Hostname is ${hostname}
        2.  Wifi \'${wifi_ssid}\' has been configured
    "
    # For reference:
    #network={
    #  ssid="eduroam"
    #  key_mgmt=WPA-EAP
    #  proto=WPA2
    #  eap=TTLS
    #  identity="GASPAR_LOGIN@epfl.ch"
    #  password="GASPAR_PASS"
    #  anonymous_identity="anonymous@epfl.ch"
    #  phase2="auth=MSCHAPV2"
    #  #ca_cert="/etc/ssl/certs/Thawte_Premium_Server_CA.pem"
    #  #ca_cert2="/etc/ssl/certs/Thawte_Premium_Server_CA.pem"
    #  subject_match="CN=radius.epfl.ch"
    #  priority=30
    #}
}
#ask_go "[Setup wifi ? (=== wpa_supplicant)]" wifi;


function conf_copydata () {
  # Next scripts
    pushd "${__dir}" > /dev/null
    mkdir "${__root}/install"
    for name in ?-*.sh
    do
        cp "$name" "${__root}/install/"
    done
    popd > /dev/null
  # Extra data
    pushd "${__dir}/data" > /dev/null
    for filename in *
    do
        if [ "${filename:0:3}" == "___" ]
        then
          newpath=${filename/___/}      # remove the first '___'
          newpath=${newpath//___/\/}    # replace all subsequent '___' by '/'
          mkdir -p "$(dirname "${__root}/${newpath}")"
          cp -r "$filename" "${__root}/${newpath}"
        else
          printf "    Skipping $filename\n"
        fi
    done
    popd > /dev/null
  # Setup watchbot-static - kinda ugly
    pushd /opt > /dev/null
    [ -e watchbot ] && rm watchbot
    ln -s watchbot-static watchbot
    popd > /dev/null
}
#ask_go "Copy additionnal data" copydata;


  # All of the above
  #
function configure () {
  printf "\n    Configure ethernet over USB \n"
  conf_eth_over_usb
  printf "\n    Configure SSH \n"
  conf_ssh
  printf "\n    Configure Wifi connectivity \n"
  conf_wifi
  printf "\n    Copy addditional data \n"
  conf_copydata
}
ask_go "[eth-over-usb / ssh / wifi / additionnal data]" configure;




  # Unmount and exit
  #
function unmount () {
    umount "$__boot"; rmdir "$__boot";
    umount "$__root"; rmdir "$__root";
    lsblk | indent
}
ask_go "Unmount sdcard" unmount

report="$report\n
    System:
        1.  $0 completed successfully
        2.  Default credentials are 'alarm/alarm', 'root/root'
        3.  You should now ssh into the system and run './setup-system.sh' \
"

printf "\n\n$report\n\n"
popd > /dev/null 2>&1
exit 0;























########################################################################
#######################    LEGACY CODE    ##############################
########################################################################
## For reference later


echo "You've reached deprecated code";
exit 0;



## Copy over networkmanager connection profiles
## HANDLED BY WPA_SUPPLICANT
##
ask_go "[Copy over NetworkManager profiles]\nHANDLED BY WPA SUPPLICANT"
if [ "$ask_go" == "true" ] ; then

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
if [ "$ask_go" == "true" ] ; then

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
