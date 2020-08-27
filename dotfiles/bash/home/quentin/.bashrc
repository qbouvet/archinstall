#
# ~/.bashrc
#


## If not running interactively, don't do anything [originally here]
##
[[ $- != *i* ]] && return
alias ls='ls --color=auto'
PS1='[\u@\h \W]\$ '



## Config, utils
##
source /scripts/bashcfg/all.sh
source /scripts/bashsnippets.sh



## SSH agent and ssh-add
##
SSHAGENT_CACHE="$HOME/.ssh/cached"
if ! pgrep -u "$USER" ssh-agent > /dev/null; then
    ssh-agent > "$SSHAGENT_CACHE"
    eval "$(<$SSHAGENT_CACHE)"
    ssh-add ~/.ssh/sshkey-sffpc-arch
    ssh-add ~/.ssh/quentin.qbvt-sffpc
elif [[ "$SSH_AGENT_PID" == "" ]]; then
    eval "$(<$SSHAGENT_CACHE)"
fi



#
#                       FUNCTIONS
#                       =========

function tar_verify {
    printf "\n[$(date +%H:%M:%S)] Verifying $1\n"
    tar -tzf $1 >/dev/null
    printf "[$(date +%H:%M:%S)] Done\n"
}

function mon_cpufreq {
    while [ "true" ] ; do clear; cat /proc/cpuinfo | grep "MHz" ; sleep 2s; done
}

alias hibernate="sudo systemctl hibernate; sudo systemctl restart fan_ctl"
alias discord-loop="while true ; do discord-ptb --disable-seccomp-filter-sandbox; sleep 0.2s; done"