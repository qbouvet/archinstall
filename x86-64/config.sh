#!/usr/bin/env bash
if [ $# -gt 0 ] && { [ "$1" == "-h" ] || [ "$1" == "--help" ] ;} ; then
printf "

    config.sh
    =========
  
  Usage : $0
  
"
return 0
fi

# Don't execute, only source
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then 
    echo "This file ($0) should be sourced, not executed"
fi


# ----- Formatting

export install_disk="/dev/disk/by-id/ata-SAMSUNG_HM080II_S0BRJ30LA51793" #ata-VBOX_HARDDISK_VBfef6bb2e-1a8ff6e1"
export swap_size="8192" # MiB


# ----- Other stuff

export hostname="rv515"
export timezone="/usr/share/zoneinfo/Europe/Zurich"


# ----- Users and passwords

export users=(
  quentin
  demosthene
)


# ----- Swap

export swappiness="60";           # Default: 60
export vfs_cache_pressure="100"   # Default: ?

export use_systemd_swap="false"


# ----- Packages

export packages=$( \
  pkgs.sh \
    cpu_amd gpu_amd \
    core \
)