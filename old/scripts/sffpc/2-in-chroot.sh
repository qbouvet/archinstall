#!/bin/bash -i 


## Init
##
__dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ ! -f "$__dir"/variables.sh ]; then 
    echo "variables.sh not found, exiting"; 
fi
set -o nounset      # exit on unassigned variable
set -o errexit      # exit on error
source "$__dir"/variables.sh



ask_go "    [ fix permissions / ownership on / ]"
if [ "$ask_go_go" == "true" ] ; then 
    chown root:root / 
    chmow 755 /
fi



ask_go "    [ timezone, locale, hostname ]"
if [ "$ask_go_go" == "true" ] ; then 
    ln -sf /usr/share/zoneinfo/Europe/Paris /etc/localtime
    hwclock --systohc

    sed 's|#en_US.UTF-8|en_US.UTF-8|' --in-place /etc/locale.gen
    sed 's|#en_GB.UTF-8|en_GB.UTF-8|' --in-place /etc/locale.gen
    sed 's|#fr_CH.UTF-8|fr_CH.UTF-8|' --in-place /etc/locale.gen
    locale-gen
    
    echo "LANG=en_US.UTF-8" > /etc/locale.conf
    echo "KEYMAP=fr_CH" > /etc/vconsole.conf
    echo "$hostname" > /etc/hostname
    
    printf "
.       127.0.0.1   localhost
.       ::1         localhost
.       127.0.1.1   $hostname.localhost $hostname\n" | sed 's|^\. *||g' >> /etc/hosts
fi



ask_go " [ Users setup ]"
if [ "$ask_go_go" == "true" ] ; then 
    username=''
    passwd=''
    # Root user setup
    printf "\nEnter root password\n>"; read passwd
    echo "root password : $passwd"
    printf "$passwd\n$passwd" | passwd
    # Wheel users setup
    while printf "\nEnter wheel/storage user's username\n>" ; read username && [ "$username" != "" ] ; do 
        printf "enter password\n>"; read passwd;
        echo "User='""$username""' Passsword='""$passwd""'"
        useradd -m -g users -G wheel,storage "$username"
        printf "$passwd\n$passwd" | passwd "$username"
    done
fi



ask_go " [ Pacman --init, --populate, mirrorlist refresh & update ]"
if [ "$ask_go_go" == "true" ] ; then 

    pacman-key --init
    pacman-key --populate archlinux
    
    pacman -Syuu                # these two are required for /usr/bin/rankmirrors
    pacman -S pacman-contrib

    # Ugly enable multilib (sed doesn't support newline char)
    printf "\n\n##Enable multilib : \n##\n[multilib]\nInclude = /etc/pacman.d/mirrorlist\n" >> /etc/pacman.conf

    function init_mirrorlist {
        mirrorfile="/etc/pacman.d/mirrorlist"
        cp "$mirrorfile" "$mirrorfile.bak"
        echo "# Mirrorlist generated with : " > "$mirrorfile"
        echo '# curl -s "https://www.archlinux.org/mirrorlist/?country=FR&country=GB&country=DE&protocol=https&use_mirror_status=on" | sed -e "s/^#Server/Server/" -e "/^#/d" | rankmirrors -n 5 -' >> "$mirrorfile"
        echo "# cf https://wiki.archlinux.org/index.php/mirrors#List_by_speed" >> "$mirrorfile"
        echo "" >> "$mirrorfile"
        curl -s "https://www.archlinux.org/mirrorlist/?country=FR&country=GB&country=DE&protocol=https&use_mirror_status=on" | sed -e "s/^#Server/Server/" -e "/^#/d" | rankmirrors -n 5 - >> "$mirrorfile"
    }
    init_mirrorlist
    
    pacman -Syuu
fi



ask_go " [ Pacman packages installation ]"
if [ "$ask_go_go" == "true" ] ; then
    pacman -S ${packages[@]}
fi



