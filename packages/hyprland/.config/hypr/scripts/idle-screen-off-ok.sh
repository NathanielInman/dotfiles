#!/bin/sh
# hypridle condition_cmd for the screen-off listener: exit 0 when the screens
# may go dark, 1 to hold them on (hypridle retries while still idle).
#
# The listener sets ignore_inhibit so T3 Code can't keep the G9 lit forever:
# its Electron window holds a wayland idle inhibitor for long stretches, and
# screen-off doesn't suspend anything, so its agents keep running in the dark.
# Every other reason to stay lit is re-checked here instead:
#   - any other window inhibiting idle (a Chrome or mpv video)
#   - audio playing or a mic open (what sway-audio-idle-inhibit guards)
# Fails open: if a probe can't answer, the screens go dark.

clients=$(hyprctl -j clients 2>/dev/null)
if [ -n "$clients" ] && printf '%s' "$clients" | jq -e \
  'any(.[]; .inhibitingIdle and .class != "com.t3tools.T3Code")' >/dev/null 2>&1; then
  exit 1
fi

audio=$(timeout 2 sway-audio-idle-inhibit --dry-print-both 2>/dev/null | head -n 1)
[ "$audio" = "RUNNING" ] && exit 1

exit 0
