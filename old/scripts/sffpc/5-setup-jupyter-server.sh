#!/bin/bash

# Run as root
[ "$UID" -eq 0 ] || exec sudo bash "$0" "$@"


########################################################################
#################   FUNCTIONS & VARIABLES   ############################
########################################################################


admin_user="quentin"
client_user="sandra"
port="14444"
jupyter_notebook_port="12244"
	# jupyter_noiretblanc
jupyter_hash="u'sha1:eaeed81e6989:efc71011990f7d4c293c4152d79e8f4d5d8c4f65'"
root_ssh_key="/root/.ssh/sffpc-root-key"
ip_repo_path="/root/ip-git"
ip_file="$ip_repo_path"/sffpc.ip
repo_upstream="git@github.com:sgPepper/ip.git"
git_mail="quentin.bouvet@hotmail.fr"
git_name="Quentin Bouvet"


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



########################################################################
#########################   EXECUTION  #################################
########################################################################


ask_go "\n [client user setup]\n"
if [ "$ask_go_go" == "true" ] ; then
	useradd  -m -g users "$client_user"
	passwd "$client_user"
fi


ask_go "\n [ssh daemon (sshd) settings]\n"
if [ "$ask_go_go" == "true" ] ; then
	# sshd config
	printf "\n\n\n## Personal config\n##" >> /etc/ssh/sshd_config
	printf "\nAllowUsers		$admin_user $client_user" >> /etc/ssh/sshd_config
	printf "[Socket]\nListenStream=\nListenStream=$port\n" > /etc/systemd/system/sshd.socket.d/override.conf
	# start daemon
	systemctl enable sshd.socket
	systemctl start sshd.socket
fi 


ask_go "\n [system-advertise-ip.sh] > root ssh-agent setup (run this one everytime) \n"
if [ "$ask_go_go" == "true" ] ; then
		# initialize ssh-agent
	if ! [ -e "$root_ssh_key" ] ; then
		ssh-keygen
		mv id_rsa "$root_ssh_key"
		mv id_rsa.pub "$root_ssh_key".pub
		echo "ssh keys have been generated"; sleep 0.5s;
		echo "The script will fail if these keys are not added to github"; sleep 1s;
		echo "Add them, then hit enter"; read	
	else 
		echo "ssh key detected in /root/.ssh"; sleep 0.5s;
		echo "NOTE : these keys *must* be added to github now, or the script will fail"; sleep 1s;
		echo "Ensure this is done and hit enter"; read	
	fi 
fi


# Eval & add Id from system-advertise-ip.sh
root_ssh_key="/root/.ssh/sffpc-root-key"
root_ssh_agent_cache="/root/.ssh-agent-cached"
if ! [ "$(pgrep -u root ssh-agent)" ] ; then
	echo " caching ssh-agent"
	ssh-agent > "$root_ssh_agent_cache"
fi
eval "$(<$root_ssh_agent_cache)"
ssh-add "$root_ssh_key"


ask_go "\n [system-advertise-ip.sh] > git repo initialization \n"
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


ask_go "\n [system-advertise-ip.sh] > advertise_ip loop setup \n"
if [ "$ask_go_go" == "true" ] ; then	
	if ! [ -f /root/system-advertise-ip.sh ] ; then
		echo "WARNING : file /root/system-advertise-ip.sh does not exist"; sleep 0.5s
		echo "Please set it up now !!! (hit enter when done)"; read
	fi
	chmod +x /root/system-advertise-ip.sh;
	systemctl enable system-advertise-ip.sh.timer;
		# Start everything
	systemctl start system-advertise-ip.sh.timer;
fi


# $1 pattern, $2 replacement, $3 file
function subst {
	sed "s|$1|$2|" -i "$3"
}


ask_go "\n Jupyter server setup \n"
if [ "$ask_go_go" == "true" ] ; then	
	jupyter notebook --generate-config
	jupy_config_file="/home/$client_user/.jupyter/jupyter_notebook_config.py"
	    # Remote connection setup
	sed "s|#c.NotebookApp.ip = 'localhost'|c.NotebookApp.ip = '*'|" -i "$jupy_config_file"
	sed "s|#c.NotebookApp.port = 8888|c.NotebookApp.port = $jupyter_notebook_port|" -i "$jupy_config_file"
	subst "c.NotebookApp.allow_origin = '*'" "c.NotebookApp.allow_origin = '*'" "$jupy_config_file"
	    # Password setup
	sed "s|#c.NotebookApp.password = ''|c.NotebookApp.password = $jupyter_hash|" -i "$jupy_config_file"
	subst "#c.NotebookApp.password_required = False" "c.NotebookApp.password_required = True" "$jupy_config_file"
	subst "#c.NotebookApp.allow_password_change = True" "c.NotebookApp.allow_password_change = False" "$jupy_config_file"
	    # Misc
	subst "#c.NotebookApp.open_browser = True" "c.NotebookApp.open_browser = False" "$jupy_config_file"
	
fi



ask_go "\n VNC server setup \n"
if [ "$ask_go_go" == "true" ] ; then	
	echo "NOT IMMPLEMENTED"
fi


printf "\n\n\tDone ! \n\n\tDon't forget to configure correctly the NAT/PAT/port forwarding on your router ;)\n\n"


