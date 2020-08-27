#!/usr/bin/env bash


## Parameters
##
wifi_mac_addr="B8:27:EB:EF:87:F8";   # board's Wi-fi chip mac address
rootfs_first_sector="206848";        # Sectors are sdcard-dependant
rootfs_last_sector="19081215";
datafs_first_sector="19081216";
datafs_last_sector="30881791";
__dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)";
cd $__dir;



## Acquire root
##
[ "$UID" -eq 0 ] || exec sudo bash "$0" "$@";



## Acquire block device path
##
lsblk;
printf "\n\tPlease enter the block device path (/dev/sdX)\n>";
bd="";
read bd;
printf "\n\nBlock device is $bd\n";
printf "\nPlease confirm";
read;



## Unmount block device's partitions
##
printf "\n\n[Unmounting partitions on $bd]\n"
cat /proc/mounts | grep $bd | while read line ; do 
    partition=$(echo $line | awk '{print $2}');
    umount $partition
done;
sleep 2s;



## Partition SD card
##
printf "\n\n[Creating partitions]\n"; 
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
printf "\n\n[formatting ${bd}1]\n"
echo "y\n" | sudo mkfs.vfat "${bd}1";
printf "\n[formatting ${bd}2]\n"
echo "y\n" | sudo mkfs.ext4 "${bd}2";
printf "\n[formatting ${bd}3]\n"
echo "y\n" | sudo mkfs.ext4 "${bd}3";



## Mount partitions
##
printf "\n\n[mounting partitions]\n"
mkdir -p "$__dir"/mnt-boot;
mkdir -p "$__dir"/mnt-rootfs;
mkdir -p "$__dir"/mnt-datafs;
mount "${bd}1" "$__dir"/mnt-boot;
mount "${bd}2" "$__dir"/mnt-rootfs;
mount "${bd}3" "$__dir"/mnt-datafs;



## Copy and extract file system
##
printf "\n\n[Copying archive]\n"
cp "${__dir}/data/ArchLinuxARM-rpi-3-latest.tar.gz" "$__dir/mnt-rootfs/";
pushd "$__dir/mnt-rootfs";

printf "\n\n[extracting filesystem]\n"
printf "\n\n[extracting filesystem]\n" &> "${__dir}/tar.log";
tar -xvf ArchLinuxARM-rpi-3-latest.tar.gz &>> "${__dir}/tar.log";
tail -n 2 "${__dir}/tar.log";   # Show possible error

printf "\n\n[Deleting archive]\n"
rm ArchLinuxARM-rpi-3-latest.tar.gz;
popd;

printf "\n\n[Populating Boot partition]\n"
# (?)
#sudo mv "${__dir}"/mnt-rootfs/boot/* "${__dir}"/mnt-boot/;
mv mnt-rootfs/boot/* mnt-boot/;

printf "\n\n[Flushing IO]\n"
sync;



## Copy over wireless connection profiles
##
printf "\n\n[Copying wifi connection files]\n"
mkdir -p "$__dir/mnt-rootfs/etc/NetworkManager/system-connections/";
cp "$__dir"/data/system-connections/* "$__dir"/mnt-rootfs/etc/NetworkManager/system-connections/;
for f in "$__dir"/mnt-rootfs/etc/NetworkManager/system-connections/* ; do 
    # Mac addresses of the connection profiles must be changed to match the wifi chip's mac address
    sed -i.bak "s/mac-address=..:..:..:..:..:../mac-address=$wifi_mac_addr/" "$f";
done
rm "$__dir"/mnt-rootfs/etc/NetworkManager/system-connections/*.bak;
# Fix permissions 
chown -R root:root "$__dir"/mnt-rootfs/etc/NetworkManager/system-connections/;
chmod 700 "$__dir"/mnt-rootfs/etc/NetworkManager/system-connections;
chmod -R 600 "$__dir"/mnt-rootfs/etc/NetworkManager/system-connections/*;



## Copy over pacman's cache
## NB : Don't touch the pacman database
##
printf "\n\n[Filling pacman packages cache]\n";
cp "$__dir"/data/pacman-cache/* "$__dir"/mnt-rootfs/var/cache/pacman/pkg/
# NOTES : 
    # backup the local pacman database : 
# tar -cjf pacman-database.tar.bz2 /var/lib/pacman/local
    # Restore the pacman database : 
# cd /; tar -xjvf pacman-database.tar.bz2

printf "\n\n[Flushing IO]\n"
sync;



## Startup Script & setup script
##
printf "\n\n[Copying setup and autostart scripts]\n"; 
    # Setup script
cp "$__dir"/data/oneTimeSetup.sh "$__dir"/mnt-rootfs/oneTimeSetup.sh;
    # boot autostart script
cp "$__dir"/data/autostart-boot.sh "$__dir"/mnt-rootfs/autostart-boot.sh;
    # login autostart script
cp "$__dir"/data/autostart-login.sh "$__dir"/mnt-rootfs/;
    # user bashrc
cp "$__dir"/data/bashrc-user "$__dir"/mnt-rootfs/;
    # root bashrc
cp "$__dir"/data/bashrc-user "$__dir"/mnt-rootfs/root/.bashrc



## SSH Setup
##
printf "\n\n[SSH Setup]\n"; 
    # Hostname
printf "quentin-pi" > "$__dir"/mnt-rootfs//etc/hostname;    
    # Allow SSH from everywhere
echo "sshd : ALL : allow" > /etc/hosts.allow;"$__dir"/mnt-rootfs/
    # Allow ssh login as root
sed -i 's/#PermitRootLogin/PermitRootLogin/' "$__dir"/mnt-rootfs//etc/ssh/sshd_config;
sed -i 's/PermitRootLogin [a-z\-]*/PermitRootLogin yes/' "$__dir"/mnt-rootfs//etc/ssh/sshd_config;



## Unmount and exit
##
printf "\n\n[unmounting sdcard]\n";
umount "$__dir/mnt-boot";
umount "$__dir/mnt-rootfs";
umount "$__dir/mnt-datafs";

printf "\n\n\
Default credentials are : 
    alarm : alarm
    root  :  root
\n";
printf "\
\nOnce the board has booted (~30s)  : 
    (1) connect a shared ethernet profile
    (2) cat /var/lib/misc/dnsmasq.leases
    (3) ssh root@
    (5) cd /; chmod +x /oneTimeSetup.sh; /oneTimeSetup.sh;
\n";

exit 0  ;





















########################################################################
##
##  LEGACY CODE

exit 0 ;

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




