#!/bin/bash

PID_FILE="/tmp/screen-record.pid"

if [ -f "$PID_FILE" ]; then
    kill -SIGINT "$(cat "$PID_FILE")" 2>/dev/null
    rm -f "$PID_FILE"
    swaync-client -df -sw
    notify-send "Recording saved" "$(cat /tmp/screen-record.path)" -i dialog-information
else
    geometry=$(slurp) || exit 0
    swaync-client -dn -sw
    mkdir -p ~/Videos
    filepath="$HOME/Videos/recording-$(date +%Y%m%d-%H%M%S).mp4"
    echo "$filepath" > /tmp/screen-record.path
    wf-recorder -g "$geometry" -f "$filepath" &
    echo $! > "$PID_FILE"
fi
