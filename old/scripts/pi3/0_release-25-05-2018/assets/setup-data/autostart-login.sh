#!/usr/bin/env bash

##
##  ~/autostart.sh
##  This script is run at user login
##


## Variables
##
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)";
log="$dir"/autostart-login.sh.log;
ssh_key="$HOME"/.ssh/sshkey_pi_quentin;



## Redirect outputs to log file
##
rm $log;
exec 1<&-;      # Close STDOUT file descriptor
exec 2<&-;      # Close STDERR FD
exec 1<>"$log"; # Open STDOUT as $log file for read and write.
exec 2>&1;      # Redirect STDERR to STDOUT



## Timestamp
##
printf "\n\n [Date]\n";
echo $(date);



## Add keys to ssh agent
##
printf "\n\n [ssh-add : $ssh_key ]\n";
sleep 3s;
ssh-add "$ssh_key";



## Advertise ip loop
##
printf "\n\n [Advertising IP ]\n";
. ~/.bashrc;
print_ip;
#function loop_advertise_ip {
#    # $1 = cycle time  |  Don't forget to fork
#    while [ "true" ] ; do 
#        sleep "$1"; 
#        advertise_ip;
#    done
#}
    # run loop
#sleep 10s;
#advertise_ip;
#loop_advertise_ip 2h > /dev/null &
    

