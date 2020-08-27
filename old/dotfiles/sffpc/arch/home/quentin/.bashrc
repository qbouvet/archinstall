#
# ~/.bashrc
#


## If not running interactively, don't do anything [originally here]
##
[[ $- != *i* ]] && return
alias ls='ls --color=auto'
PS1='[\u@\h \W]\$ '



## Paths and variables
##
export MOZ_PLUGIN_PATH="/usr/lib/mozilla/plugins";	# flash player for firefox
export PATH="${PATH}:/scripts"				# run scripts as commands
export EDITOR='nano --tabsize=4 --tabstospaces'					# fuck off vi



## SSH agent and ssh-add
##
SSHAGENT_CACHE="$HOME/.ssh/cached"
if ! pgrep -u "$USER" ssh-agent > /dev/null; then
    ssh-agent > "$SSHAGENT_CACHE"
    eval "$(<$SSHAGENT_CACHE)"
    ssh-add ~/.ssh/sshkey-sffpc-arch
elif [[ "$SSH_AGENT_PID" == "" ]]; then
    eval "$(<$SSHAGENT_CACHE)"
fi



#
#                       FUNCTIONS
#                       =========

alias redshift='redshift -x; sleep 1.5s; pkill redshift; sleep 0.1s; redshift -r -b 0.97 -O 5800K -g 1:0.95:0.95'


function tar_verify {
    printf "\n[$(date +%H:%M:%S)] Verifying $1\n"
    tar -tzf $1 >/dev/null
    printf "[$(date +%H:%M:%S)] Done\n"
}

function mon_cpufreq {
    while [ "true" ] ; do clear; cat /proc/cpuinfo | grep "MHz" ; sleep 2s; done
}
