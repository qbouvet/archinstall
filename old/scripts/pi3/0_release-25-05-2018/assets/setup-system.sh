#!/usr/bin/env bash


## Run me as root
##
[ "$UID" -eq 0 ] || exec sudo bash "$0" "$@";



## Variables
##
    # users and passwords
printf "\nChoose a user name\n>"
_user=""; read _user;
printf "\nEnter a password for user $_user\n>"
pwd=""; read pwd;
printf "\nEnter a root password\n>"
rootpwd=""; read rootpwd;
    # paths
__dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)";
__data="/setup-data";
__home=/home/"$_user";



## Users setup
## 
printf "\n\n [Configuring users accounts]\n"
useradd -m -g users -G wheel "$_user"; 
printf "$pwd\n$pwd" | passwd "$_user";  # user password
printf "$rootpwd\n$rootpwd" | passwd ;  # root password
userdel alarm;



## Updates
##
printf "\n\n [Updating packages]\n"
# NB : mirrors are arm-specific mirrors - don't change them
printf "Y\n" | pacman -Syuu;



## Install packages
## 
packages=(core/sudo
          extra/networkmanager
          extra/networkmanager-openconnect 
          extra/networkmanager-openvpn
          extra/dnsmasq
          extra/bluez
          extra/bluez-utils
          community/syncthing
          community/syncthing-relaysrv
          alarm/firmware-raspberrypi
          alarm/libbcm2835 
          extra/git
          );          

printf "Y\n" | pacman -S ${packages[@]};



## start / enable NetworkManager
##
printf "\n\n [Enabling NetworkManager]\n"
systemctl start NetworkManager;
systemctl enable NetworkManager;



## autostart-boot.sh - doesn't work
##
printf "\n\n [Generating autostart-boot.sh.service]\n"
    # Setup autostart.sh
cp "$__data"/autostart-boot.sh /autostart-boot.sh    
chmod +x /autostart-boot.sh;
    # Systemd service to start it up
cat >/etc/systemd/system/autostart-boot.sh.service <<EOF
# /etc/systemd/system/autostart-boot.sh.service

[Unit]
Description=Starts /autostart-boot.sh at boot.

[Service]
Type=forking
ExecStart=/bin/bash /autostart-boot.sh
TimeoutSec=0
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
# Doesn't work - do it manually in /autostart.sh
#After=network.target NetworkManager.service
EOF
chmod 744 /etc/systemd/system/autostart-boot.sh.service;
systemctl enable autostart-boot.sh.service;



## Automatically login user 
##
printf "\n\n [User auto-login on tty1]\n"
# cf : https://wiki.archlinux.org/index.php/getty#Automatic_login_to_virtual_console
#      https://wiki.archlinux.org/index.php/Systemd_FAQ#How_do_I_change_the_default_number_of_gettys.3F
mkdir -p /etc/systemd/system/getty@tty1.service.d/;
cat >/etc/systemd/system/getty@tty1.service.d/override.conf <<EOF
# /etc/systemd/system/getty@tty1.service.d/override.conf
# Auto-login $USER at startup

[Service]
ExecStart=
ExecStart=-/usr/bin/agetty --autologin $_user --noclear %I \$TERM
EOF



## sudoers configuration
##
printf "\n\n [Configuring sudo]\n"
printf '

##Personal configuration : 
##
' | sudo EDITOR='tee -a' visudo;
echo '%wheel ALL=(ALL) ALL' | sudo EDITOR='tee -a' visudo;



## Misceleanous
##
printf "\n\n [Misceleanous]\n"
    # Locale 
    # enable fr_CH and en_US, activate fr_CH    
sed -i 's/#fr_CH.UTF-8 UTF-8/fr_CH.UTF-8 UTF-8/' "$__root"/etc/locale.gen;
sed -i 's/#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' "$__root"/etc/locale.gen;
sed -i 's/#en_GB.UTF-8 UTF-8/en_GB.UTF-8 UTF-8/' "$__root"/etc/locale.gen;
locale-gen;
printf "LANG=en_GB.UTF-8\nLANGUAGE=en_GB.UTF-8:en_US.UTF-8\n" > /etc/locale.conf;
localectl set-locale LANG=fr_CH.UTF-8;    
    # Time synchronization
timedatectl set-ntp true;
    # /opt ownership
chown "$_user":users /opt;
    # user bashrc
cp "$__data"/bashrc "$__home"/.bashrc;
cp "$__data"/bash_profile "$__home"/.bash_profile;
    # setup-user.sh
cp "$__data"/setup-user.sh "$__home"/;
chmod +x "$__home"/setup-user.sh;
    # fix user's home permissions
chown -R "$_user:users" "$__home"/;



## Cleanup
##
# Todo (?)



## TODO
##
# Firewall - https://wiki.archlinux.org/index.php/Uncomplicated_Firewall



## Exit
##
printf "\n\n
  (1)   Updates have been installed. 
  
  (2)   Users have been added
  
  (3)   A startup script at /startup.sh has been configured.
  
  (4)   Please login as $_user and run ./setup-user.sh


  (?)   The board should now be able to automatically connect 
        to known wifi networks at boot.

";

logout; # logout of ssh ?
exit 0;




























########################################################################
#######################    LEGACY CODE    ##############################
########################################################################
## For reference purpose


echo "You've reached deprecated code";
exit 0;


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
