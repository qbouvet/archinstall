#
# ~/.bashrc
#


# If not running interactively, don't do anything
[[ $- != *i* ]] && return


#
#    Cosmetic stuff
#
PS1='[\u@\h \W]\$ '
alias ls='ls --color=auto'


#
#   Import my stuff
#
srcdir="/scripts"
if [[ -d "$srcdir" ]] 
then 
    source "$srcdir"/bashcfg/all.sh
    source "$srcdir"/bashsnippets.sh
fi


#
#   SSH agent and ssh-add
#
SSHAGENT_CACHE="$HOME/.ssh/ssh-env"
if ! pgrep -u "$USER" ssh-agent > /dev/null; then
    ssh-agent > "$SSHAGENT_CACHE"
    eval "$(<$SSHAGENT_CACHE)"
    shopt -s nullglob
    for f in ~/.ssh/*; do 
		if [[ "$f" =~ .*\.key ]]; then 
			ssh-add "$f"
		fi
    done
    shopt -u nullglob
elif [[ "$SSH_AGENT_PID" == "" ]]; then
    eval "$(<$SSHAGENT_CACHE)"
fi


#
#   Aliases
#
alias yay='yay --removemake --sudoloop --norebuild --noredownload'


#
#   Variables
#
export STEAM_FRAME_FORCE_CLOSE=1	# Close steam to tray


#
#   Some messy functions
#
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
