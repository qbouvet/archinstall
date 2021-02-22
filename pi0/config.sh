#!/usr/bin/env bash
if [ $# -gt 0 ] && { [ "$1" == "-h" ] || [ "$1" == "--help" ] ;} ; then
printf "

    config.sh
    =========

  Editable configuration variables. Don't execute this file, source it.  
  
  Usage : $0
  
"
return 0
fi

# Don't execute, only source
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then 
    echo "This file ($0) should be sourced, not executed"
fi


# ----- SD Card block device

export blockdev="/dev/sdd"          # !! If mmcblk, needs a 'p'
export swapsize="2048"  


# ----- Image to install

export alarm_archive="ArchLinuxARM-rpi-latest.tar.gz"
export alarm_archive_url="http://os.archlinuxarm.org/os/$alarm_archive"
export alarm_archive_md5="$alarm_archive_url.md5"


# ----- Users and passwords

users=(
  #root     # pw=root
  quentin   # pw=quentin
)


# ----- Other stuff

export hostname="pi0-openocd"
export timezone="/usr/share/zoneinfo/Europe/Zurich"


# ----- Network & SSH

export ssh_port="22"


# ----- Partitions

export blocksize="512"
export boot_part_start="2048s"      # s2048 -> s821247 = 400MB (with 512b sectors)
export boot_part_end="821247s"   
export root_part_start="821248s"    # rest of the space
export root_part_end="100%"


# ----- Swap

export swappiness="60";             # default: 60
export vfs_cache_pressure="250"     # default: ? 
export use_systemd_swap="false"


# ----- CONSTANTS, DO NOT CHANGE

export __dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)";
export workdir="/tmp/install-arch/${hostname}"
mkdir -p "${workdir}"
export rootmnt="${workdir}/mnt";
export bootmnt="${workdir}/mnt/boot";
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







