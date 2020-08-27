#!/usr/bin/env bash


## Acquire root
##
[ "$UID" -eq 0 ] || exec sudo bash "$0" "$@";



########################################################################
#####################    SYSTEM SETUP    ###############################
########################################################################


## Parameters
##
uname="quentin";
pwd="";
printf "\nEnter a password for user $uname\n>"
read pwd;
rootpwd=""
printf "\nEnter a root password\n>"
read rootpwd;



## Users setup
## 
printf "\n\n [Setting up users and passwords]\n"
useradd -m -g users -G wheel "$uname"; 
printf "$pwd\n$pwd" | passwd "$uname";  # user password
printf "$rootpwd\n$rootpwd" | passwd ;  # root password
userdel alarm;



## Updates
##
printf "\n\n [Updating packages]\n"
# NB : mirrors are arm-specific mirrors
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



## autostart-boot.sh
##
printf "\n\n [Generating autostart-boot.sh.service]\n"
    # Setup autostart.sh
chmod +x /autostart-boot.sh;
    # Systemd service to start it up
cat >/etc/systemd/system/autostart-boot.sh.service <<EOF
# /etc/systemd/system/autostart.sh.service

[Unit]
Description=Starts /autostart-boot.sh at boot.

[Service]
#Type=oneshot              # 'oneshot'/'forking' -> neither works
ExecStart=/autostart.sh
TimeoutSec=0
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
# Doesn't work - do it manually in /autostart.sh
#After=network.target NetworkManager.service
EOF
chmod 744 /etc/systemd/system/autostart-boot.sh.service;
systemctl enable autostart-boot.sh.service;



## Misceleanous
##
printf "\n\n [Misceleanous]\n"
    # Time synchronization
timedatectl set-ntp true;
    # user bashrc
mv bashrc-user /home/"$uname"/.bashrc;
    # /opt ownership
chown "$uname":users /opt;
    # fix user's home permissions
chown -R "$uname:users" /home/"$uname"/




########################################################################
#######################    USER SETUP    ###############################
########################################################################


## Automatically login user 
##
printf "\n\n [auto-login on tty1]\n"
mkdir -p /etc/systemd/system/getty@tty1.service.d/;
cat >/etc/systemd/system/getty@tty1.service.d/override.conf <<EOF
# /etc/systemd/system/getty@tty1.service.d/override.conf
# Auto-login $uname at startup

[Service]
ExecStart=
ExecStart=-/usr/bin/agetty --autologin $uname --noclear %I \$TERM
EOF
echo "Done - check result with 'systemctl edit getty@tty1'"
# From : 
#   https://wiki.archlinux.org/index.php/getty#Automatic_login_to_virtual_console
# Note : multiple getty : 
#   https://wiki.archlinux.org/index.php/Systemd_FAQ#How_do_I_change_the_default_number_of_gettys.3F



## autostart-login.sh
## 
printf "\n\n [autostart-login.sh]\n"
    # Put autostart.sh in user directory
mv /autostart-login.sh /home/"$uname"/autostart-login.sh
chmod +x /home/"$uname"/autostart-login.sh;
    # Systemd service to start it up
mkdir -p /home/"$uname"/.config/systemd/user/;
cat >/home/"$uname"/.config/systemd/user/autostart-login.sh.service  <<EOF
#Also sent service to /etc/systemd/user/ but I don't think it's relevant
#cat >>/etc/systemd/user/autostart-login.sh.service  <<EOF
# ~/.config/systemd/user/autostart-login.sh.service

[Unit]
Description="$uname" - autostart-login.sh

[Service]
ExecStart=%h/autostart-login.sh

[Install]
WantedBy=default.target
EOF
    # Permission fix absolutely needed - we created all as root
chown -R "$uname:users" /home/"$uname"/            
chmod 744 /home/"$uname"/.config/systemd/user/autostart-login.sh.service;
    # manually start `systemctl --user` for $uname before being able to enable the service
    # cd https://unix.stackexchange.com/questions/423632/systemctl-user-not-available-for-www-data-user
