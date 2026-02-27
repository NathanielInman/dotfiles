#!/bin/bash

PID_FILE="/tmp/meeting-record.pid"
CHUNK_DURATION=900 # 15 minutes in seconds

start_recording() {
    local session_dir="$HOME/Audio/meetings/$(date +%Y-%m-%d_%H-%M-%S)"
    mkdir -p "$session_dir"

    # Spawn chunking loop in background
    (
        chunk_num=1
        while true; do
            chunk_name=$(printf "chunk-%03d-%s.wav" "$chunk_num" "$(date +%H%M%S)")
            pw-record --rate 16000 --channels 1 --format s16 \
                "$session_dir/$chunk_name" &
            pw_pid=$!
            sleep "$CHUNK_DURATION"
            kill "$pw_pid" 2>/dev/null
            wait "$pw_pid" 2>/dev/null
            chunk_num=$((chunk_num + 1))
        done
    ) &
    loop_pid=$!

    echo "$loop_pid" > "$PID_FILE"
    echo "$session_dir" > /tmp/meeting-record.path

    notify-send "Meeting recording started" "$session_dir" -i audio-input-microphone
}

stop_recording() {
    local loop_pid
    loop_pid=$(cat "$PID_FILE" 2>/dev/null)
    local session_dir
    session_dir=$(cat /tmp/meeting-record.path 2>/dev/null)

    # Kill the chunking loop and all its children (including active pw-record)
    kill -- -"$loop_pid" 2>/dev/null
    # Also kill any stray pw-record children
    pkill -P "$loop_pid" 2>/dev/null

    rm -f "$PID_FILE" /tmp/meeting-record.path

    local chunk_count=0
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
    > "$transcript"

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
        if [ -f "$PID_FILE" ]; then
            stop_recording
        else
            start_recording
        fi
        ;;
    start)
        [ -f "$PID_FILE" ] && { echo "Already recording"; exit 1; }
        start_recording
        ;;
    stop)
        [ -f "$PID_FILE" ] || { echo "Not recording"; exit 1; }
        stop_recording
        ;;
    transcribe)
        transcribe "$2"
        ;;
    *)
        echo "Usage: $(basename "$0") [toggle|start|stop|transcribe <dir>]" >&2
        exit 1
        ;;
esac
