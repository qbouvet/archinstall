#!/usr/bin/env bash

#
#   Holds the variables for alk the scrips, get source'd
#

## 1-base-install.sh
##
export dev_disk="/dev/sda"
export dev_root="/dev/sda1"     # Block dev for root system partition


## 2-in-chroot.sh
##
export hostname="quentin-e6400-arch"
export username="quentin"
export swap_file_size="6G"             # Size of swap file  !! include unit !! 
export swap_file_path=/SWAP_"$swap_file_size"
export swappiness="20"          
export packages=(
        # pacman base stuff
    pacman-contrib
        # Network
    dialog networkmanager network-manager-applet dnsmasq bluez bluez-utils blueman 
        # Sound
    alsa-utils pulseaudio pulseaudio-alsa pulseaudio-bluetooth 
        # Graphics driver
    extra/nvidia-340xx-dkms extra/opencl-nvidia-340xx multilib/lib32-nvidia-340xx-utils multilib/lib32-opencl-nvidia-340xx
        # xorg
    xorg-server xorg-apps xorg-xinit xorg-xauth xorg-xhost 
        # Desktop environment
    openbox tint2 midori gpicview terminator synapse tilda geany scribes libreoffice gummi vlc evince
    xfce4-taskmanager gnome-screenshot xfce4-notifyd obmenu obconf lxappearance
    adwaita-icon-theme elementary-icon-theme cantarell-fonts ttf-droid imwheel
    lxinput polkit lxsession 
    pcmanfm gvfs udisks2     
        # basic Utilities
    tlp gparted baobab arandr hdparm sudo git git-lfs wget bc htop lm_sensors xsensors ntfs-3g p7zip file-roller 
        # Network/server services
    samba tigervnc openssh openconnect syncthing syncthing-gtk 
        # codecs
    gstreamer gst-plugins-base gst-libav gst-plugins-good gst-plugins-ugly gst-plugins-bad 
)
export packages_aur=(
    vivaldi
    opensnap-quicktiles
    xcalib 
    gst-plugin-libde265 libde265 
    grub-customizer
    gtk-theme-adwaita-tweaks
    obkey
)


## 4-vnc-ssh-samba.sh
##
sshport="14444"
samba_user="samba-user"
root_ssh_key="/root/.ssh/sffpc-root-key"
ip_repo_path="/root/ip-git"
ip_file="$ip_repo_path"/sffpc.ip
repo_upstream="git@github.com:sgPepper/ip.git"
git_mail="quentin.bouvet@hotmail.fr"
git_name="Quentin Bouvet"







    # Control flow function used everywhere
    #
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
    package : \t\t	$_packagename
    go ?\n\n"
    read; sleep 2s; 
        # create build directory
    mkdir -p /build; pushd /build
    sudo chown -R "$_user":users .
        # download pkgbuild
    wget "$_snapshotlink"
    tar -xvf "$_archive"
    pushd "$_packagename"
        # Build and install
    sudo -u "$_user" makepkg "${@:2}"
    sudo pacman -U "$_packagename"*.tar.xz
        # clean and exit
    popd; sudo rm -rf "$_packagename"
    popd;
    return 0
}   



    # $1 pattern
    # $2 replacement
    # $3 file
function subst {
	sed "s|$1|$2|" -i "$3"
}



