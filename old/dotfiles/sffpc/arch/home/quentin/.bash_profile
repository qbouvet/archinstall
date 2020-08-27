#
# ~/.bash_profile
#

# Source .bashrc
[[ -f ~/.bashrc ]] && . ~/.bashrc

# Auto-start X
if [[ ! $WAYLAND_DISPLAY && ! $DISPLAY && $XDG_VTNR -eq 1 ]]; then
	exec startx
fi
