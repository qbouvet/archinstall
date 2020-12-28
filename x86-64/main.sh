#!/usr/bin/env bash

if [ $# -gt 0 ] && { [ "$1" == "-h" ] || [ "$1" == "--help" ] ;} ; then
printf "

    Install.sh
    ===========

  1/ Transfer files: 
      $ git clone https://github.com/qbouvet/install-arch.git
      or
      $ ip=192.168.1.13; ssh root@$ip 'mkdir -p /install'; scp -r ./* root@$ip:/install/

  2/ \$ screen -S install

  3/ $ nano /install/x86_64/config.sh
  
  4/ ./$0

  TODO: 
    * Add a BIOS version (GPT+BIOS)
    *----
    * Use reflector for pacman DL speedup
    * Is there anything userful here ? https://github.com/danboid/ALEZ/blob/master/alez.sh

  Done: 
    * Done        <<< Add swap partition
    * Done        <<< Un-Hardcode the disk name
    *----
    * Works       <<< base.sh/users
    * Works       <<< Check SSH access
    * Works       <<< Check network connectivity
    * Works       <<< Check unattended boot works
    *----
    * Draft version
  
"
return 0
fi


# ----- Prelude

# Usual bash flags
set -euo pipefail   # Exit on 1/ nonzero exit code 2/ unassigned variable 3/ pipe error
shopt -s nullglob   # Allow null globs
#set -o xtrace      # Show xtrace  

# Run as root
[ "$UID" -eq 0 ] || exec sudo bash "$0" "$@";

# Set working directory
export wd="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Imports 
source "${wd}/config.sh"


# ----- Parameters

source "${wd}/utils/aa.sh"
declare -A params

params["stage"]="format"
params["unattended"]="false"
params["reportfile"]="$wd/report.txt"

aa.argparse params ${@:1}



# ----- Constants 

firmware_interface="bios"
[ -d /sys/firmware/efi ] && firmware_interface="efi"
export firmware_interface

export LANG="C"       # prevent locale errors when building mandb





# ----- Dispatch to correct stage

# User interaction
aa.pprint params
if ! [[ ${params["unattended"]} == "true" ]]
then 
  read
fi

# Copy scripts to chroot
if [[ -d "/mnt/install" ]]
then 
  cp -a /install/* /mnt/install
fi

case ${params["stage"]} 
in 
    ("format") \
        ${wd}/format.sh
        ${0} --stage "pacstrap"   --unattended ${params["unattended"]} --reportfile ${params["reportfile"]}
        ;;
    ("pacstrap") \
        ${wd}/pacstrap.sh
        ${0} --stage "base"       --unattended ${params["unattended"]} --reportfile ${params["reportfile"]}
        ;;
    ("base") \
        arch-chroot /mnt ${wd}/base.sh
        ${0} --stage "bootloader" --unattended ${params["unattended"]} --reportfile ${params["reportfile"]}
        ;;
    ("bootloader") \
        arch-chroot /mnt ${wd}/bootloader.sh
        ${0} --stage "yay"        --unattended ${params["unattended"]} --reportfile ${params["reportfile"]}
        ;;
    ("yay") \
        arch-chroot /mnt ${wd}/yay.sh
        ${0} --stage "done"       --unattended ${params["unattended"]} --reportfile ${params["reportfile"]}
        ;;
    (*) \
        printf "Stage: ${params["stage"]}, exiting normally\n"
        exit 0
        ;;
esac