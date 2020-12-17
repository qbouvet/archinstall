#!/usr/bin/env bash

#
#       0-config.sh
#       ===========
#
#   Holds the variables for all scripts. Source it, don't execute
#



# ----- Block device

export blockdev="/dev/sde"          # !! needs a p when mmcblk



# ----- Partitions sizes

export boot_part_start="2048s"      # s2048 -> s821247 = 400MB (with 512b sectors)
export boot_part_end="821247s"   
export root_part_start="821248s"    # rest of the space
export root_part_end="100%"



# ----- Image to install

export alarm_archive="ArchLinuxARM-rpi-aarch64-latest.tar.gz"
export alarm_archive_url="http://os.archlinuxarm.org/os/$alarm_archive"
export alarm_archive_md5="$alarm_archive_url.md5"



# ----- Swap

export swappiness="10";
export vfs_cache_pressure="250"



# ----- Packages

export packages=(
  # base, base-devel, or minimal equivalent
    pacman-mirrorlist
    autoconf automake binutils bison file findutils flex gawk gcc gettext grep groff gzip libtool m4 make pacman patch pkgconf sed sudo texinfo which
    # autoconf automake binutils fakeroot gcc make patch sudo 
  # Core stuff
    man-db man-pages git pacman-contrib pacutils ntp fake-hwclock dnsmasq wget htop 
    po4a    # for fakeroot-tcp
    go      # for yay
  # Firmware
    firmware-raspberrypi libbcm2835
  # Applications  
    syncthing                                   # Synchronization
    networkmanager modemmanager usb_modeswitch  # Wifi AP 
);
export aur_packages=(
    #ngrok-bin                                  # Small test package
    pi-bluetooth                                # Powersave feature, maybe
)



# ----- Network & SSH

export ssh_port="22"



# ----- Users and passwords

export rootpw="root"
export username="quentin"
export userpw="quentin"



# ----- Other stuff

export hostname="pi3"
export timezone="/usr/share/zoneinfo/Europe/Zurich"








# ----- Constants, leave that bit alone

export __dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)";
export rootmnt="${__dir}/mnt";
export bootmnt="${__dir}/mnt/boot";
export bootpart="${blockdev}1" # !! mmcblk -> add p1 / p2
export rootpart="${blockdev}2" # !! sdb    -> add 1  / 2


#
# For reference:
#

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

#ctrl_interface=/var/run/wpa_supplicant
#ap_scan=0
#network={
#   key_mgmt=IEEE8021X
#   eap=PEAP
#   identity="bill_bot_"
#   password="qwertz"
#   phase2="autheap=MSCHAPV2"
#}







