#!/bin/bash

chosen=$(echo -e "Idle\nLock\nLogout\nSuspend\nReboot\nShutdown" | walker --dmenu --placeholder "Power")

case "$chosen" in
    # Screens off now instead of waiting for hypridle's timeout; the next
    # mouse move / key press wakes them (mouse_move_enables_dpms /
    # key_press_enables_dpms). Sleep so the Enter that picked this entry has
    # been released before dpms goes off, or the release wakes it right back.
    # The guard re-asserts dpms off on DP-2 when the G9's secondary PBP input
    # bounces its link entering standby and hotplugs itself awake. setsid with
    # redirects so waybar's exec pipe isn't held open by the background child.
    Idle) sleep 0.5; [ "$(hyprctl dispatch dpms off 2>/dev/null)" = "ok" ] || hyprctl dispatch 'hl.dsp.dpms({ action = "off" })'
          setsid -f "$(dirname "$0")/idle-dpms-guard.sh" >/dev/null 2>&1 ;;
    Lock) hyprlock ;;
    # Legacy keyword form first, then the lua-config (Hyprland 0.55+) form
    Logout) [ "$(hyprctl dispatch exit 2>/dev/null)" = "ok" ] || hyprctl dispatch 'hl.dsp.exit()' ;;
    Suspend) systemctl suspend ;;
    Reboot) systemctl reboot ;;
    Shutdown) systemctl poweroff ;;
esac
