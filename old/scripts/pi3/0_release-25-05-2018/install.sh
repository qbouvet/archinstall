#!/usr/bin/env bash


## Parameters
##
wifi_mac_addr="B8:27:EB:EF:87:F8";   # board's Wi-fi chip mac address
rootfs_first_sector="206848";        # Sectors are sdcard-dependant
rootfs_last_sector="19081215";
datafs_first_sector="19081216";
datafs_last_sector="30881791";
__dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)";
__root="$__dir"/mnt-rootfs;
__boot="$__dir"/mnt-boot;
__data="$__dir"/mnt-data;   # Pi data partition
__assets="$__dir"/assets;   # Host data folder
cd $__dir;



## Acquire root
##
[ "$UID" -eq 0 ] || exec sudo bash "$0" "$@";



## Ask block device path
##
lsblk;
printf "\n\tPlease enter the block device path (/dev/sdX)\n>";
bd="";
read bd;
printf "\n\nBlock device is $bd\nPlease confirm or ctrl-C\n";
read;



## Unmount block device's partitions
##
printf "\n\n [Unmounting partitions on $bd]\n"
cat /proc/mounts | grep $bd | while read line ; do 
    partition=$(echo $line | awk '{print $2}');
    umount $partition
done;
sleep 2s;



## Partition SD card
##
printf "\n\n [Creating partitions]\n"; 
# Partitions size is in sector, divide the wanted size in bytes by 512 to 
# have an aligned partition
# check with parted (parted /dev/sdb ; > align)
parted --script "$bd" \
    mklabel msdos \
    mkpart primary fat16 2048s 206847s \
    mkpart primary ext4 "${rootfs_first_sector}s" "${rootfs_last_sector}s" \
    mkpart primary ext4 "${datafs_first_sector}s" "${datafs_last_sector}s" \
    set 1 boot on ;



## Format partitions
##
printf "\n\n [formatting partitions]\n"
echo "y\n" | sudo mkfs.vfat "${bd}1";
echo "y\n" | sudo mkfs.ext4 "${bd}2";
echo "y\n" | sudo mkfs.ext4 "${bd}3";



## Mount partitions
##
printf "\n\n[mounting partitions]\n"
mkdir -p "$__boot";
mkdir -p "$__root";
mkdir -p "$__data";
mount "${bd}1" "$__boot";
mount "${bd}2" "$__root";
mount "${bd}3" "$__data";



## Copy and extract file system
##
printf "\n\n [Copying archive]\n"
cp "$__assets"/ArchLinuxARM-rpi-3-latest.tar.gz "$__root/";

printf "\n\n [extracting filesystem]\n"
pushd "$__root";
printf "Check for Errors / IO Error in the following lines :\n"
tar -xvf ArchLinuxARM-rpi-3-latest.tar.gz > .tmp;
cat .tmp | tail -n 2;
rm .tmp;

printf "\n\n [Deleting archive]\n"
rm ArchLinuxARM-rpi-3-latest.tar.gz;
popd;

printf "\n\n [Populating Boot partition]\n"
#mv mnt-rootfs/boot/* mnt-boot/;
mv "$__root"/boot/* "$__boot"/;

printf "\n\n [Flushing IO]\n"
sync;



## Copy over wireless connection profiles
##
printf "\n\n [Copying wifi connection files]\n"
mkdir -p "$__root/etc/NetworkManager/system-connections/";
cp "$__assets"/system-connections/* "$__root"/etc/NetworkManager/system-connections/;
for f in "$__root"/etc/NetworkManager/system-connections/* ; do 
    # Mac addresses of the connection profiles must be changed to match the wifi chip's mac address
    sed -i.bak "s/mac-address=..:..:..:..:..:../mac-address=$wifi_mac_addr/" "$f";
done
rm "$__root"/etc/NetworkManager/system-connections/*.bak;
# Fix permissions 
chown -R root:root "$__root"/etc/NetworkManager/system-connections/;
chmod 700 "$__root"/etc/NetworkManager/system-connections;
chmod -R 600 "$__root"/etc/NetworkManager/system-connections/*;



## Copy over pacman's cache
## NB : Don't touch the pacman database
##
printf "\n\n [Filling pacman packages cache]\n";
cp "$__assets"/pacman-cache/* "$__root"/var/cache/pacman/pkg/
# NOTES : 
    # backup the local pacman database : 
# tar -cjf pacman-database.tar.bz2 /var/lib/pacman/local
    # Restore the pacman database : 
# cd /; tar -xjvf pacman-database.tar.bz2

printf "\n\n [Flushing IO]\n"
sync;



## System setup script and setup-data/
##
printf "\n\n [Copying setup script and data]\n"; 
    # Setup script
cp "$__assets"/setup-system.sh "$__root"/;
chmod +x "$__root"/setup-system.sh;
    # setup-data/
cp -r "$__assets"/setup-data "$__root"/setup-data;
    # root bashrc
cp "$__assets"/bashrc "$__root"/root/.bashrc;
cp "$__assets"/bash_profile "$__root"/root/.bash_profile;



## SSH Setup
##
printf "\n\n [SSH Setup]\n"; 
    # Hostname
printf "quentin-pi" > "$__dir"/mnt-rootfs//etc/hostname;    
    # Allow SSH from everywhere
echo "sshd : ALL : allow" > "$__root"/etc/hosts.allow;
    # Allow ssh login as root
sed -i 's/#PermitRootLogin/PermitRootLogin/' "$__root"/etc/ssh/sshd_config;
sed -i 's/PermitRootLogin [a-z\-]*/PermitRootLogin yes/' "$__root"/etc/ssh/sshd_config;



## Unmount and exit
##
printf "\n\n [unmounting sdcard]\n";
umount "$__boot"; rmdir "$__boot";
umount "$__root"; rmdir "$__root";
umount "$__data"; rmdir "$__data";

printf "\n\n\
Default credentials are : 
    alarm : alarm
    root  :  root
\n";
printf "\
\nOnce the board has booted (~30s)  : 
    (1) connect a shared ethernet profile 
    (2) be patient, dnsmasq.leases takes some time to update
    (3) cat /var/lib/misc/dnsmasq.leases
    (4) ssh root@
    (5) cd /; /setup-system.sh;
\n";

exit 0  ;




























########################################################################
#######################    LEGACY CODE    ##############################
########################################################################
## For reference purpose


echo "You've reached deprecated code";
exit 0;


# Wipe the SD card30881791
fdisk_cmd_clear='';
read -d '' fdisk_cmd_clear <<EOF
o
w
EOF
echo "$fdisk_cmd_clear" | sudo fdisk "$bd";

# 100MB vfat boot partition
fdisk_cmd_boot='';
read -d '' fdisk_cmd_boot <<EOF
n
p
1

+100M
y
t
c
w
EOF
echo "$fdisk_cmd_boot" | sudo fdisk "$bd";

# 9GB ext4 root FS
fdisk_cmd_rootfs='';
read -d '' fdisk_cmd_rootfs <<EOF
n
p
2

19081216
y
w
EOF
echo "$fdisk_cmd_rootfs" | sudo fdisk "$bd";

# Remaining is ext4 data
fdisk_cmd_data='';
read -d '' fdisk_cmd_data <<EOF
n
p
3


y
w
EOF
echo "$fdisk_cmd_data" | sudo fdisk "$bd";




