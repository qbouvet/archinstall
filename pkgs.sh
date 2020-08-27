#!/bin/bash 

#
#   Generate package lists for arch install 
#
#   Usage: 
#     pacman -Syu $($0 system)
#     yay -Syu $($0 applications)
#

#
#	Core packages
#
system=(
  # Base packages 
	base base-devel 
	linux-lts linux-lts-headers 
	linux-firmware
  # Drivers / firmware 
    amd-ucode 
    intel-ucode
    nvidia-dkms nvidia-settings 
    lm_sensors xsensors 
  # Core CLI utilities
    sudo nano gnu-netcat wget git git-lfs  
    openconnect openssh sshfs 
    iftop htop s-tui 
    shellcheck nmap par2cmdline unrar p7zip    
    stress
  # Wireless, network
    networkmanager bluez
    sshuttle 
  # Sound
    alsa-utils
    pulseaudio pulseaudio-alsa pulseaudio-bluetooth pavucontrol    
  # Disks 
    udisks2 smartmontools hdparm 
    gnome-disk-utility gparted   
    exfat-utils ntfs-3g f2fs-tools dosfstools fatresize
    ext4magic, e2fsprogs    # badblocks, recovery
  # System management
    systemd-swap ntp
    grub-customizer os-prober
    tlp powertop    
  # X.org
    xorg-server xorg-xinit xorg-xauth xorg-xrandr	# Core stuff
    xorg-setxkbmap xorg-xmodmap					    # Keyboard stuff
    # xorg-xkbcomp xorg-xkbevd xorg-xkbutils  # ? ...
    # xorg-xhost xorg-xinput xorg-xev         # ? ...
    # xorg-xset xorg-xbacklight			      # ? ...    
)

system_aur=(
    xrandr-invert-colors 
    apfsprogs-git
    python36
)


#
#   Plasma DE
#
plasma=(
    plasma-desktop
    plasma-wayland-session
  # Applets  
    plasma-nm bluedevil
    kmix
    powerdevil
  # Terminal, Files, text editor, image viewer, pdf viewer, video player, archive
    terminator dolphin geany gpicview evince vlc file-roller
  # Other applications
    synapse tilda syncthingtray baobab konsole caffeine-ng
    spectacle 		# screenshots
  # Theming  
    colord-kde kde-gtk-config breeze-gtk
    ttf-dejavu ttf-liberation cantarell-fonts ttf-droid 
)


#
#	Minimalist DE based on openbox+tint2
#
qde=(
    openbox tint2
  # Terminal, Files, text editor, image viewer, pdf viewer, video player, archive
    terminator pcmanfm geany gpicview evince vlc file-roller
    tilda syncthing-gtk baobab caffeine
    gnome-screenshot gnome-system-monitor
  # Theming  
    ttf-dejavu ttf-liberation cantarell-fonts ttf-droid 
    # ... obkey, lxappearance, ...
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
  # Office
	mailspring-libre
	syncthing 
	libreoffice-still ms-office-online
	gimp
  # Multimedia
  	spotify youtube-dl
    audacious audacity
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
	memtest86-efi		# in AUR
	imwheel
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

fprint_array $1
