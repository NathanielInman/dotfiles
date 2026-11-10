#!/bin/bash
# Toggles a region screen recording with wf-recorder. Stopping normalizes the
# audio loudness in place. State lives in $XDG_RUNTIME_DIR, which logout and
# reboot clear, so a crash can't leave the bar icon lit for good.

RUNTIME="${XDG_RUNTIME_DIR:-/tmp}"
PID_FILE="$RUNTIME/screen-record.pid"
PATH_FILE="$RUNTIME/screen-record.path"
WAYBAR_SIGNAL=9 # custom/screen-record "signal" in config.jsonc

refresh_bar() { pkill -RTMIN+"$WAYBAR_SIGNAL" -x waybar 2>/dev/null; }

recording_pid() {
    local pid
    pid=$(cat "$PID_FILE" 2>/dev/null) || return 1
    if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
        echo "$pid"
        return 0
    fi
    rm -f "$PID_FILE"
    return 1
}

if [ "$1" = "status" ]; then
    recording_pid >/dev/null && echo '⏺'
    exit 0
fi

if pid=$(recording_pid); then
    kill -SIGINT "$pid" 2>/dev/null
    for _ in $(seq 50); do kill -0 "$pid" 2>/dev/null || break; sleep 0.2; done
    rm -f "$PID_FILE"
    refresh_bar
    filepath="$(cat "$PATH_FILE")"
    rm -f "$PATH_FILE"
    normalized="${filepath%.mp4}-normalized.mp4"
    ffmpeg -y -i "$filepath" -af loudnorm -c:v copy "$normalized" 2>/dev/null && mv "$normalized" "$filepath"
    swaync-client -df -sw
    notify-send "Recording saved" "$filepath" -i dialog-information
else
    geometry=$(slurp) || exit 0
    swaync-client -dn -sw
    mkdir -p ~/Videos
    filepath="$HOME/Videos/recording-$(date +%Y%m%d-%H%M%S).mp4"
    echo "$filepath" > "$PATH_FILE"
    audio_source=$(pactl get-default-sink).monitor
    setsid wf-recorder -g "$geometry" -a --audio-source="$audio_source" -f "$filepath" </dev/null >/dev/null 2>&1 &
    echo $! > "$PID_FILE"
    refresh_bar
fi
