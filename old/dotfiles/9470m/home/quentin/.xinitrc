
## NB : right now, this is cancelled by the setxkbmap call in autostart.sh
## activates the custom ~/.Xmodmap table
	[[ -f ~/.Xmodmap ]] && xmodmap ~/.Xmodmap

## start openbox session
	exec dbus-launch openbox-session

## Start Mate DE (appearently needed to edit caja keyboard shortcuts after having set the can-change-accels key in dconf)
#	exec mate-session
