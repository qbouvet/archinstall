#
# ~/.bash_profile
#

#
#   Source bashrc if file exists
#
[[ -f ~/.bashrc ]] && . ~/.bashrc

#
#   Autostart X (`startx`) at console login in tty1
#
if systemctl -q is-active graphical.target && [[ ! $DISPLAY && XDG_VTNR -eq 1 ]]; 
then 
  exec startx
fi
