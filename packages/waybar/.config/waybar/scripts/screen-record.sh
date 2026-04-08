#!/bin/bash

PID_FILE="/tmp/screen-record.pid"

if [ -f "$PID_FILE" ]; then
    kill -SIGINT "$(cat "$PID_FILE")" 2>/dev/null
    rm -f "$PID_FILE"
    sleep 1
    filepath="$(cat /tmp/screen-record.path)"
    normalized="${filepath%.mp4}-normalized.mp4"
    ffmpeg -y -i "$filepath" -af loudnorm -c:v copy "$normalized" 2>/dev/null && mv "$normalized" "$filepath"
    swaync-client -df -sw
    notify-send "Recording saved" "$filepath" -i dialog-information
else
    geometry=$(slurp) || exit 0
    swaync-client -dn -sw
    mkdir -p ~/Videos
    filepath="$HOME/Videos/recording-$(date +%Y%m%d-%H%M%S).mp4"
    echo "$filepath" > /tmp/screen-record.path
    audio_source=$(pactl get-default-sink).monitor
    wf-recorder -g "$geometry" -a --audio-source="$audio_source" -f "$filepath" &
    echo $! > "$PID_FILE"
fi
