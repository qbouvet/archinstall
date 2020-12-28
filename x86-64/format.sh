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
  echo "BIOS detected."
  echo "Only EFI installation is supported."
  echo "Exiting"
  exit 1
fi

if ! [[ $(modprobe zfs) ]]
then
  echo "Failed to load zfs."
  echo "Exiting"
  exit 1
fi

echo "Installing to:"
echo "  > $install_disk"
echo "Please confirm..."
read


# ----- Partitioning

bdev=$(\
  readlink -f "$install_disk" \
  | sed 's|/dev/||' \
)
secsize=$(\
  lsblk --noheadings -o NAME,LOG-SEC \
  | grep "$blockdev" \
  | head -n 1 \
  | awk '{print $2;}' \
)

mib=$((1024*1024))

disk_start="2048"
disk_end=$(blockdev --getsize /dev/$bdev)

esp_start=${disk_start}
esp_end=$((esp_start +128*mib/secsize -1))

root_start=$((esp_end +1))
root_end=$((disk_end -swap_size*mib/secsize -1))

swap_start=$((root_end +1))
swap_end="100%"

parted --script "$install_disk" \
  mklabel "gpt"  

# EFI System Partition
parted --script "$install_disk" \
  mkpart primary "${disk_start}s" "${esp_end}s" \
  set "1" "boot" "on" 

# Future ZFS pool containing /, /boot, ...
parted --script "$install_disk" \
  mkpart primary "${root_start}s" "${root_end}s"

# Swap Space
parted --script "$install_disk" \
  mkpart primary "${swap_start}s" "${swap_end}" 


# ----- Formatting  

mkfs.fat -F 32 "$install_disk-part1"

mkswap "$install_disk-part3"

swapon "$install_disk-part3"


# ----- ZFS Pools

echo "  zpool"

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

zfs_opts_grub_compat_v1=" \
  -d \
  -o feature@async_destroy=enabled \
  -o feature@bookmarks=enabled \
  -o feature@embedded_data=enabled \
  -o feature@empty_bpobj=enabled \
  -o feature@enabled_txg=enabled \
  -o feature@extensible_dataset=enabled \
  -o feature@filesystem_limits=enabled \
  -o feature@hole_birth=enabled \
  -o feature@large_blocks=enabled \
  -o feature@lz4_compress=enabled \
  -o feature@spacemap_histogram=enabled \
  -o feature@zpool_checkpoint=enabled \
"

zfs_opts_grub_compat_v2=" \
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
zpool create \
  ${zfs_opts_default} \
  ${zfs_opts_grub_compat_v2} \
  -R /mnt \
  zroot "/dev/disk/by-id/ata-VBOX_HARDDISK_VBfef6bb2e-1a8ff6e1-part2"


# ----- ZFS Datasets

echo "  datasets"

zfs create -o mountpoint=/     -o canmount=noauto      zroot/rootfs


# ----- Validate ZFS config and mount datasets

echo "  validation & mount"

# Validate configuration by exporting and re-importing zpools
zpool export zroot
zpool import -d /dev/disk/by-id -R /mnt zroot -N

# Manually mount rootfs dataset, then mount all other
zfs mount zroot/rootfs
zfs mount -a  


# ----- Mount additional partitions (ESP)

echo "  ESP"

mkdir -p /mnt/boot/EFI
mount "${install_disk}-part1" /mnt/boot/EFI

























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