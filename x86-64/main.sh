#!/usr/bin/env bash
if [ $# -gt 0 ] && { [ "$1" == "-h" ] || [ "$1" == "--help" ] ;} ; then
printf "

    Install.sh
    ===========

  1/ Transfer files: 
      $ ip=192.168.1.13; ssh root@$ip 'mkdir -p /install'; scp -r ./* root@$ip:/install/
      or 
      curl / git

  2/ Configure stuff in config.sh

  3/ \$ screen -S install
  
  3/ ./$0
  
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
params["noconfirm"]="false"
params["reportfile"]="$wd/report.txt"
params["restoredir"]=$(pwd)             # just want to show this
params["workdir"]=$wd                   # just want to show this

aa.argparse params ${@:1}


# ----- Dispatch to correct stage

# case ${params["stage"]} in 

#     ("populate") \
#         ${wd}/format.sh
#         ${wd}/pacstrap.sh
#         ${wd}/${0} --stage "prep-chroot"
#         ;;
#     ("prep-chroot") \
#         mkdir -p /mnt/install
#         cp -a ./* /mnt/install
#         arch-chroot /mnt /install/${0} --stage "in-chroot"
#         ;;
#     ("in-chroot") \
#         ${wd}/base.sh
#         ${wd}/bootloader.sh
#         ;;
#     (*) \
#         printf "Error: Wrong stage: ${params["stage"]}"
# esac

aa.pprint params
read

# This version does not pass exported variables through chroot. The old version does,
# as the entire script is run again in chroot. This is not necessarily a problem,
# source config.sh again
case ${params["stage"]} 
in 
    ("format") \
        ${wd}/format.sh
        ${0} --stage "pacstrap"
        ;;
    ("pacstrap") \
        ${wd}/pacstrap.sh
        ${0} --stage "base"
        ;;
    ("base") \
        arch-chroot /mnt ${wd}/base.sh
        ${0} --stage "bootloader"
        ;;
    ("bootloader") \
        arch-chroot /mnt ${wd}/bootloader.sh
        ${0} --stage "done"
        ;;
    (*) \
        printf "Error: Wrong stage: ${params["stage"]}"
        exit 1
        ;;
esac

echo "Installation complete"
exit 0