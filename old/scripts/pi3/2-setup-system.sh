#!/usr/bin/env bash


## Setup
##
    # Error codes
set -o nounset      # exit on unassigned variable
set -o errexit      # exit on error
set -o pipefail     # exit on pipe fail

    # Acquire root
[ "$UID" -eq 0 ] || exec sudo bash "$0" "$@";

    # Set execution director
export __dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)";
pushd $__dir;

    # Source variables
source 0-config.sh




## Users setup
## 
function config_user_account {
        # new root password
    printf "$rootpw\n$rootpw" | passwd ;  # root password
        # new user
    useradd -m -g users -G wheel "$username"; 
    printf "$userpw\n$userpw" | passwd "$username";
        # remove alarm user -> in use, do it during user setup    
    #userdel alarm;
    #rm -rf /home/alarm;
}
ask_go "[Configuring users accounts]" config_user_account




## Pacman update, packages installation
##
function pacman_setup_packages_install {
        # Setup pacman
    pacman-key --init
    pacman-key --populate archlinuxarm
    # NB : mirrors are arm-specific mirrors - don't change them
        # update system
    pacman -Syuu;
        # install packages
    pacman -S ${packages[@]};
        # wipe cache, save space
    sudo paccache -rk 0
}
ask_go "[Pacman setup & packages installation]" pacman_setup_packages_install




## sudoers configuration
##
function configure_sudo {
    printf '

    ## Personal configuration : 
    ##
        # Allow all wheel users to use sudo
    %%wheel ALL=(ALL) ALL
    ' | sed 's|    ||' | sudo EDITOR='tee -a' visudo;
}
ask_go "[Configure sudo]" configure_sudo




## Tentative aurman installation
##
    # This will typically fail due to dependancies, check them first
function install_aurman {
    ugly_aur_install https://aur.archlinux.org/cgit/aur.git/snapshot/aurman.tar.gz --skippgpcheck
    sudo -u "$username" aurman -S ${packages_aur[@]};
}
ask_go "[Tentative-install aurman and aur packages]" install_aurman




## Swap
##
function configure_swap {
        # Swappiness
    echo "vm.swappiness=$swappiness" > /etc/sysctl.d/99-sysctl.conf;
        # Swap
    fallocate -l "$swapfile_size" "$swapfile_path";
    chmod 600 "$swapfile_path";
    mkswap "$swapfile_path";
    swapon "$swapfile_path";
    printf "$swapfile_path \tnone \tswap \tdefaults \t0 \t0" >> /etc/fstab;
    printf "\n\nThe following swaps are now active : \n";
    swapon;
}
ask_go "[Configure swap]" configure_swap;




## Swap
##
function enable_zswap {
    sed 's|MODULES=(|MODULES=(lz4 lz4_compress |' -i /etc/mkinitcpio.conf;
    mkinitcpio -g /boot/initramfs.img;
    touch /boot/cmdline.txt;
    echo " zswap.enabled=1 zswap.compressor=lz4 zswap.max_pool_percent=35 zswap.zpool=z3fold" >> /boot/cmdline.txt;
}
ask_go "[Enable zswap [ !! Requires some swap to exist ] ( + verify results with 'dmesg | grep zswap')]" enable_zswap;




function misc {
        # Locale 
        # enable fr_CH and en_US, activate fr_CH    
    sed -i 's/#fr_CH.UTF-8 UTF-8/fr_CH.UTF-8 UTF-8/' /etc/locale.gen;
    sed -i 's/#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen;
    sed -i 's/#en_GB.UTF-8 UTF-8/en_GB.UTF-8 UTF-8/' /etc/locale.gen;
    locale-gen;
    echo "LANG=en_GB.UTF-8\nLANGUAGE=en_GB.UTF-8:en_US.UTF-8" > /etc/locale.conf;
    localectl set-locale LANG=en_US.UTF-8;    
    
        # Time synchronization
    timedatectl set-ntp true;
    
        # fix permissions
    chown -R "$username:users" "/home/$username";
    chown -R "$username":users /opt;
}
ask_go "[locale, time & misc]" misc




