#!/usr/bin/env bash


## Debug flags & bash magic
set -o nounset      # exit on unassigned variable
set -o errexit      # exit on error
set -o pipefail     # exit on pipe fail
__dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# set -o xtrace     # Display xtrace



########################################################################
##################     VARIABLES &  FUNCTIONS      #####################
########################################################################

    # Root SSH keys
sshkey_path="/root/.ssh/sshkey-rbpi-root"
    # Path for caching $(eval ssh-agent)
ssh_agent_cache="/root/.ssh-agent-cached"
    # git / github setup
repo_upstream="git@github.com:sgPepper/ip.git"
git_name="sgpepper"
git_mail="quentin.bouvet@hotmail.fr"
    # path for ip files
ip_repo_path="/root/ip-git"
ip_file="$ip_repo_path"/rbpi.ip


# Control flow function
function ask_go {
    if [ "$#" -gt 0 ] ; then
        printf "$1"
    fi
    input=''
    ask_go_go="true"
    ask_go_done="false"
    while [ "$ask_go_done" == "false" ] ; do
        printf " go | skip | stop > " ; read input
        case "$input" in 
        ("go")      ask_go_done="true";;
        ("skip")    ask_go_done="true"
                    ask_go_go="false";;
        ("stop")    ask_go_done="true"
                    exit 1;;
        (*)         echo "?";;
        esac
    done
}

# Substitute pattern in file
#       $1  pattern, 
#       $2  replacement, 
#       $3  file
function subst {
	sed "s|$1|$2|" -i "$3"
}


########################################################################
######################      EXECUTION      #############################
########################################################################


ask_go "\n [client user setup]\n"
if [ "$ask_go_go" == "true" ] ; then
    echo "Creating guests group"
    groupadd guests
    client_user=""
    echo "Enter guest username"
    read client_user
    useradd  -m -g guests "$client_user"
    passwd "$client_user"
fi


ask_go "\n SSH keys setup\n"
if [ "$ask_go_go" == "true" ] ; then
		# initialize ssh-agent
	if ! [ -e "$sshkey_path" ] ; then
        ask_go "\nSSH key not found ($sshkey_path), do you want to generate a new pair ?\n"
        if [ "$ask_go_go" == "true" ] ; then
            ssh-keygen
            mv id_rsa "$sshkey_path"
            mv id_rsa.pub "$sshkey_path".pub
            echo "ssh keys have been generated"; sleep 0.5s;
            echo "The script will fail if these keys are not added to github"; sleep 1s;
            echo "Add them, then hit enter"; read	
        fi
	else 
		echo "ssh key detected in /root/.ssh"; sleep 0.5s;
		echo "NOTE : these keys *must* be added to github now, or the script will fail"; sleep 1s;
		echo "Ensure this is done and hit enter"; read	
	fi 
fi


# Compulsory ssh-agent setup
if ! [ "$(pgrep -u root ssh-agent)" ] ; then
	echo " caching ssh-agent"
	ssh-agent > "$ssh_agent_cache"
fi
eval "$(<$ssh_agent_cache)"
ssh-add "$sshkey_path"


ask_go "\n Github repository setup \n"
if [ "$ask_go_go" == "true" ] ; then
	git config --global user.email "$git_mail"
	git config --global user.name "$git_name"
	mkdir -p "$ip_repo_path"
	pushd "$ip_repo_path"
	git init
	git remote add origin "$repo_upstream"
	git pull origin master
	git checkout master
	echo "init" > "$ip_file"
	git add "$ip_file"
	git commit -m "init"
	git push -u origin master
fi


ask_go "\n system-advertise-ip systemd timer setup \n"
if [ "$ask_go_go" == "true" ] ; then	
    echo ONE
	if ! [ -f /root/system-advertise-ip.sh ] ; then
		echo "WARNING : script /root/system-advertise-ip.sh does not exist"; sleep 0.5s
		ask_go "    Do you want to copy it from /scripts ? \n"
        if [ "$ask_go_go" == "true" ] ; then	
            cp /scripts/system-advertise-ip.sh /root/system-advertise-ip.sh
        fi
    fi
    echo TWO    
	if ! [ -f /etc/systemd/system/system-advertise-ip.service ] ; then
		echo "WARNING : service /root/system-advertise-ip.service does not exist"; sleep 0.5s
		ask_go "    Do you want to set it up automatically ? \n"
        if [ "$ask_go_go" == "true" ] ; then	
            echo "
.           # /etc/systemd/system/system-advertise-ip.service

.           [Unit]
.           Description=Advertises ip address via git
   
.           [Service]
.           Type=oneshot
.           User=root
.           Group=root
.           ExecStart=/bin/bash -i /root/system-advertise-ip.sh

.           [Install]
.           WantedBy=multi-user.target
"           | sed 's|.           ||g' > /etc/systemd/system/system-advertise-ip.service
        fi
    fi
    if ! [ -f /etc/systemd/system/system-advertise-ip.timer ] ; then
        echo "WARNING : timer /root/system-advertise-ip.timer does not exist"; sleep 0.5s
        ask_go "    Do you want to set it up automatically ? \n"
        if [ "$ask_go_go" == "true" ] ; then	
            echo "
.           # /etc/systemd/system/system-advertise-ip.sh.timer

.           [Unit]
.           Description=system-advertise-ip.sh.service : Timer for system-advertise-ip.sh.service

.           [Timer]
.           # Wait 20 seconds at boot
.           OnBootSec=20sec
.           # Repeat every 1:40m afterwards
.           OnUnitActiveSec=100min

.           [Install]
.           WantedBy=timers.target
"           | sed 's|.           ||g' >/etc/systemd/system/system-advertise-ip.timer
        fi
	fi
	chmod +x /root/system-advertise-ip.sh;
	systemctl enable system-advertise-ip.timer;
		# Start everything
	systemctl start system-advertise-ip.timer;
fi


