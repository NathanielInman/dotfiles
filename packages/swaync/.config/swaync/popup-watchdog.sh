#!/bin/sh
# Hides swaync popups that outlive every configured timeout (max 20s).
# swaync 0.12.6 can leave an orphaned popup on screen that the daemon no
# longer tracks: --close-latest can't reach it and it never expires (seen
# 2026-11-03 with a Chrome calendar reminder). --hide-all clears it and
# keeps history in the control center.
#
# Run by swaync-popup-watchdog.timer. A popup is stale when the popup layer
# is mapped but no notification has arrived for STALE_AFTER seconds;
# log-notification.sh touches the log on every notification.
STALE_AFTER=120
LOG=/tmp/swaync-notify.log

hyprctl layers 2>/dev/null | grep -q swaync-notification-window || exit 0

if [ -f "$LOG" ]; then
  age=$(( $(date +%s) - $(stat -c %Y "$LOG") ))
  [ "$age" -lt "$STALE_AFTER" ] && exit 0
fi

swaync-client --hide-all >/dev/null
printf '%s watchdog hid stale popup\n' "$(date +%F.%T)" >> /tmp/swaync-watchdog.log