ask_go " [ aurman installation ]"
if [ "$ask_go_go" == "true" ] ; then
    pacman -S expac python-requests python-regex git pyalpm python-dateutil python-feedparser   
    mkdir /build; pushd /build;
    wget https://aur.archlinux.org/cgit/aur.git/snapshot/aurman.tar.gz
    tar -xvf aurman.tar.gz
    cd aurman
    chown quentin:users -R /build
    sudo -u quentin makepkg -s -f --skippgpcheck
    pacman -U aurman*.tar.xz
    popd; rm -rf build;

    # Need to configure sudo to use aurman
    printf '\n\n##Personal configuration : \n##\n' | sudo EDITOR='tee -a' visudo;
    echo '%wheel ALL=(ALL) ALL' | sudo EDITOR='tee -a' visudo;
fi 



ask_go " [ AUR packages installation (cf. 0-variables.sh) ]"
if [ "$ask_go_go" == "true" ] ; then
    sudo -u quentin aurman -S ${packages_aur[@]}
fi



systemctl enable NetworkManager



ask_go " [ Autostart fan_ctl.sh ]"
if [ "$ask_go_go" == "true" ] ; then
	if [ -f /scripts/fan_ctl.sh ] ; then
        cp /scripts/fan_ctl.sh /root/fan_ctl.sh
    else 
		echo "WARNING : file /scripts/fan_ctl.sh does not exist ! "
        echo "          as a result, you need to copy it manually to /root/fan_ctl.sh"
	fi
    
    # ! should this go in /etc/systemd/multi-user.target.wants/ ?
	printf "# /etc/systemd/system/fan_ctl.service
.   [Unit]
.   Description=Starts fan control at boot.
.   [Service]
.   Type=simple
.   ExecStart=/bin/bash /root/fan_ctl.sh
.   TimeoutSec=0
.   RemainAfterExit=yes
.   [Install]
.   WantedBy=multi-user.target	
.   " | sed 's|^\. *||g' > /etc/systemd/system/fan_ctl.service
	systemctl start fan_ctl.service
	systemctl enable fan_ctl.service
	if ! [ -f /root/fan_ctl.sh ] ; then
		echo "WARNING : file /root/fan_ctl.sh does not exist"
		echo "          Don't forget to set it up !!!"
	fi
fi


ask_go " [ Swap configuration ]"
if [ "$ask_go_go" == "true" ] ; then
    fallocate -l "$swap_file_size" "$swap_file_path"
    chmod 600 "$swap_file_path"
    mkswap "$swap_file_path"
    swapon "$swap_file_path"
    printf "\n\n#Swap file\n$swap_file_path \tnone \tswap \tdefaults \t0 \t0\n" >> /etc/fstab 
    printf "vm.swappiness=$swappiness\n" > /etc/sysctl.d/99-sysctl.conf
fi


ask_go " [ Disks mounts settings for storage group]"
if [ "$ask_go_go" == "true" ] ; then
        # Allow users in the 'storage' group to mount / unmount drives via pcmanfm
	printf '\
.   polkit.addRule(function(action, subject) {
.       if ((action.id == "org.freedesktop.udisks2.filesystem-mount-system" &&
.       subject.local && subject.active && subject.isInGroup("storage")))
.       {
.           return polkit.Result.YES;
.       }
.   });
.   ' | sed 's|^\.   ||g' >/etc/polkit-1/rules.d/00-mount-internal.rules
fi


ask_go " [ Bootloader/grub install ]"
if [ "$ask_go_go" == "true" ] ; then
    # https://wiki.archlinux.org/index.php/GRUB
        
        # Install
    pacman -S grub efibootmgr os-prober
    grub-install --target=x86_64-efi --efi-directory="$mnt_esp" --bootloader-id=GRUB-ARCH-MAIN
        
        # Customize
    printf '
.   menuentry "System shutdown" {
.       echo "System shutting down..."
.       halt
.   }\n\n' | sed 's|^\.   ||g' >> /boot/grub/custom.cfg
    printf '
.   menuentry "Firmware setup" {
.       echo "running firmware-setup"
.       fwsetup
.   }\n\n' | sed 's|^\.   ||g' >> /boot/grub/custom.cfg
        
        # Generate file
    grub-mkconfig -o /boot/grub/grub.cfg
fi


exit; 
