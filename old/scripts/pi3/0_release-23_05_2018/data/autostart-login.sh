#!/usr/bin/env bash

##
##  ~/autostart.sh
##  This script is run at user login
##


## Variables
##
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)";
log="$dir"/autostart-login.sh.log


## Redirect outputs to log file
##
rm $log;
exec 1<&-;      # Close STDOUT file descriptor
exec 2<&-;      # Close STDERR FD
exec 1<>"$log"; # Open STDOUT as $log file for read and write.
exec 2>&1;      # Redirect STDERR to STDOUT


printf "\n\n [Timedatectl]\n";
echo $(timedatectl);

printf "\n\n [Checking on NetworkManager]\n";
systemctl status NetworkManager;



## advertise_ip()
## If doesn't work, paste back the function from bashrc
##
source ~/.bashrc;   

## Take $1 as a time parameter and loop advertise_ip every $1
## Don't forget to fork it
##
function loop_advertise_ip {
    while [ "true" ] ; do 
        advertise_ip;
        sleep "$1"; 
    done
}

sleep 10s;
loop_advertise_ip 30m;
    

