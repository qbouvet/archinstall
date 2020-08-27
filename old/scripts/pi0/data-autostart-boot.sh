#!/usr/bin/env bash

##  /autostart.sh
##
##  This script is executed at startup by
##  /etc/systemd/system/autostart.sh.service
##
##  It runs with root priviledge.
##


## Variables
##
__dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)";
__log=${__dir}/autostart-boot.sh.log
source "$HOME"/.bashrc;


## Redirect outputs to log file
##
rm $log;
exec 1<&-;          # Close STDOUT file descriptor
exec 2<&-;          # Close STDERR FD
exec 1<>"$__log";   # Open STDOUT as $log file for read and write.
exec 2>&1;          # Redirect STDERR to STDOUT


## Init log, test sudo and log running time
##
printf "\n\n [Date] ";
date;
sleep 2s;


printf "\n\n  /root/autostart-boot.sh -> done\n"
exit 0;












########################################################################
#######################    LEGACY CODE    ##############################
########################################################################
## For reference later
echo "You've reachd deprecated code"; exit 1;


##  Autoconnects to a given acces point
##
function nmcli_connect {
    printf "\n\n [nmcli_connect()]\n"
    systemctl start NetworkManager;
    sleep 2s;
    nmcli radio wifi on;
    nmcli device connect wlan0;
    #nmcli connection up "Airbox Sosh-FA9B"; # Fails
    nmcli connection up uuid 12a49b12-9cfe-47d1-a587-1df9dc703b3c
}

#   nmcli_connect
