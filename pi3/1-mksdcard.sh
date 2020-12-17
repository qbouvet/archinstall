#!/usr/bin/env bash
if [ $# -gt 0 ] && { [ "$1" == "-h" ] || [ "$1" == "--help" ] ;} ; then
printf "

    mksdcard.sh
    ===========
  
  Create a arch linux sd card for raspbarry pi. 
  
  - Do not run this script without reading it
  - Configure this script using '0-config.sh' 
  - Do not pass any command line argument to this script - they are 
    added automatically to run the different stages of the script. You 
    might break something. 
  - The only exception to the above is --noconfirm
  
  Usage : $0
  
"
return 0
fi


#
#   Initial setup, imports, requires
#

# Usual bash flags
set -euo pipefail   # Exit on 1/ nonzero exit code 2/ unassigned variable 3/ pipe error
shopt -s nullglob   # Allow null globs
#set -o xtrace      # Show xtrace  

# Root
[ "$UID" -eq 0 ] || exec sudo bash "$0" "$@";

# Set execution directory
__dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)";
pushd "$__dir" 2>&1 >/dev/null;

# Source helpers & configuration
source "${__dir}/0-config.sh"
source "${__dir}/0-utils.sh"


#
#   Default arguments, CLI arguments parsing, Initialization
#
#   !! CLI arguments are automatically generated, NEVER pass CLI 
#   arguments by hand (except --noconfirm)
#
declare -A params
params["stage"]="populate"
params["skip_bd_check"]="false"
params["reportfile"]="$__dir/report.txt"
params["reportclear"]="true"
params["noconfirm"]="false"
aa.argparse params ${@:1}
#aa.pprint params

if [[ "${params[reportclear]}" = "true" ]]; then 
    report.clear
    params["reportclear"]="false"
fi
#report.append "stage is ${params[stage]}\n\n"

function blockdev_check () {
    lsblk 
    printf "\nSelected block device is ${blockdev}.\n[enter] to confirm \n";
    read -r;
}
if [[ "${params[skip_bd_check]}" = "false" ]]; then 
    printf "  Double-check block device...\n"
    blockdev_check | indent 4
    params["skip_bd_check"]="true"
    printf "  Done\n\n"
fi 

function remount () {
  # Unmount both 
    [[ $(mount | grep "report.txt") ]] \
      && umount $(mount | grep "report.txt" | awk '{print $3}')
    [[ $(mount | grep "${bootpart}") ]] \
      && umount $(mount | grep "${bootpart}" | awk '{print $3}')
    [[ $(mount | grep "${rootpart}") ]] \
      && umount $(mount | grep "${rootpart}" | awk '{print $3}')
  # Remount root file system  
    mkdir -p "$rootmnt";
    mount "${rootpart}" "$rootmnt"; # [[ $(mount | grep "${rootpart}") ]] || 
  # Remount boot directly into root file system 
    mkdir -p "$rootmnt/boot";
    mount "${bootpart}" "$rootmnt/boot"; # [[ $(mount | grep "${bootpart}") ]] || 
    lsblk | indent 2;
    sleep 1s;
}



#
#   Populate stage: Get the base file system onto the SD card
#

function download_image () {
    if [ -f "$alarm_archive" ] ; then
        printf "Linux image found on disk\n\n"
    else
        printf "Linux image not found on disk\n"
        printf "downloading... \n\n"
        wget "$alarm_archive_url" | indent 2
        wget "$alarm_archive_md5" | indent 2
    fi
    if ! md5sum --status -c "${alarm_archive}.md5" ; then
        printf "Image checksum mismatch"
        printf "Exiting\n\n"
        exit 255
    else
        printf "Checksum matches\n\n"
    fi
}

