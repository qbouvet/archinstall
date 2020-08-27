#
# ~/.bashrc
#


	# If not running interactively, don't do anything [originally here]
	#
[[ $- != *i* ]] && return
alias ls='ls --color=auto'
#PS1='[\u@\h \W]\$ '
PS1='> \u@\h \w\n$ '


# 	User-accessible snippets
# 	Sources bashconfig.sh and bashutils.sh
#	
source /scripts/bashsnippets.sh


#   Temporary stuff
#
alias pissh='ssh -p 13333 quentin@bouvet.ddns.net -i ~/.ssh/id_rsa' 
alias pisshfs='sshfs -p 13333 quentin@bouvet.ddns.net:/ /mnt/pi3' 
    # !!    This one seems to work only once per boot 
    # !!    Especially so with the --dns flag
    # !!    The '--dns' flag is crucial to acces the livebox interface
alias pisshuttle='sshuttle --verbose --dns -x $(ipv4) -r quentin@bouvet.ddns.net:13333 0.0.0.0/0'


# 	wxWidgets
#
export LD_LIBRARY_PATH="/usr/local/lib/"

# 	Anaconda
#
#export PATH="${PATH}:/opt/anaconda/bin"								


	# (?)
	#
	# LAP's licence servers for altera products
export ARMLMD_LICENSE_FILE="27004@eslsrv9.epfl.ch:27004@lsipc2.epfl.ch:27004@lappc2.epfl.ch" 	

	# Cross-compilers Toolchains			
	#
	# Don't ? :
#export LD_LIBRARY_PATH="/opt/cross-pi-gcc-8.3.0-1/lib:${LD_LIBRARY_PATH}"
	# handmade one
#export PATH="${PATH}:/opt/cc-glibc219/bin"


