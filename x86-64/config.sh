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

export blockdev="/dev/sda"          # !! needs a p when mmcblk
export is_efi="true"



# ----- Other stuff

export hostname="rv515"
export timezone="/usr/share/zoneinfo/Europe/Zurich"



# ----- Users and passwords

export users=(
  quentin
  demosthene
)



# ----- Swap

export swappiness="60";
export vfs_cache_pressure="250"