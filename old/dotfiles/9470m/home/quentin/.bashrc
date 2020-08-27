#
# ~/.bashrc
#


## If not running interactively, don't do anything [originally here]
##
[[ $- != *i* ]] && return
alias ls='ls --color=auto'
PS1='[\u@\h \W]\$ '


## Source per-machine variables and common bash helpers
##
source /scripts/config.sh
source /scripts/utils.sh


## Paths and variables
##
	# run scripts as commands
export PATH="${PATH}:/scripts"				
	# fuck off vi
export EDITOR='nano --tabsize=4 --tabstospaces'					

	# flash player for firefox
export MOZ_PLUGIN_PATH="/usr/lib/mozilla/plugins";	

	# bugfix for vmware-workstation / vmware-player
export VMWARE_USE_SHIPPED_LIBS='yes'			
	# Anaconda
export PATH="${PATH}:/opt/anaconda/bin"			
	# LAP's licence servers for altera products
	# [?]
export ARMLMD_LICENSE_FILE="27004@eslsrv9.epfl.ch:27004@lsipc2.epfl.ch:27004@lappc2.epfl.ch" 	