sudo install -d -o "$uname" /run/user/`id -u "$uname"`;
sudo systemctl start user@`id -u "$uname"`;
sudo -u "$uname" DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/`id -u "$uname"`/bus systemctl --user enable autostart-login.sh    ;



printf "\n\n\n Exit : Features below are untester / likely don't work\n\n";
exit 0;



## Test : "run-as-user" kind of function, with correct dbus
##
user_systemctl_started=0;
function user_run {
    if [ "$user_systemctl_started" -eq "0" ] ; then
        printf "\n\n [user_run : starting systemctl --user manually]\n";
        sudo install -d -o "$uname" /run/user/`id -u "$uname"`;
        sudo systemctl start user@`id -u "$uname"`;
        user_systemctl_started=1;
    fi
    
    printf "\n\n [user_run]\n";
    sudo -u "$uname" DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/`id -u "$uname"`/bus \
        bash -c "$@";
        
    printf "\n [user_run : done]\n";
}



## Github setup - Untested - ssh agent doesn't work
##
printf "\n\n [ssh-agent & git setup]\n"
    # SSH-agent service setup
mkdir -p /home/"$uname"/.config/systemd/user/;
cat >/home/"$uname"/.config/systemd/user/ssh-agent.service <<EOF
[Unit]
Description=SSH key agent

[Service]
Type=simple
Environment=SSH_AUTH_SOCK=%t/ssh-agent.socket
ExecStart=/usr/bin/ssh-agent -D -a \$SSH_AUTH_SOCK

[Install]
WantedBy=default.target    
EOF
echo 'SSH_AUTH_SOCK DEFAULT="${XDG_RUNTIME_DIR}/ssh-agent.socket"' >> /home/"$uname"/.pam_environment;
# Normally done beforehands
#sudo install -d -o "$uname" /run/user/`id -u "$uname"`;
#sudo systemctl start user@`id -u "$uname"`;
user_run 'systemctl --user enable ssh-agent; \
          systemctl --user start ssh-agent;'
#sudo -u "$uname" DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/`id -u "$uname"`/bus systemctl --user enable ssh-agent;
#sudo -u "$uname" DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/`id -u "$uname"`/bus systemctl --user start ssh-agent;
    # SSH keys setup : 'remember keys' setting + enter key once
mkdir -p /home/"$uname"/.ssh/;
echo "AddKeysToAgent yes" > /home/"$uname"/.ssh/config;
#sudo -u "$uname" eval `ssh-agent -s`;
#ls /home/"$uname"/.ssh/ | grep -v ".pub" | while read key ; do 
#    sudo -u "$uname" ssh-add "$key";        
#done;
user_run 'eval `ssh-agent -s`;
        ls ~/.ssh/ | grep -v ".pub" | while read key ; do 
            ssh-add "$key";        
        done;
        cd ~/rbpi-git;
        echo a > ip;
        git add ip;
        git commit -m "m";
        git push'
    # Repository setup
mkdir -p /home/"$uname"/rbpi-git;
pushd /home/"$uname"/rbpi-git;
git config --global user.email "quentin.bouvet@hotmail.fr";
git config --global user.name "quentin";
git init;
git remote add origin git@github.com:sgPepper/rbpi.git;
git pull origin master;
popd;


## Cleanup
##
# Todo



## TODO
##
# Firewall - https://wiki.archlinux.org/index.php/Uncomplicated_Firewall



## Exit
##
printf "\n\n
  (1)   Updates have been installed. 

  (2)   The board should now be able to automatically connect 
        to known wifi networks at boot.

  (3)   Users have been added
 
  (4)   A startup script at /startup.sh has been configured.

  Please setup the sudoers, and remove the 'alarm' user next login : 
    $ EDITOR=nano visudo 
    [logout, log back in] 
    $ userdel -r alarm 
";

exit 0