## autostart-boot.sh - doesn't work
##
function autostart_boot_sh {
        # Setup autostart.sh
    cp "data-autostart-boot.sh" /root/autostart-boot.sh
    chmod +x /root/autostart-boot.sh;
        # Systemd service to start it up
    printf "
    # /etc/systemd/system/autostart-boot.service

    [Unit]
    Description=Starts /root/autostart-boot.sh at boot.

    [Service]
    Type=forking
    ExecStart=/bin/bash /root/autostart-boot.sh
    TimeoutSec=0
    RemainAfterExit=yes

    [Install]
    WantedBy=multi-user.target
    # Doesn't work - wait manually in /autostart.sh
    #After=network.target NetworkManager.service
    " | sed 's|    ||' >/etc/systemd/system/autostart-boot.service
    chmod 744 /etc/systemd/system/autostart-boot.service;
    systemctl enable autostart-boot.service;
}
ask_go "[Setup autostart-boot.sh]" autostart_boot_sh




function configfiles {
    cp data-bashrc /root/.bashrc
    cp data-bashrc /home/${username}/.bashrc
    cp data-bashrc /root/.bash_profile
    cp data-bashrc /home/${username}/.bash_profile
}
ask_go "[Copy additionnal config files]" configfiles




## Exit
##
popd;
printf "\n\n
  (1)   Updates & essential packages have been installed. 
  
  (2)   User has been added
  
  (3)   A startup script at /root/autostart-boot.sh has been configured.
  
  (4)   Please login as $username and run ./3-setup-user.sh

";
exit 0;






















########################################################################
#######################    LEGACY CODE    ##############################
########################################################################
## For reference later


echo "You've reached deprecated code";
exit 0;



## Automatically login user 
##
ask_go "\n\n [User auto-login on tty1]\n"
if [ "$ask_go_go" == "true" ] ; then 
    # cf : https://wiki.archlinux.org/index.php/getty#Automatic_login_to_virtual_console
    #      https://wiki.archlinux.org/index.php/Systemd_FAQ#How_do_I_change_the_default_number_of_gettys.3F
    mkdir -p /etc/systemd/system/getty@tty1.service.d/;
    printf "
# /etc/systemd/system/getty@tty1.service.d/override.conf
# Auto-login $USER at startup

[Service]
ExecStart=
ExecStart=-/usr/bin/agetty --autologin $_user --noclear %I \$TERM
"   >/etc/systemd/system/getty@tty1.service.d/override.conf
fi

printf "\n\ntesting features\n\n"


## Fstab
##
ask_go "\n\n [Configuring mounts]\n"; 
if [ "$ask_go_go" == "true" ] ; then 
    datafs_uid=$(blkid -o value -s UUID $datafs_blkdev);
    mkdir -p "$datafs_mountpoint"
    mount "$datafs_blkdev" "$datafs_mountpoint";
            # <file system>      <dir>                <type> <options>            <dump> <pass>
    printf "\nUUID=$datafs_uid \t$datafs_mountpoint \text4 \t$datafs_mount_opt \t0 \t0 \n" >> /etc/fstab;
fi







## On running systemctl --user as a root (when no user has logged in)
##
    # manually start `systemctl --user` for $_user before being able to enable the service
    # cd https://unix.stackexchange.com/questions/423632/systemctl-user-not-available-for-www-data-user
sudo install -d -o "$_user" /run/user/`id -u "$_user"`;
sudo systemctl start user@`id -u "$_user"`;
sudo -u "$_user" DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/`id -u "$_user"`/bus systemctl --user enable autostart-login.sh    ;


## Similarily (homemade - kinda shitty)
##
user_systemctl_started=0;
function user_run {
    if [ "$user_systemctl_started" -eq "0" ] ; then
        printf "\n\n [user_run : starting systemctl --user manually]\n";
        sudo install -d -o "$_user" /run/user/`id -u "$_user"`;
        sudo systemctl start user@`id -u "$_user"`;
        user_systemctl_started=1;
    fi
    
    printf "\n\n [user_run]\n";
    sudo -u "$_user" DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/`id -u "$_user"`/bus \
        bash -c "$@";
        
    printf "\n [user_run : done]\n";
}