function partition () {
  # Unmount partitions from selected device, if mounted
    printf "Unmounting...\n"
    mountpoints=$( \
        cat /proc/mounts \
        | grep "$blockdev" \
        | awk '{print  $2; }' \
        || [ $? == 1 ] \
    )   # [ $? == 1 ] === don't exit if grep returns 1
    if [ "$mountpoints" != "" ] ; then
        while read -r mountpoint ; do
            echo "  $mountpoint"
            umount "$mountpoint"
        done <<< "$mountpoints";
    fi
  # Create partitions
    printf "Creating partition table...\n"
    parted --script "$blockdev" \
        mklabel msdos \
        mkpart primary fat16  "${boot_part_start}" "${boot_part_end}" \
        mkpart primary ext4 "${root_part_start}" "${root_part_end}" \
        set 1 boot on \
        | indent 8;
  # Format partitions
    printf "Formatting... \n"
    printf "  ${bootpart}... \n"
    echo "y" | sudo mkfs.vfat "${bootpart}" | indent 12 ;
    sleep 2s
    printf "  ${rootpart}...\n"
    echo "y" | sudo mkfs.ext4 "${rootpart}" 2>&1 | indent 12 ;
}

function extract_fs () {
  # Check parameters
    if [ ! -f "$alarm_archive" ] ; then
        echo "Arch linux ARM archive not found, exiting"; exit 1
    fi
  # Extract root file system
    printf "Extracting root file system...\n"
    pushd "$rootmnt" > /dev/null 2>&1;
  # redirect stderr to allow grep to filter error messages
    tar -xf "../${alarm_archive}" 2>&1 | grep -v 'SCHILY.fflags' | indent 2
    popd > /dev/null 2>&1;
  # Populate boot partition
    #printf "    Populating /boot...\n"
    #cp -r -a "${rootmnt}/boot"/* "${bootmnt}/";
    #mv "${rootmnt}/boot"/* "${bootmnt}/";
  # flush before return
    printf "Flushing IO ($(timestamp))... \n"
    sync
  # Remount boot partition  
    #printf "    Remounting /boot...\n"
    #umount "${bootmnt}" 
    #mount "${blockdev}1" "${rootmnt}/boot/" # !! mmcblk -> add p1 / p2, sdb    -> add 1  / 2
  # Feedback  
    lsblk | indent 2
    sleep 1s
    printf "IO complete ($(timestamp))\n\n"
}

