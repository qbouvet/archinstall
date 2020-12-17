
## NB : right now, this is cancelled by the setxkbmap call in autostart.sh
## activates the custom ~/.Xmodmap table
[[ -f ~/.Xmodmap ]] && xmodmap ~/.Xmodmap

## start openbox session
exec dbus-launch openbox-session
