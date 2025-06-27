#!/bin/bash

# This is needed for dbus
if [ -d /etc/X11/xinit/xinitrc.d ] ; then
	for f in /etc/X11/xinit/xinitrc.d/?*.sh ; do
		[ -x "$f" ] && . "$f"
	done
	unset f
fi

#xset r rate 250 45
#setxkbmap -layout "latam"
xset -dpms
xset s off

xmousepasteblock &
/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1 &
exec awesome
