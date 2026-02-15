#!/bin/bash

chosen=$(echo -e "Lock\nLogout\nSuspend\nReboot\nShutdown" | rofi -dmenu -p "Power")

case "$chosen" in
    Lock) swaylock ;;
    Logout) hyprctl dispatch exit ;;
    Suspend) systemctl suspend ;;
    Reboot) systemctl reboot ;;
    Shutdown) systemctl poweroff ;;
esac
