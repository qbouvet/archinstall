##
##  ~/.bashrc
##
##  source it from a script with #!/bin/bash -i
##


# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'

PS1='[\u@\h \W]\$ '


########################################################################
###################    PATHS & VARIABLES    ############################
########################################################################

EDITOR=nano;
#rbpi_git_dir="$HOME"/rbpi-git;
#ssh_key="$HOME"/.ssh/sshkey_pi_quentin;


########################################################################
#######################    FUNCTIONS    ################################
########################################################################


alias ll='ls -la';


## Meh
##
function temperature {
    cput=$(cat /sys/class/thermal/thermal_zone0/temp);
    #gput=$(/opt/vc/bin/vcgencmd measure_temp);
    printf "  CPU : $((cput/1000))C\n";
}


## print the current date & ip 
##
function print_ip {
    if [ $# -gt 1 ] && [ "$1" == "--date" ] ; then
        printf "Date : "; date
    fi
    ip -br -f inet addr | grep UP | while read line ; do 
        echo $line | awk '{split($3,ip,"/"); print $1 " " ip[1]}'
    done;
}
        

## List all IPs available on all interfaces, put them in a file,
## push the file to github
##
function advertise_ip {
    printf "\n\n [Advertising IPs]\n";
        # init
    pushd "$rpbi_git_dir";
    rm ip;
        # print current ip in ip file
    print_ip > ip;
        # push on git
    git add ip;
    git commit -m "ip autocomit";
    git push -u origin master;
        # exit
    popd;
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



	# Ugly AUR installer. Automates downloading, extracting and calling makepkg.
	# Args : 	$1	link to the AUR snapshot
	#			$2+ passed to makepkg (use it for --skippgpcheck)
	#
function ugly_aur_install {
    _user="quentin"
    _snapshotlink="$1"
    _archive=$(echo "$_snapshotlink" | sed 's|https://aur.archlinux.org/cgit/aur.git/snapshot/||')
    _packagename=$(echo "$_archive" | sed 's|.tar.gz||')
    printf "
    snapshot link :\t$_snapshotlink
    archive : \t\t	$_archive
    package : \t\t	$_packagename
    go ?\n\n"
    read; sleep 2s; 
        # create build directory
    mkdir -p /build; pushd /build
    sudo chown -R "$_user":users .
        # download pkgbuild
    wget "$_snapshotlink"
    tar -xvf "$_archive"
    pushd "$_packagename"
        # Build and install
    sudo -u "$_user" makepkg "${@:2}"
    sudo pacman -U "$_packagename"*.tar.xz
        # clean and exit
    popd; sudo rm -rf "$_packagename"
    popd;
    return 0
}    


# Test GPIO with pigpiod : https://www.raspberrypi.org/forums/viewtopic.php?t=180505
#export LD_LIBRARY_PATH=/usr/local/lib
#export PATH="$PATH:/usr/local/lib"
#ldconfig
