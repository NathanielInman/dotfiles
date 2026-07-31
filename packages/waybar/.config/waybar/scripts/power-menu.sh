#!/bin/bash

chosen=$(echo -e "Lock\nLogout\nSuspend\nReboot\nShutdown" | walker --dmenu --placeholder "Power")

case "$chosen" in
    Lock) hyprlock ;;
    # Legacy keyword form first, then the lua-config (Hyprland 0.55+) form
    Logout) [ "$(hyprctl dispatch exit 2>/dev/null)" = "ok" ] || hyprctl dispatch 'hl.dsp.exit()' ;;
    Suspend) systemctl suspend ;;
    Reboot) systemctl reboot ;;
    Shutdown) systemctl poweroff ;;
esac
