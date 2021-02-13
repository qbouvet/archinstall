#!/bin/bash 

#
#   Generate package lists for arch install 
#
#   Usage: 
#     pacman -Syu $($0 system)
#     yay -Syu $($0 applications)
#


#	----- Pacstrap packages

pacstrap=(
	base base-devel 
	linux-lts linux-lts-headers 
	sudo git screen nano 	# Screen: https://gist.github.com/zigmoo/b67b11cd7bc8a5c66a44b91fcf37898e
)


#	----- Vendor-specific packages

sffpc=(
  amd-ucode nct6775-master-dkms-git   # AMD CPU 
  nvidia-dkms nvidia-settings         # Nvidia GPU
)
9470m=(
  intel-ucode thermald                # Intel CPU 
)
rv515=(
  amd-ucode nct6775-master-dkms-git   # AMD CPU 
  mesa xf86-video-ati mesa-vdpau      # AMD GPU
)
e6400=(
  intel-ucode thermald                # Intel CPU 
  nvidia-dkms nvidia-settings         # Nvidia GPU 
)
macbookair=(
  intel-ucode thermald                # Intel CPU 
  hid-apple-patched-git-dkms          # Apple keyboard mod
)
pi0=(
  firmware-raspberrypi libbcm2835
)
pi3=()
pi4=()


# ----- Temporary

export pizero_apps=(
  # Applications  
    pi-bluetooth                                # Powersave feature, maybe
    networkmanager
  # ...  
    modemmanager usb_modeswitch
)


# -----	Core packages

core_minimal=(
  # base / base-devel minimal equivalent
    pacman-mirrorlist
    autoconf automake binutils bison file findutils flex gawk gcc gettext grep groff gzip libtool m4 make pacman patch pkgconf sed sudo texinfo which
    # autoconf automake binutils fakeroot gcc make patch sudo 
  # Other core stuff
    man-db man-pages git pacman-contrib pacutils ntp fake-hwclock dnsmasq wget htop 
    po4a    # for fakeroot-tcp
    go      # for yay
)

core=(
  # Core packages
    linux-firmware
    systemd-swap ntp tlp 
    lm_sensors xsensors powertop
  # Core CLI utilities
    sudo nano git git-lfs gnu-netcat wget 
    openconnect openssh 
    pacman-contrib
  # Filesystems and disks
    udisks2 nvme-cli smartmontools hdparm
    exfat-utils ntfs-3g f2fs-tools dosfstools fatresize 
    ext4magic e2fsprogs     # badblocks, recovery
    apfsprogs-git           # AUR
  # Wireless, network
    networkmanager bluez
  # Sound
    alsa-utils
    pulseaudio pulseaudio-alsa pulseaudio-bluetooth pavucontrol    
  # Scripting utilities  
    nmap par2cmdline pigz unrar p7zip    
  # System management
    screen shellcheck 
    sshfs
    gparted gnome-disk-utility 
    htop iftop s-tui stress
    sshuttle python36           # AUR
  # X.org
    xorg-server xorg-xinit xorg-xauth xorg-xrandr	  # Core stuff
    xorg-setxkbmap                                  # Keyboard layout 
    xorg-xmodmap xorg-xinput  	                    # Customize Kb layout (old way)
    xorg-xkbutils xorg-xkbevd xorg-xkbcomp          # Customize Kb layout (modern way)
    # xorg-xhost xorg-xinput xorg-xev         		  # ? ...
    # xorg-xset xorg-xbacklight			      		      # ? ...  
    xrandr-invert-colors 							              # AUR   
)


#
#	User applications
#
apps=(
  # Programming
	code gedit geany
	texinfo texlive-bibtexextra texlive-fontsextra texlive-formatsextra texlive-latexextra texlive-pstricks texlive-publishers texlive-science
	virtualbox virtualbox-host-dkms virtualbox-ext-oracle
  # Internet  
	deluge 
	discord slack-desktop skypeforlinux-stable-bin zoom-system-qt
    remmina logmein-hamachi 
    firefox vivaldi vivaldi-codecs-ffmpeg-extra-bin chromium
    ferdi
  # Office
	mailspring-libre
	syncthing 
	libreoffice-still ms-office-online
	gimp
  # Multimedia
  	#spotify 	# always has GPG problems
  	youtube-dl audacious audacity
	gstreamer gst-libav gst-plugins-base gst-plugins-good gst-plugins-bad gst-plugins-ugly	
	libdvdcss
  # Gaming
	steam steam-native-runtime
	dxvk-bin mangohud libstrangle-git
    wine wine-mono wine-gecko winetricks
  # Printing	
	cups cups-pdf 
	epson-inkjet-printer-201208w epson-printer-utility	# AUR
  # Mobile network modems  
    modemmanager modem-manager-gui mobile-broadband-provider-info
    usb_modeswitch wvdial
  # ...
    apache archiso 
    memtest86-efi        # in AUR
    imwheel
)


#
#	Desktop Environments
#

plasma=(                                                                # KDE Plasma DE
    plasma-desktop plasma-wayland-session
  # Applets  
    plasma-nm bluedevil
    kmix
    powerdevil
  # Terminal, Files, text editor, pdf, image, video, archive
    terminator dolphin geany gpicview evince vlc file-roller
  # Other applications
    synapse tilda syncthingtray baobab konsole caffeine-ng
    spectacle 		# screenshots
  # Theming  
    colord-kde kde-gtk-config breeze-gtk
    ttf-dejavu ttf-liberation cantarell-fonts ttf-droid 
  # Other
    kwallet-pam  
)

qde=(                                                                   # Minimalistic DE based on openbox+tint2
    openbox tint2 opensnap
    lxsession
    obconf lxappearance obkey
    notification-daemon xfce4-notifyd
    gvfs gvfs-mtp gvfs-gphoto2
  # applets  
    nm-applet blueman
  # Applications
    terminator pcmanfm geany gpicview evince vlc file-roller
    tilda syncthing-gtk baobab caffeine-ng
    gnome-screenshot gnome-system-monitor
  # Theming  
    elementary-icon-theme
    ttf-dejavu ttf-liberation cantarell-fonts ttf-droid 
)


#
#   NB: Pass array by name 
#
function fprint_array () {
  aname=$1[@]
  array=("${!aname}")  
  for item in ${array[@]};
  do 
    printf "$item "
  done
}

for arg in "$@"
do 
  fprint_array "$arg"
done

