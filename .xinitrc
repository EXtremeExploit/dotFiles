#!/bin/bash
#
# ~/.xinitrc
#
# Executed by startx (run your window manager from here)

if [ -d /etc/X11/xinit/xinitrc.d ] ; then
    for f in /etc/X11/xinit/xinitrc.d/?*.sh ; do
        [ -x "$f" ] && . "$f"
    done
    unset f
fi

xrandr

xset r rate 250 45
setxkbmap -layout "latam"
xset -dpms
xset s off

xrdb -merge ~/.Xresources

xmousepasteblock &
/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1 &
exec awesome
