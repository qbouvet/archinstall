#!/usr/bin/env bash
if [ $# -gt 0 ] && { [ "$1" == "-h" ] || [ "$1" == "--help" ] ;} ; then
printf "

    config.sh
    =========
  
  Usage : $0
  
"
return 0
fi


# ----- Formatting

export blockdev="/dev/sda"          # !! needs a p when mmcblk
export is_efi="true"



# ----- Other stuff

export hostname="rv515"
export timezone="/usr/share/zoneinfo/Europe/Zurich"



# ----- Users and passwords

export root="root"
export username="quentin"



# ----- Swap

export swappiness="10";
export vfs_cache_pressure="250"