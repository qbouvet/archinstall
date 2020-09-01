#!/bin/bash 

#
#   Generate package lists for arch install 
#
#   Usage: 
#     pacman -Syu $($0 system)
#     yay -Syu $($0 applications)
#


#
#	Pacstrap packages
#

pacstrap=(
	base base-devel 
	linux-lts linux-lts-headers linux-firmware
	nano sudo
	git
)


#
#	Vendor-specific packages
#

amd=(
    amd-ucode lm_sensors 
)

intel=(  
    intel-ucode thermald lm_sensors 
)

nvidia=( 
    nvidia-dkms nvidia-settings lm_sensors 
)

apple=(
    hid-apple-patched-git-dkms
)


#
#	Core packages
#

system=(
  # Core services
    systemd-swap ntp tlp 
    powertop
  # CLI utilities (Core)
    sudo nano git git-lfs gnu-netcat wget 
    openconnect openssh 
  # FS & Disks 
    udisks2 smartmontools hdparm
    exfat-utils ntfs-3g f2fs-tools dosfstools fatresize apfsprogs-git 
    ext4magic e2fsprogs    # badblocks, recovery
  # Wireless, network
    networkmanager bluez
  # Sound
    alsa-utils
    pulseaudio pulseaudio-alsa pulseaudio-bluetooth pavucontrol    
  # Scripting utilities  
    nmap par2cmdline unrar p7zip    
  # System management
    sshfs sshuttle python36
    gparted gnome-disk-utility 
    htop iftop s-tui stress
    shellcheck
  # X.org
    xorg-server xorg-xinit xorg-xauth xorg-xrandr	# Core stuff
    xorg-setxkbmap                                  # Keyboard layout 
    xorg-xmodmap xorg-xinput  	                    # Customize Kb layout (old way)
    xorg-xkbutils xorg-xkbevd xorg-xkbcomp          # Customize Kb layout (modern way)
    # xorg-xhost xorg-xinput xorg-xev         		# ? ...
    # xorg-xset xorg-xbacklight			      		# ? ...  
    xrandr-invert-colors 							# AUR
  #  
    
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
	memtest86-efi		# in AUR
	imwheel
)


#
#	Desktop Environments
#

plasma=(												 # KDE Plasma DE
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
)

qde=(							# Minimalistic DE based on openbox+tint2
    openbox tint2
  # Terminal, Files, text editor, pdf, image, video, archive
    terminator pcmanfm geany gpicview evince vlc file-roller
    tilda syncthing-gtk baobab caffeine-ng
    gnome-screenshot gnome-system-monitor
  # Theming  
    ttf-dejavu ttf-liberation cantarell-fonts ttf-droid 
    # ... obkey, lxappearance, ...
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

