#!/usr/bin/env bash

#
#   Holds the variables for alk the scrips, get source'd
#

## Base installation
##
export dev_esp="/dev/sda1"      # Block dev for ESP
export dev_root="/dev/sda2"     # Block dev for root system partition


## in-chroot
##
export hostname="quentin-sffpc-arch"
export swap_file_size="10G"             # Size of swap file  !! include unit !! 
export swap_file_path=/SWAP_"$swap_file_size"
export swappiness="20"          
export mnt_esp="/boot/efi"              # Mountpoint for ESP (in chroot)
export packages=(
    pacman-contrib
    dialog networkmanager network-manager-applet dnsmasq bluez bluez-utils blueman 
    alsa-utils pulseaudio pulseaudio-alsa pulseaudio-bluetooth 
    nvidia nvidia-utils lib32-nvidia-utils lib32-nvidia-utils nvidia-settings
    xorg-server xorg-apps xorg-xinit
    openbox obconf lxinput polkit lxsession
    pcmanfm gvfs udisks2 
    #xfdesktop thunar
    tint2 firefox midori gpicview terminator synapse
    geany scribes libreoffice gummi vlc syncthing syncthing-gtk guake
    gparted baobab arandr p7zip file-roller steam  gimp xfce4-taskmanager
    cantarell-fonts ttf-droid gnome-screenshot redshift xfce4-notifyd adwaita-icon-theme elementary-icon-theme
    gstreamer gst-plugins-base gst-libav gst-plugins-good gst-plugins-ugly gst-plugins-bad 
    openssh hdparm sudo openconnect
    git git-lfs wget bc htop
    lm_sensors xsensors
    ntfs-3g
)
export packages_aur=(
    xcalib 
    gst-plugin-libde265 libde265 
    grub-customizer
    steam-fonts
    gtk-theme-adwaita-tweaks
    obkey
)






## Control flow function used everywhere
##
function ask_go {
    if [ "$#" -gt 0 ] ; then
        printf "\n\n$1"
    fi
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
        (*)         echo "?";;
        esac
    done
    printf "\n"
}

