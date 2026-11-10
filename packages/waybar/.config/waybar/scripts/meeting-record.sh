#!/bin/bash
# Records a meeting from the default input in 15 minute chunks, and
# transcribes a finished session with voxtype.
#
# The chunk loop runs in its own session (setsid), so its pid is also its
# process group and stop takes down the loop, the sleep and pw-record
# together. Killing only the loop's children used to leave the loop alive,
# which started the next chunk after "stop" with the bar icon already dark.
#
# State lives in $XDG_RUNTIME_DIR, which logout and reboot clear; /tmp on this
# machine survives a reboot and kept a stale icon lit.

RUNTIME="${XDG_RUNTIME_DIR:-/tmp}"
PID_FILE="$RUNTIME/meeting-record.pid"
PATH_FILE="$RUNTIME/meeting-record.path"
CHUNK_DURATION=900 # 15 minutes in seconds
WAYBAR_SIGNAL=8    # custom/meeting-record "signal" in config.jsonc

refresh_bar() { pkill -RTMIN+"$WAYBAR_SIGNAL" -x waybar 2>/dev/null; }

recording_pid() {
    local pid
    pid=$(cat "$PID_FILE" 2>/dev/null) || return 1
    if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
        echo "$pid"
        return 0
    fi
    # The loop died without a stop (crash, kill): drop the stale state
    rm -f "$PID_FILE" "$PATH_FILE"
    return 1
}

chunk_loop() {
    local session_dir="$1" chunk_num=1 chunk_name
    trap 'trap - TERM INT HUP; kill 0; exit 0' TERM INT HUP
    while true; do
        chunk_name=$(printf "chunk-%03d-%s.wav" "$chunk_num" "$(date +%H%M%S)")
        pw-record --rate 16000 --channels 1 --format s16 "$session_dir/$chunk_name" &
        pw_pid=$!
        sleep "$CHUNK_DURATION" &
        wait $!
        kill "$pw_pid" 2>/dev/null
        wait "$pw_pid" 2>/dev/null
        chunk_num=$((chunk_num + 1))
    done
}

start_recording() {
    local session_dir
    session_dir="$HOME/Audio/meetings/$(date +%Y-%m-%d_%H-%M-%S)"
    mkdir -p "$session_dir"

    setsid "$0" _loop "$session_dir" </dev/null >/dev/null 2>&1 &
    echo $! > "$PID_FILE"
    echo "$session_dir" > "$PATH_FILE"
    refresh_bar

    notify-send "Meeting recording started" "$session_dir" -i audio-input-microphone
}

stop_recording() {
    local pid session_dir chunk_count=0
    session_dir=$(cat "$PATH_FILE" 2>/dev/null)
    if pid=$(recording_pid); then
        # pid is the session leader, so -pid is the whole group
        kill -TERM -- -"$pid" 2>/dev/null
        for _ in 1 2 3 4 5 6 7 8 9 10; do
            kill -0 "$pid" 2>/dev/null || break
            sleep 0.2
        done
        kill -KILL -- -"$pid" 2>/dev/null
    fi
    rm -f "$PID_FILE" "$PATH_FILE"
    refresh_bar

    if [ -d "$session_dir" ]; then
        chunk_count=$(find "$session_dir" -name '*.wav' | wc -l)
    fi
    notify-send "Meeting recording stopped" "$chunk_count chunk(s) saved to $session_dir" -i dialog-information
}

transcribe() {
    local dir="${1:-.}"
    dir=$(realpath "$dir")

    if [ ! -d "$dir" ]; then
        echo "Directory not found: $dir" >&2
        exit 1
    fi

    local transcript="$dir/transcript.txt"
    : > "$transcript"

    local count=0
    for wav in "$dir"/chunk-*.wav; do
        [ -f "$wav" ] || continue
        count=$((count + 1))
        echo "Transcribing: $(basename "$wav")..." >&2
        voxtype transcribe "$wav" >> "$transcript"
        echo "" >> "$transcript"
    done

    if [ "$count" -eq 0 ]; then
        echo "No chunk WAV files found in $dir" >&2
        exit 1
    fi

    echo "Transcript written to $transcript ($count chunks)" >&2
}

case "${1:-toggle}" in
    toggle)
        if recording_pid >/dev/null; then stop_recording; else start_recording; fi
        ;;
    start)
        recording_pid >/dev/null && { echo "Already recording"; exit 1; }
        start_recording
        ;;
    stop)
        recording_pid >/dev/null || { echo "Not recording"; exit 1; }
        stop_recording
        ;;
    status)
        # waybar custom/meeting-record: an icon while recording, nothing otherwise
        recording_pid >/dev/null && echo '󰻞'
        exit 0
        ;;
    transcribe)
        transcribe "$2"
        ;;
    _loop)
        chunk_loop "$2"
        ;;
    *)
        echo "Usage: $(basename "$0") [toggle|start|stop|status|transcribe <dir>]" >&2
        exit 1
        ;;
esac
