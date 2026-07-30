#!/bin/sh
# Called by swaync on every notification (see "scripts" in config.json).
# Appends app/urgency/summary to a tmpfs log so urgency surprises (e.g.
# Chrome marking calendar reminders critical) can be diagnosed later.
printf '%s app=%s urgency=%s summary=%s\n' "$(date +%F.%T)" \
  "$SWAYNC_APP_NAME" "$SWAYNC_URGENCY" "$SWAYNC_SUMMARY" >> /tmp/swaync-notify.log
