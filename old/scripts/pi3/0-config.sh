#!/usr/bin/env bash

#
#   Holds the variables for all scripts, gets source'd
#



## 1-mksdcard.sh
##
export blockdev="/dev/sdb"
export alarm_archive="ArchLinuxARM-rpi-3-latest.tar.gz"

export rootfs_start="206848s";  # Don't forget to specify the units (s, %, ...)
#export rootfs_end="30881791s";  # 16G sdcard
export rootfs_end="100%";

export __dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)";
export __root="$__dir"/mnt-rootfs;
export __boot="$__dir"/mnt-boot;

export wifi_ssid="Livebox-3970"
export wifi_wpapass="0641EC23A6F80E7F483AFF525E"
export nm_profiles_dir="data-networkmanager-profiles"
export wifi_mac_addr="B8:27:EB:EF:87:F8";   # board's Wi-fi chip mac address - PI3

export hostname="pi3b-server"
export ssh_port="22"



## 2-setup-system.sh
##
    # Users and root 
export rootpw="pithreeb"
export username="quentin"
export userpw="pithreeb"

    # Pacman setup
export packages=(
        # core stuff
    base 
    base-devel
    core/sudo 
    alarm/firmware-raspberrypi 
    alarm/libbcm2835 
    pacman-contrib      # paccache
        # networks
    extra/networkmanager
    extra/networkmanager-openconnect 
    extra/networkmanager-openvpn
    extra/dnsmasq
    extra/bluez
    extra/bluez-utils
        # syncthings
    community/syncthing
    community/syncthing-relaysrv
        # utilities
    wget 
    htop
    extra/git 
    cmake
        # aurman
    expac 
    python-requests 
    pyalpm 
    python-regex  
    python-dateutil 
    python-feedparser

);
export packages_aur=(
        # camera stuff
    python-rpi.gpio
    python-raspberry-gpio 
    python-pigpio-git
)

    # swap
export swapfile_size="2G";
export swapfile_path=/swap_"$swapfile_size";
export swappiness="20";




## 3-setup-user.sh
##














########################################################################
#########################    FUNCTIONS    ##############################
########################################################################



## Control flow function used everywhere
##
function ask_go {
    ask="ask_go() : "
    if [ "$#" -gt 0 ] ; then
        ask=$1
    fi
    [ -x "$(command -v notify-send)" ] && notify-send --icon=terminator "$ask";
    printf "\n\n$ask";
    
    if [ "$#" -gt 1 ] ; then
    # new way : the caller passes to ask_go() a function to be called
        passedFunction=$2
        input=''
        while [ "true" ] ; do
            printf "\n go | skip | stop > " ; read input
            case "$input" in 
            ("go")      $passedFunction
                        return 0;;
            ("skip")    echo "Skipping"
                        return 0;;
            ("stop")    echo "Exiting"
                        exit 0;;
            (*)         echo " ? ($input) ";;
            esac
        done
    else 
    # original way : we set the variables that will be used by the caller 
        input=''
        ask_go_go="false"
        ask_go_done="false"
        while [ "$ask_go_done" == "false" ] ; do
            printf "\n go | skip | stop > " ; read input
            case "$input" in 
            ("go")      ask_go_done="true"
                        ask_go_go="true";;
            ("skip")    ask_go_done="true"
                        ask_go_go="false";;
            ("stop")    ask_go_done="true"
                        ask_go_go="false"
                        exit 1;;
            (*)         echo " ? ($input) ";;
            esac
        done
        printf "\n"
    fi
}

function timestamp {
    date +%Y%m%d_%H%M%S
}


	# Ugly AUR installer. Automates downloading, extracting and calling makepkg.
	# Args : 	$1	link to the AUR snapshot
	#			$2+ passed to makepkg (use it for --skippgpcheck)
	#
function ugly_aur_install {
    _user="quentin"
    _snapshotlink="$1"
    _archive=$(echo "$_snapshotlink" | sed 's|https://aur.archlinux.org/cgit/aur.git/snapshot/||')
    _packagename=$(echo "$_archive" | sed 's|.tar.gz||')
    printf "
    snapshot link :\t$_snapshotlink
    archive : \t\t	$_archive
    package : \t\t	$_packagename\n\n"
        # create build directory
    mkdir -p /build; pushd /build
    chown -R "$_user":users .
        # download pkgbuild
    wget "$_snapshotlink"
    tar -xvf "$_archive"
    chown -R "$_user":users .
    pushd "$_packagename"
        # Build and install
    sudo -u "$_user" makepkg "${@:2}"
    sudo pacman -U "$_packagename"*.tar.xz
        # clean and exit
    popd; rm -rf "$_packagename"
    popd;
    return 0
}
