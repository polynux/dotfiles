#!/bin/sh

xrdb merge ~/.Xresources 
xbacklight -set 10 &
# feh --bg-fill ~/Pictures/wall/gruv.png 
xset r rate 200 50 &
picom &
variety &
copyq &
flameshot &
optimus-manager-qt &
blueman-applet &
nm-applet &
volumeicon &
/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1 &
xfce4-power-manager &
sh ~/Téléchargements/OpenFreezeCenter/at_startup.sh &

~/.config/chadwm/scripts/bar.sh &
while type dwm >/dev/null; do dwm && continue || break; done
