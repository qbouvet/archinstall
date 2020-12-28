#!/usr/bin/env bash


# ----- Prelude

# Usual bash flags
set -euo pipefail   # Exit on 1/ nonzero exit code 2/ unassigned variable 3/ pipe error
shopt -s nullglob   # Allow null globs
#set -o xtrace      # Show xtrace  

source $wd/config.sh
source $wd/utils/f.sh


# ----- Pre-flight check

if [[ $firmware_interface != "efi" ]]
then 
  printf "\n  Using BIOS firmware interface\n"
else 
  printf "\n  Using UEFI firmware interface\n"
fi

if ! modprobe zfs
then
  echo "Failed to load zfs."
  echo "Exiting"
  exit 1
fi

printf "\nInstalling to:\n"
printf "  > $install_disk\n"
printf "Please confirm...\n"
read

if ! [[ -e "$install_disk" ]] 
then 
  echo "Not a valid disk: "
  echo "  $install_disk"
  echo "(did you include '/dev/disk/by-id' in the path ?)"
  echo "Exiting"
  exit 1
fi


# ----- Partitioning

printf "\n  Reading disk info\n"

bdev=$(readlink -f "$install_disk")

secsize=$(\
  lsblk --noheadings -o NAME,LOG-SEC \
  | grep $(echo $bdev | sed 's|/dev/||') \
  | head -n 1 \
  | awk '{print $2;}' \
)

printf "\n  Computing disk values\n"

mib=$((1024*1024))      # 1 MiB
mibsec=$((mib/secsize)) # How many sectors for 1MiB

disk_start="2048"       
disk_max=$(blockdev --getsize $bdev)
disk_mib_blocks=$((disk_max/mibsec))        # integer division -> how many "1MiB sector groups" we have
disk_end=$((mibsec*disk_mib_blocks))        # MiB-aligned disk end

if [[ $(( (disk_end/mibsec)*mibsec )) -ne $disk_end ]]
then 
  echo "  Error while computing disk values"
  exit 1
fi

fip_start=${disk_start}                     # Firmware interface partition
fip_end=$((fip_start +128*mib/secsize -1))  # ESP for UEFI, BIOS-boot for BIOS

root_start=$((fip_end +1))
root_end=$((disk_end -swap_size*mib/secsize -1))

swap_start=$((root_end +1))
swap_end="100%"

printf "\n  Partitioning\n"

parted --script "$install_disk" \
  mklabel "gpt"  

# EFI System Partition
if [[ "$firmware_interface" == "efi" ]]
then 
  parted --script "$install_disk" \
    mkpart primary "${disk_start}s" "${fip_end}s" \
    set "1" "boot" "on" 
  sync; sleep 1s; # Weird behaviour
  mkfs.fat -F 32 "${install_disk}-part1"  
else 
  parted --script "$install_disk" \
    mkpart primary "${disk_start}s" "${fip_end}s" \
    set "1" "bios_grub" "on" 
fi

# Future ZFS pool containing /, /boot, ...
parted --script "$install_disk" \
  mkpart primary "${root_start}s" "${root_end}s"

# Swap Space
parted --script "$install_disk" \
  mkpart primary "${swap_start}s" "${swap_end}" 
sync; sleep 1s; # Weird behaviour
mkswap "${install_disk}-part3"
swapon "${install_disk}-part3"


# ----- ZFS Pools

printf "\n  Creating Zpools\n"

zfs_opts_default=" \
  -o ashift=12             \
  -O acltype=posixacl      \
  -O relatime=on           \
  -O xattr=sa              \
  -O dnodesize=legacy      \
  -O normalization=formD   \
  -O mountpoint=none       \
  -O canmount=off          \
  -O devices=off           \
  -O compression=lz4       \
"

zfs_opts_grub_compat=" \
  -d \
  -o feature@allocation_classes=enabled \
  -o feature@async_destroy=enabled      \
  -o feature@bookmarks=enabled          \
  -o feature@embedded_data=enabled      \
  -o feature@empty_bpobj=enabled        \
  -o feature@enabled_txg=enabled        \
  -o feature@extensible_dataset=enabled \
  -o feature@filesystem_limits=enabled  \
  -o feature@hole_birth=enabled         \
  -o feature@large_blocks=enabled       \
  -o feature@lz4_compress=enabled       \
  -o feature@project_quota=enabled      \
  -o feature@resilver_defer=enabled     \
  -o feature@spacemap_histogram=enabled \
  -o feature@spacemap_v2=enabled        \
  -o feature@userobj_accounting=enabled \
  -o feature@zpool_checkpoint=enabled   \
"

# Single pool with grub compatible options
#  -f if script runs several times, old pool gets detected in spite of formatting
zpool create -f \
  ${zfs_opts_default} \
  ${zfs_opts_grub_compat} \
  -R /mnt \
  zroot "${install_disk}-part2"


# ----- ZFS Datasets

printf "\n  Creating Partitioning\n"

zfs create -o mountpoint=/     -o canmount=noauto      zroot/rootfs


# ----- Validate ZFS config and mount datasets

printf "\n  Validating ZFS and mounts\n"

# Validate configuration by exporting and re-importing zpools
zpool export zroot
zpool import -d /dev/disk/by-id -R /mnt zroot -N

# Manually mount rootfs dataset, then mount all other
zfs mount zroot/rootfs
zfs mount -a  

if [[ "$firmware_interface" == "efi" ]]
then 
  mkdir -p /mnt/boot/EFI \
  mount "${install_disk}-part1" /mnt/boot/EFI
fi

























# ----- Legacy stuff

# install_disk=""

# disks=()
# parts=()
# for e in /dev/disk/by-id/*
# do
#   echo $e
#   if [[ "$e" =~ .*-part[0-9]+ ]]
#   then 
#     parts+=("$e")
#   else 
#     disks+=("$e")
#   fi 
# done

# case ${#disks[@]} 
# in
#   0)
#     echo "No disk detecting. Aborting"
#     exit 1
#     ;;
#   1)
#     install_disk="${disks[0]}"
#     echo "One disk detected. "
#     ;;
#   *)
#     echo "Several disks detected. Select one"
#     declare -i i; i=0
#     while [[ i -lt ${#disks[@]} ]]
#     do 
#       echo "  $i  -  ${disks[i]}"
#       i=$((i+1))
#     done 
#     echo "> "; read i
#     install_disk="${disks[i]}"
#     ;;
# esac