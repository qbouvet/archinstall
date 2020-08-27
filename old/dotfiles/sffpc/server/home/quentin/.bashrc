#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
PS1='[\u@\h \W]\$ '




########################################################################
####################   PATHS & VARIABLES   #############################
########################################################################

export PATH=$PATH:/scripts
export EDITOR=nano								# fuck off vi
export MAKEFLAGS="-j$(expr $(nproc) \+ 1)"	# run make with several threads by default
export ip_git_dir="/root/ip-git"
export ssh_key=""




########################################################################
########################   FUNCTIONS   #################################
########################################################################

#
#	Outputs the public ip address by default, or the local ip adresses 
#	of all interfaces with '--local'
#
function print_ip {
	# Local IP adress
	if [ $# -gt 0 ] && [ "$1" == "--local" ] ; then 
		ip -br -f inet addr | grep UP | while read line ; do 
			echo $line | awk '{split($3,ip,"/"); print $1 " " ip[1]}'
		done;
	fi 
	# Public IP adress 
	# Several alternatives : 
	#	curl ipinfo.io/ip
	#	curl -s checkip.dyndns.org | sed -e 's/.*Current IP Address: //' -e 's/<.*$//'
	curl ipinfo.io/ip
}
