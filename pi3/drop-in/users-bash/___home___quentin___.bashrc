##
##  ~/.bashrc
##
##  source it from a script with #!/bin/bash -i
##



# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'

PS1='[\u@\h \W]\$ '

EDITOR=nano;

alias ll='ls -la';



## Meh
##
function temperature {
    cput=$(cat /sys/class/thermal/thermal_zone0/temp);
    #gput=$(/opt/vc/bin/vcgencmd measure_temp);
    printf "  CPU : $((cput/1000))C\n";
}


## Read / Set wifi connection priorities. Cf usage()
##
function nmcli_connections_priority {
    if [ $# -lt 1 ] || [ "$1" == "-h" ] ; then
        printf "\nUsage : nmcli_connections_priority <list/set> <connection name> <priority[-10,10]>\n"
        return
    fi
    if [ "$1" == "list" ] ; then 
        nmcli -f autoconnect-priority,name c;
        return;
    fi
    if [ "$1" == "set" ] && [ $# -eq 3 ] ; then 
        nmcli connection modify "$2" connection.autoconnect-priority "$3";
        return;
    fi
    echo "Arguments not understood, try -h"
}
