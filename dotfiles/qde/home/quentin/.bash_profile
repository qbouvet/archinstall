#
# ~/.bash_profile
#

#
# Source .bashrc
#
[[ -f ~/.bashrc ]] && . ~/.bashrc

#
# Auto-start X
# https://wiki.archlinux.org/index.php/Xinit#Tips_and_tricks
#
if [[ ! $WAYLAND_DISPLAY && ! $DISPLAY && $XDG_VTNR -eq 1 ]]; 
then
  exec startx
fi
