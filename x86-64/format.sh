#!/usr/bin/env bash


# ----- Pre-flight check

modprobe zfs


# ----- Partitioning

sector_size=512
mib=$((1024*1024))
esp_sector_start=2048
esp_sector_end=$((2048 +128*mib/sector_size -1))
boot_sector_start=$((esp_sector_end+1))
boot_sector_end=$((boot_sector_start +512*mib/sector_size -1))

parted --script "/dev/sda" \
  mklabel "gpt"  

# EFI System Partition
parted --script "/dev/sda" \
  mkpart primary "${esp_sector_start}s" "${esp_sector_end}s" \
  set "1" "boot" "on" 

mkfs.fat -F 32 /dev/sda1  

# Boot Partition
parted --script "/dev/sda" \
  mkpart primary "${boot_sector_start}s" "${boot_sector_end}s"
  
# Root partition
parted --script "/dev/sda" \
  mkpart primary "$((boot_sector_end+1))s" "100%" 


# ----- ZFS Pools

echo "zpool"; read

# Boot pool on 2d partition
# We'll store /boot on a ZFS pool and use GRUB. GRUB does not support all ZFS features, so we create a 
# special pool with the specific subset of GRUB-compatible options.
zpool create \
  -o ashift=9 -d \
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
  -O acltype=posixacl -O canmount=off -O compression=lz4 \
  -O devices=off -O normalization=formD -O relatime=on -O xattr=sa \
  -O mountpoint=/boot \
  -R /mnt \
  zboot "/dev/disk/by-id/ata-VBOX_HARDDISK_VBfef6bb2e-1a8ff6e1-part2"


# Root pool on 3rd partition
# use -o ashift=9 for disks with a 512 byte physical sector size or -o ashift=12 for disks with a 4096 byte physical sector size
zpool create -f \
  -o ashift="9"              \
  -O acltype="posixacl"       \
  -O relatime="on"            \
  -O xattr="sa"               \
  -O dnodesize="legacy"       \
  -O normalization="formD"    \
  -O mountpoint="none"        \
  -O canmount="off"           \
  -O devices="off"            \
  -R /mnt                   \
  -O compression="zstd"       \
  zroot "/dev/disk/by-id/ata-VBOX_HARDDISK_VBfef6bb2e-1a8ff6e1-part3"


# ----- ZFS Datasets

echo datasets; read

#   Datasets for /, /home, /root
zfs create -o mountpoint=none zroot/ROOT
zfs create -o mountpoint=/ -o canmount=noauto zroot/ROOT/default

#   Datasets fo /home, /root
zfs create -o mountpoint=none  zroot/data
zfs create -o mountpoint=/home zroot/data/home
zfs create -o mountpoint=/root zroot/data/home/root

#   Datasets for /boot
# "filesystem datasets to act as container"
zfs create -o canmount=off -o mountpoint=none zboot/BOOT
# "Filesystem datasets for root and boot"
zfs create -o mountpoint=/boot zboot/BOOT/default

#   Other datasets recommended by arch wiki (???)
zfs create -o mountpoint=/var -o canmount=off     zroot/var
zfs create                                        zroot/var/log
zfs create -o mountpoint=/var/lib -o canmount=off zroot/var/lib
zfs create                                        zroot/var/lib/libvirt
zfs create                                        zroot/var/lib/docker



# ----- Validate ZFS config and mount datasets

echo "validation"; read

# Validate configuration by exporting and re-importing zpools
zpool export zroot
zpool import -d /dev/disk/by-id -R /mnt zroot -N

zpool export zboot
zpool import -d /dev/disk/by-id -R /mnt zboot -N

# Manually mount rootfs dataset, then mount all other
zfs mount zroot/ROOT/default
zfs mount -a  


# ----- Mount additional partitions (ESP)

mkdir -p /mnt/boot/EFI
mount /dev/sda1 /mnt/boot/EFI