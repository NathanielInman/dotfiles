#!/bin/bash

chosen=$(echo -e "Lock\nLogout\nSuspend\nReboot\nShutdown" | walker --dmenu --placeholder "Power")

case "$chosen" in
    Lock) hyprlock ;;
    Logout) hyprctl dispatch exit ;;
    Suspend) systemctl suspend ;;
    Reboot) systemctl reboot ;;
    Shutdown) systemctl poweroff ;;
esac
