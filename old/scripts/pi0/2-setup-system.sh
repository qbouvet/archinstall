#!/usr/bin/env bash

  #
  #   Initial setup, imports, requires
  #
function prepare () {
    set -o nounset      # exit on unassigned variable
    set -o errexit      # exit on error
    set -o pipefail     # exit on pipe fail
  # Set execution directory
    export __dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)";
    pushd "$__dir";
  # Source variables
    source "${__dir}/0-config.sh"
  # Report
    report="REPORT:"
}
# Acquire root
[ "$UID" -eq 0 ] || exec sudo bash "$0" "$@";
prepare



  # Users setup
  #
function conf_users {
  # new root password
    printf "$rootpw\n$rootpw" | passwd ;  # root password
  # new user
    useradd -m -g users -G wheel "$username";
    printf "$userpw\n$userpw" | passwd "$username";
    chown -R "$username":users "/home/${username}"
  # fix permissions
    chown -R "$username:users" "/home/$username";
    chown -R "$username":users /opt;
  # remove default user
    userdel alarm;
    rm -rf /home/alarm;
  # autostart-login.sh
    # TODO (not really useful)
}
ask_go "Configure users" conf_users


  # Pacman update, packages installation
  #
function run_pacman {
  # Setup pacman - NB: mirrors are arm-specific - don't change them
    pacman-key --init
    pacman-key --populate archlinuxarm
  # update system
    pacman -Syu;
  # install packages
    pacman -S "${packages[@]}" --noconfirm;
  # wipe cache, save space
    sudo pacman -Scc
}
ask_go "Pacman setup & packages installation" run_pacman


  # sudoers configuration
  #
function conf_sudo {
    append "/etc/sudoers" '
      # Personal configuration :
      #
    # Allow all wheel users to use sudo
    %%wheel ALL=(ALL) ALL'
}
ask_go "Configure sudo" conf_sudo


  # Tentative aurman installation
  #
# Dependancies must be resolved manually
function install_aurman {
    aur_install aurman --skippgpcheck
    sudo -u "$username" aurman -S "${packages_aur[@]}" \
      --noconfirm --skip_news --skip_new_locations;
}
ask_go "Install AURman & packages" install_aurman


  # Swap
  #
function conf_swap {
  # Swappiness
    overwrite "/etc/sysctl.d/99-sysctl.conf" "vm.swappiness=$swappiness"
  # Swap
    fallocate -l "$swapfile_size" "$swapfile_path";
    chmod 600 "$swapfile_path";
    mkswap "$swapfile_path";
    swapon "$swapfile_path";
    append "/etc/fstab" "$swapfile_path \tnone \tswap \tdefaults \t0 \t0"
    printf "\n\nThe following swaps are now active : \n";
    swapon;
}
ask_go "[Configure swap]" conf_swap;


  # ...
  #
function conf_misc {
  # Locale
    uncomment "/etc/locale.gen" "en_US.UTF-8 UTF-8"
    locale-gen;
    overwrite "/etc/locale.conf" "LANG=en_US.UTF-8"
    localectl set-locale LANG=en_US.UTF-8;
  # Time synchronization
    timedatectl set-ntp true;
  # System autostart.#!/bin/sh
    chmod +x /root/autostart-system.sh;
    chmod 744 /etc/systemd/system/autostart-system.service;
    systemctl enable autostart-system.service;
  # Rectify SSH login permissions
    comment "${__root}/etc/ssh/sshd_config" "PermitRootLogin"
    append "${__root}/etc/ssh/sshd_config" "\nPermitRootLogin no\n"
    report="${report}\n\n    ssh:
        1.  Root login no longer allowed\
    "
}
ask_go "locale, time synchronization, autostart" conf_misc




## Exit
##
report="${report}
    System:
        1.  Updates & essential packages have been installed.
        2.  User '$username' has been added
        3.  A startup script at /root/autostart-system.sh has been configured.
";
printf "\n\n${report}"
popd > /dev/null;
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
