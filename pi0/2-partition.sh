 #!/usr/bin/env bash

if [ $# -gt 0 ] && { [ "$1" == "-h" ] || [ "$1" == "--help" ] ;} ; then
printf "
    Partition SD card for arch linux ARM installation
"
return 0
fi


# ----- Prelude

set -euo pipefail   # Exit on 1/ nonzero exit code 2/ unassigned variable 3/ pipe error
shopt -s nullglob   # Allow null globs
#set -o xtrace      # Show xtrace  


# ----- Imports

# Variables don't need to ba re-sources, but functions do ???
source "${wd}/config.sh"              # <- This is not needed ? 
source "${wd}/../common/utils/indent.sh"     # <- But this is ? 


# ----- Confirm blockdev

lsblk | indent 4
printf "\nSelected block device is ${blockdev}.\n[enter] to confirm \n";
read -r;


# ----- Unmount partitions if mounted

readarray -t mountpoints < <( \
  cat /proc/mounts \
        | grep "$blockdev" \
        | awk '{print  $2; }' \
        || [ $? == 1 ] \
) # [ $? == 1 ] === don't exit if grep returns 1
printf "\nFound mountpoints: \n"
for mp in ${mountpoints[@]}; 
do 
  printf "  * $mp\n"
done

printf "\nUnmounting...\n"
# Reverse iterations, because later mountpoints can keep earlier mountpoints busy
for (( i=${#mountpoints[@]}-1; i>=0; i-- )) 
do 
  mountpoint="${mountpoints[i]}"
  echo "  * ${mountpoint}"
  umount "${mountpoint}"
done 
  

# ----- Create partitions

printf "\nCreating partition table...\n"
parted --script "$blockdev" \
    mklabel msdos \
    mkpart primary fat16  "${boot_part_start}" "${boot_part_end}" \
    mkpart primary ext4 "${root_part_start}" "${root_part_end}" \
    set 1 boot on

printf "Formatting... \n"

printf "  * ${bootpart}... \n"
echo "y" | sudo mkfs.vfat "${bootpart}" | indent 4 ;

sleep 2s

printf "  * ${rootpart}...\n"
echo "y" | sudo mkfs.ext4 "${rootpart}" 2>&1 | indent 4 ;


# ----- Remount and assert mounts are correct

# Unmount everything 
[[ $(mount | grep "report.txt") ]] \
    && umount $(mount | grep "report.txt" | awk '{print $3}')

[[ $(mount | grep "${bootpart}") ]] \
    && umount $(mount | grep "${bootpart}" | awk '{print $3}')

[[ $(mount | grep "${rootpart}") ]] \
    && umount $(mount | grep "${rootpart}" | awk '{print $3}')

# Remount root file system  
mkdir -p "$rootmnt";
mount "${rootpart}" "$rootmnt"; # [[ $(mount | grep "${rootpart}") ]] || 

# Remount boot directly into root file system 
mkdir -p "$rootmnt/boot";
mount "${bootpart}" "$rootmnt/boot"; # [[ $(mount | grep "${bootpart}") ]] || 
sleep 1s;

# Assert mounts are correct
printf "\nChecking mountpoints...\n"
expected=( 
  "${rootpart} on ${rootmnt}"
  "${bootpart} on ${bootmnt}"
)
for expectation in "${expected[@]}"
do
  printf "  * $expectation\n"
  if [[ $(grep "$expectation" < <(mount)) ]]
  then 
    printf "    found\n"
  else 
    printf "    not found !\n"
    exit 1
  fi
done