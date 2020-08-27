#!/bin/bash -i

##
##  ~/autostart.sh
##  This script is run at user login in an interactive shell 
##      ( bash -i in autostart-login.sh.service )
##


## Paths & variables
##
__dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)";
__log="$__dir"/autostart-login.sh.log;
source "$HOME"/.bashrc;	# ssh_key
                        # rbpi_git_dir
                        # advertise_ip ()



## Redirect outputs to log file
##
rm $log;
exec 1<&-;          # Close STDOUT file descriptor
exec 2<&-;          # Close STDERR FD
exec 1<>"$__log";     # Open STDOUT as $log file for read and write.
exec 2>&1;          # Redirect STDERR to STDOUT


## Timestamp
##
printf "\n\n [Date]";
date;


printf "\n\n  /root/autostart-login.sh -> done\n"
exit 0;







########################################################################
#######################    LEGACY CODE    ##############################
########################################################################
## For reference later
echo "You've reachd deprecated code"; exit 1;


## Add keys to ssh agent
##
printf "\n\n [ssh-add : $ssh_key ]\n";
sleep 3s;
ssh-add "$ssh_key";


## Advertise ip loop
##
printf "\n\n [Advertising IP ]\n";
function loop_advertise_ip {
    # Don't forget to fork
    #   $1 = cycle time  
    while [ "true" ] ; do 
        sleep "$1"; 
        advertise_ip;
    done
}
    # run loop
#sleep 5s
#print_ip
#advertise_ip
#loop_advertise_ip 15m > /dev/null &
# -> This will be done by a systmctl system timer
