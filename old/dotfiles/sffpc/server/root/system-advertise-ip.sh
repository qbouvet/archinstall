#!/bin/bash -i

# This file is looped with a systemd timer 

# maybe later
#source ~/.bashrc

ip_git_dir="/root/ip-git"
ipfile="$ip_git_dir"/sffpc.ip
latency="3m"
log="/root/system-advertise-ip.sh.log"
git_mail="quentin.bouvet@hotmail.fr"
git_name="sgPepper"



## Redirect outputs to log file
##
#rm $log; touch "$log"
function redirect_io {
	exec 1<&-;      # Close STDOUT file descriptor
	exec 2<&-;      # Close STDERR FD
	exec 1<>"$log"; # Open STDOUT as $log file for read and write.
	exec 2>&1;      # Redirect STDERR to STDOUT
}
#redirect_io



#
#	Outputs the public ip address by default, or the local ip adresses 
#	of all interfaces with '--local'
#
function print_ip {
	# Local IP adress
	ip -br -f inet addr | grep UP | while read line ; do 
		echo $line | awk '{split($3,ip,"/"); print "local " $1 " " ip[1]}'
	done;
	# Public IP adress  -  Several alternatives : 
	#	curl ipinfo.io/ip
	#	curl -s checkip.dyndns.org | sed -e 's/.*Current IP Address: //' -e 's/<.*$//'
	echo "public $(curl -s ipinfo.io/ip)"
}


function advertise_ip {
	rm "$ipfile"
	if [ $# -gt 0 ] && [ "$1" == "--date" ] ; then 
		printf "Date : $(date)\n" >> "$ipfile"
	fi
	print_ip >> $ipfile
	git add "$ipfile"
	git commit -m "sffpc ip autocommit"
	git push -u origin master
}


function eval_ssh_agent_add_identity {
	root_ssh_key="/root/.ssh/sffpc-root-key"
	root_ssh_agent_cache="/root/.ssh-agent-cached"
	if ! [ "$(pgrep -u root ssh-agent)" ] ; then
		echo " caching ssh-agent"
		ssh-agent > "$root_ssh_agent_cache"
	fi
	eval "$(<$root_ssh_agent_cache)"
	ssh-add "$root_ssh_key"
}

printf "\n[$(date '+%Y-%m-%d %H:%M:%S')] systemctl-advertise-ip.sh()\n\n";

# Not sure if done properly during install
#git config --global user.email "$git_mail"
#git config --global user.name "$git_name"

cd "$ip_git_dir"

    # Setup ssh-agent 
eval_ssh_agent_add_identity >> $log

	# Run
advertise_ip --date >> $log


