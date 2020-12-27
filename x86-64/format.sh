#!/usr/bin/env bash


# ----- Prelude

# Usual bash flags
set -euo pipefail   # Exit on 1/ nonzero exit code 2/ unassigned variable 3/ pipe error
shopt -s nullglob   # Allow null globs
#set -o xtrace      # Show xtrace  

source $wd/config.sh
source $wd/utils/f.sh


# ----- Pre-flight check

# Check disk

modprobe zfs

# Check BIOS/EFI

# ...


# ----- Partitioning

# Wipe the disk

sector_size=512
mib=$((1024*1024))
esp_sector_start=2048
esp_sector_end=$((2048 +128*mib/sector_size -1))
# No separate boot partition
#boot_sector_start=$((esp_sector_end+1))
#boot_sector_end=$((boot_sector_start +512*mib/sector_size -1))

parted --script "/dev/sda" \
  mklabel "gpt"  

# EFI System Partition
parted --script "/dev/sda" \
  mkpart primary "${esp_sector_start}s" "${esp_sector_end}s" \
  set "1" "boot" "on" 

mkfs.fat -F 32 /dev/sda1  

# Future ZFS pool containing /, /boot, ...
parted --script "/dev/sda" \
  mkpart primary "$((esp_sector_end+1))s" "100%" 


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
mount /dev/sda1 /mnt/boot/EFI