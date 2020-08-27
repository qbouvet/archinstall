#!/usr/bin/env bash

#
#       rpi0/0-config.sh
#       ================
#
#   Holds the variables for all scripts, gets source'd
#



  # 1-mksdcard.sh
  #
export blockdev="/dev/mmcblk0"  # !! needs a p when mmcblk
export alarm_archive="ArchLinuxARM-rpi-latest.tar.gz"

export boot_part_start="2048s"   # s2048 -> s206857 = 100MB with 512b sectors
export boot_part_end="411647s"   # s2048 -> s411647 = 200MB with 512b sectors
export root_part_start="411648s"
export root_part_end="100%"

export __dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)";
export __root="${__dir}/mnt-rootfs";
export __boot="${__dir}/mnt-boot";

export wifi_ssid="Livebox-3970"               # This can also be done with data/
export wifi_psk="0641EC23A6F80E7F483AFF525E"  #

export hostname="pizero"
export ssh_port="22"



  # 2-setup-system.sh
  #
# Users and root
export rootpw="pizero"
export username="quentin"
export userpw="pizero"

# Pacman setup
export packages=(
        # "base base-devel",but smaller
    binutils fakeroot patch gcc make autoconf automake #base base-devel
        # Firmwares
    alarm/firmware-raspberrypi alarm/libbcm2835
        # utilities
    core/sudo htop
        # Server
    python python-tornado
        # For aurman
    git expac python-requests pyalpm python-regex  python-dateutil python-feedparser
        # Not needed : use wpa_supplicant
    #extra/networkmanager extra/dnsmasq
        # No longer needed server for communication
    # community/python-flask community/python-flask-script community/python-flask-talisman
        # (?) https://github.com/waveform80/pistreaming
    #python-picamera libav
);
export packages_aur=(
        # Only those are strictly needed
    python-picamera python-raspberry-gpio
        # These are independant projects
    #python-ws4py motion
        # these are duplicates of python-raspberry-gpio
    #python-rpi.gpio python-pigpio-git
        # (?) https://github.com/waveform80/pistreaming
    # libav-no-libs -> build libav from source, libav-no-libs not armv6h compatible
)

    # swap
export swapfile_size="1G";
export swapfile_path=/swap_"$swapfile_size";
export swappiness="20";




## 3-setup-user.sh
##














########################################################################
#########################    FUNCTIONS    ##############################
########################################################################


  # Control flow function
  #
function ask_go {
    if [ "$#" -lt 0 ] ; then
        echo "Error: Missing argument"
        return
    fi
    ask="===> $1"
    [ -x "$(command -v notify-send)" ] && notify-send --icon=terminator "$ask";
    printf "\n\n$ask";
    passedFunction=$2
    input=''
    while [ "true" ] ; do
        printf "\n===> [ go | skip | stop ] \n===> " ; read input
        case "$input" in
        ("go")      echo ""
                    $passedFunction
                    echo "Done !"
                    return 0;;
        ("skip")    echo "Skipping"
                    return 0;;
        ("stop")    echo "Exiting"
                    exit 0;;
        (*)         echo " ? ($input) ";;
        esac
    done
}

  # Add indentation to stdin input
function indent () {
    amount="${1:-4}"
    prefix=""
    IFS=''
    while [ "$amount" -gt 0 ]
    do
      prefix="${prefix} "
      amount=$((amount-1))
    done
    while read -r line ; do
      #printf "${prefix}${line}\n"
      echo "${prefix}${line}"
    done < /dev/stdin
}

  # AUR installer. Automates downloading, extracting and calling makepkg.
  # Args : $1  link to the AUR snapshot
  #        $2+ passed to makepkg (use it for --skippgpcheck)
  #
function aur_install () {
    _user="quentin"
    _package="$1"
    _builddir="/tmp/build"
    _gitlink="https://aur.archlinux.org/${_package}.git"
    [ ! -e "$_builddir" ] && mkdir -p "$_builddir"
    pushd "$_builddir"
    rm -rf "$_package"
    printf "\n\nCloning...\n"
    git clone "$_gitlink" | indent
    chmod 777 -R "$_builddir/$_package"
    cd "$_package"
    printf "\n\nBuilding...\n"
    sudo -u "$_user" makepkg "${@:2}"
    printf "\n\n... Installing\n"
    pacman -U "$_package"*.tar.xz --noconfirm
    printf "\n\nDone\n"
    popd
}


  #  Misc helpers for readability
  #

function timestamp {
    date +%Y%m%d_%H%M%S
}

  # overwrite the content of a file
function overwrite () {
    _file="$1"
    _text="$2"
    printf "$_text" | sed 's:    ::g' > "$_file"
}

  # overwrite the content of a file
function append () {
    _file="$1"
    _text="$2"
    printf "$_text" | sed 's:    ::g' >> "$_file"
}

  # Append to the last line (!: No new line)
function appendToLine () {
    _file="$1"
    _text="$2"
    sed "\$s/\$/${_text}/" -i "$_file"
}

  # Find and comment all instances
function comment () {
    _file="$1"
    _text1="$2"
    _text2="#$2"
    sed "s|${_text1}|${_text2}|g" -i "$_file"
}

  # Find and uncomment all instances
function uncomment () {
    _file="$1"
    _text1="#$2"
    _text2="$2"
    sed "s|${_text1}|${_text2}|g" -i "$_file"
}
