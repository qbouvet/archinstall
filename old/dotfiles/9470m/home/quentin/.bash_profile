#
# ~/.bash_profile
#

# was there by default
	[[ -f ~/.bashrc ]] && . ~/.bashrc

# autostart X at login
	if [ -z "$DISPLAY" ] && [ -n "$XDG_VTNR" ] && [ "$XDG_VTNR" -eq 1 ]; then
	  exec startx
	fi

export QSYS_ROOTDIR="/tmp/yaourt-tmp-quentin/aur-quartus-lite/pkg/quartus-lite//opt/altera/quartus/sopc_builder/bin"
