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



## commands aliases
##
alias ll='ls -la'
alias eject='udisksctl power-off -b'
alias spindown='sudo hdparm -y'
alias timestamp='date +%Y-%m-%d_%H:%M:%S'
alias reindent='/usr/lib/python3.6/Tools/scripts/reindent.py'
alias leafpad='leafpad --tab-width=4'
alias nano='nano --tabsize=4 --tabstospaces'
function scribe { 
    scribes "$@" > /dev/null 2>&1 
}


## SSH agent and ssh-add
##
#SSHAGENT_CACHE="$HOME/.ssh/cached"
#if ! pgrep -u "$USER" ssh-agent > /dev/null; then
#    ssh-agent > "$SSHAGENT_CACHE"
#    eval "$(<$SSHAGENT_CACHE)"
#    ssh-add ~/.ssh/sshkey-sffpc-arch
#elif [[ "$SSH_AGENT_PID" == "" ]]; then
#    eval "$(<$SSHAGENT_CACHE)"
#fi