function cp_files () { 
    pushd "${__dir}/data" > /dev/null
    report.append "The following arbitrary files have been copied over:\n"
    for filename in *
    do
        if [ "${filename:0:3}" == "___" ]
        then
          newpath=${filename/___/}      # remove the first '___'
          newpath=${newpath//___/\/}    # replace all subsequent '___' by '/'
          mkdir -p "$(dirname "${rootmnt}/${newpath}")"
          cp "$filename" "${rootmnt}/${newpath}"
          report.append "  - $newpath\n"
        else
          printf "    Skipping $filename\n"
        fi
    done
    popd > /dev/null
    sync
}

function populate () {
    printf "  Download Arch Linux Arm image...\n"
    download_image | indent 4
    printf "  Done\n\n"
    printf "  Partition SD card \n"
    partition | indent 4
    printf "  Done\n\n"
    printf "  Mount partitions SD card...\n"
    remount | indent 4
    printf "  Done\n\n"
    printf "  Extract file system...\n"
    extract_fs | indent 4
    printf "  Done\n\n"
    printf "  Copy arbitrary files...\n"
    cp_files
    printf "  Done\n\n"
}

[[ "${params[stage]}" == "populate" ]] && \
  ask_go "Format and populate SD card" populate;



#
#   Chain the configure stage
#
function chain_in_chroot () { 
    aa.pprint params
  # Remount if skipped previous step
    printf "  Remount...\n"
    remount | indent 2
    printf "  Done\n\n"
  # Copy the installation scripts into the rootfs for reference  
    mkdir -p "${rootmnt}/install"
    cp ./*.sh "${rootmnt}/install/"
  # Bind-mount file for reporting  
    touch "$rootmnt"/report.txt
    mount --bind "${params[reportfile]}" "$rootmnt"/report.txt
  # Chroot and call script again  
    arch-chroot "${rootmnt}" "./install/$0" \
      --stage configure \
      --reportfile "/report.txt" \
      --reportclear "false" \
      --skip-bd-check "${params[skip_bd_check]}" \
      --noconfirm "${params[noconfirm]}"
  # Unbind the reporting file, else mnt/ "target is busy"
    umount "$rootmnt"/report.txt
}

[[ "${params[stage]}" == "populate" ]] && \
  ask_go "Chroot and configure ?" chain_in_chroot;



#
#   Configure stage: runs in chroot
#
#   See: 
#     https://wiki.archlinux.org/index.php/QEMU#Chrooting_into_arm/arm64_environment_from_x86_64
#     https://lexruee.ch/customizing-an-arch-arm-image-using-qemu.html   
#
function user_setup () {
    report.append "  Users\n"
  # new root password
    printf "$rootpw\n$rootpw" | passwd ;  # root password
    report.append "    Root password has been changed: $rootpw"
  # new user, if doesn't exist
    ret=0; id -u "$username" &> /dev/null || ret=$?;
    if [[ $ret -ne 0 ]]; then 
        useradd -m -g users -G wheel "$username";
        printf "$userpw\n$userpw" | passwd "$username";
        chown -R "$username":users "/home/${username}"
        report.append "    User created: $username:$userpw"
    fi 
  # fix permissions
    chown -R "$username:users" "/home/$username";
    chown -R "$username":users /opt;
  # remove default user, if exists
    ret=0; id -u alarm &> /dev/null || ret=$?
    if [[ $ret -eq 0 ]]; then 
        userdel alarm;
        rm -rf /home/alarm;
        report.append "    Default user removed: alarm:alarm"
    fi 
}

function systemd_services () {
    systemctl enable run-at-boot.sh
}

function conf_network () {
    fOverwrite "/etc/hostname" "$hostname";
    # https://ladvien.com/installing-arch-linux-raspberry-pi-zero-w/
    fOverwrite "/etc/hostname" "$hostname";
    fOverwrite "/etc/systemd/network/wlan0.network" "\
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
    \n
    "
}

function conf_ssh () {
    # Forbid root login
    fComment "/etc/ssh/sshd_config" "PermitRootLogin"
    fAppend "/etc/ssh/sshd_config" "\nPermitRootLogin no\n"
    # Except root, every user can login     
    fOverwrite "/etc/hosts.allow" "sshd : ALL : allow"
    # Change the default port
    mkdir -p "/etc/systemd/system/sshd.socket.d/"
    fOverwrite "/etc/systemd/system/sshd.socket.d/override.conf" "\
        [Socket]
        ListenStream=
        ListenStream=${ssh_port}
    "
    # Something about X11 forwarding 
    #fUncomment "${rootmnt}/etc/ssh/sshd_config" "X11Forwarding"
    report.append "\
    ssh:
        1.  Root login no longer allowed
        2.  All non-root users can login
        3.  Port is ${ssh_port} 
    \n    
    "   
}

function conf_locale () { 
    fUncomment "/etc/locale.gen" "en_US.UTF-8 UTF-8"
    locale-gen;
    fOverwrite "/etc/locale.conf" "LANG=en_US.UTF-8"
    localectl set-locale LANG=en_US.UTF-8;    
    report.append "\
    Locale:
        en_US.UTF-8
    \n    
    "   
} 

function pacman_setup () {
  # Initial setup - NB: mirrors are arm-specific - don't change them
    sed -i 's/#Color/Color/' /etc/pacman.conf
    pacman-key --init  
    pacman-key --populate archlinuxarm 
    pacman --noprogressbar --noconfirm -Syu
    pacman --noprogressbar --noconfirm -S pacutils
  # Update and install packages  
    pacinstall --noconfirm --install "${packages[@]}" 
  # wipe cache, save space
    pacman --noconfirm -Scc 
}

function conf_sudo {    #   Probably requires pacman
    fAppend "/etc/sudoers" "\n
      #  
      # Allow all wheel users to use sudo
      #
      %%wheel ALL=(ALL) ALL"    
}

function yay_setup () { #   Requires sudo / pacman
  # Fakeroot doesn't work under qemu chroot
    # https://archlinuxarm.org/forum/viewtopic.php?f=57&t=14466
    # https://aur.archlinux.org/packages/fakeroot-tcp/
    # https://www.reddit.com/r/archlinux/fComments/7rycmu/cannot_build_fakeroottcp_without_fakeroot/
  # Compile fakeroot-tcp from source
    wget http://ftp.debian.org/debian/pool/main/f/fakeroot/fakeroot_1.23.orig.tar.xz
    tar xvf fakeroot_1.23.orig.tar.xz
    cd fakeroot-1.23/
    ./bootstrap
    ./configure --prefix=/opt/fakeroot-tcp \
      --libdir=/opt/fakeroot-tcp/libs \
      --disable-static \
     --with-ipc=tcp
    make 
    make install 
  # compile "package-manager" fakeroot-tcp using "from-source" fakeroot-tcp
    PATH="/opt/fakeroot-tcp/bin/:${PATH}" manual_aur_install fakeroot-tcp \
      && rm -rf /opt/fakeroot-tcp
  # Arch building system should now work 
    manual_aur_install yay
}

function yay_packages () {
  # Temporarily need sudo without password  
    fAppend "/etc/sudoers" "\n
        #  
        # Allow user to run all commands without password
        #
        $username ALL=(ALL) NOPASSWD: ALL"
  # Install AUR packages
    sudo -u "$username" yay --noconfirm -S "${aur_packages[@]}" 
  # Revert sudo without password
    fComment "/etc/sudoers" "$username ALL=(ALL) NOPASSWD: ALL"
}

function conf_time () { #   Requires pacman
    # Timezone
    ln -sf "$timezone" /etc/localtime
    # Enable NTP
    timedatectl set-ntp true
    pacman --noconfirm -S ntp fake-hwclock
    systemctl enable ntpd.service
    report.append "\
    Time:
        Timezone configured
        NTP enabled
    \n    
    "
} 

function conf_swap () { #   Requires pacman
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
  # zswap / swapfc
    pacman --noconfirm -S systemd-swap
    mkdir -p /var/lib/systemd-swap/swapfc
    systemctl enable systemd-swap
  # Swappiness
    fOverwrite "/etc/sysctl.d/99-sysctl.conf" "vm.swappiness=$swappiness\n"
    # https://haydenjames.io/linux-performance-almost-always-add-swap-part2-zram/
    fAppend "/etc/sysctl.d/99-sysctl.conf" "vm.vfs_cache_pressure=$vfs_cache_pressure\n"
    fAppend "/etc/sysctl.d/99-sysctl.conf" "vm.dirty_background_ratio=1\n"
    fAppend "/etc/sysctl.d/99-sysctl.conf" "vm.dirty_ratio=50\n"
}

function configure () {
    printf "  Architecture:\n    $(uname -m)\n  Done\n\n";
    printf "  User management\n"
    #user_setup 2>&1 | indent 4
    printf "  Done\n\n"
    printf "  Misc systemd services\n"
    #systemd_services 2>&1 | indent 4
    printf "  Done\n\n"
    printf "  Network\n"
    #conf_network 2>&1 | indent 4
    printf "  Done\n\n"
    printf "  SSH\n"
    #conf_ssh 2>&1 | indent 4
    printf "  Done\n\n"
    printf "  Locale\n"
    #conf_locale 2>&1 | indent 4
    printf "  Done\n\n"
    printf "  Install packages (pacman)... \n"
    #pacman_setup 2>&1 | indent 4
    printf "  Done\n\n"
    printf "  Configure sudo\n"
    #conf_sudo 2>&1 | indent 4
    printf "  Done\n\n"
    printf "  Install yay...\n"
    #yay_setup 2>&1 | indent 4
    printf "  Done\n\n"
    printf "  Install packages (yay)...\n"
    yay_packages 2>&1 | indent 4
    printf "  Done\n\n"
    printf "  Time\n"
    conf_time 2>&1 | indent 4
    printf "  Done\n\n"
    printf "  Swap\n"
    conf_swap 2>&1 | indent 4
    printf "  Done\n\n"
}

[[ "${params[stage]}" == "configure" ]] \
  && configure



#
#   Exit sequence
#
function cleanup () {  
    sync; 
    umount "$rootmnt/report.txt";  
    umount "$rootmnt/boot";  
    umount "$rootmnt"; 
    sleep 2s; 
    lsblk
}

[[ "${params[stage]}" == "populate" ]] \
  && ask_go "Cleanup ?" cleanup

[[ "${params[stage]}" == "populate" ]] \
  && report.produce

popd 2>&1 >/dev/null
exit 0;


