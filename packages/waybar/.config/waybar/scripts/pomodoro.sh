#!/bin/bash

STATE_FILE="/tmp/pomodoro.state"
WORK_DURATION=1500  # 25 minutes
BREAK_DURATION=300  # 5 minutes

get_state() {
    if [ -f "$STATE_FILE" ]; then
        cat "$STATE_FILE"
    else
        echo "idle|0|0"
    fi
}

save_state() {
    echo "$1|$2|$3" > "$STATE_FILE"
}

case "${1:-status}" in
    toggle)
        IFS='|' read -r state start_time paused_remaining <<< "$(get_state)"
        case "$state" in
            idle)
                save_state "work" "$(date +%s)" "0"
                notify-send "Pomodoro" "Work session started (25 min)" -i dialog-information
                ;;
            work|break)
                if [ "$paused_remaining" = "0" ]; then
                    # Running -> pause
                    elapsed=$(( $(date +%s) - start_time ))
                    [ "$state" = "work" ] && dur=$WORK_DURATION || dur=$BREAK_DURATION
                    remaining=$(( dur - elapsed ))
                    [ "$remaining" -lt 0 ] && remaining=0
                    save_state "$state" "$start_time" "$remaining"
                    notify-send "Pomodoro" "Paused"
                else
                    # Paused -> resume
                    [ "$state" = "work" ] && dur=$WORK_DURATION || dur=$BREAK_DURATION
                    new_start=$(( $(date +%s) - (dur - paused_remaining) ))
                    save_state "$state" "$new_start" "0"
                    notify-send "Pomodoro" "Resumed"
                fi
                ;;
        esac
        ;;
    reset)
        rm -f "$STATE_FILE"
        notify-send "Pomodoro" "Timer reset" -i dialog-information
        ;;
    status)
        IFS='|' read -r state start_time paused_remaining <<< "$(get_state)"
        case "$state" in
            idle)
                echo '{"text": "", "class": "idle"}'
                ;;
            work|break)
                now=$(date +%s)
                if [ "$state" = "work" ]; then
                    duration=$WORK_DURATION
                    icon=""
                else
                    duration=$BREAK_DURATION
                    icon=""
                fi

                if [ "$paused_remaining" != "0" ]; then
                    remaining=$paused_remaining
                else
                    elapsed=$(( now - start_time ))
                    remaining=$(( duration - elapsed ))
                fi

                if [ "$remaining" -le 0 ]; then
                    if [ "$state" = "work" ]; then
                        save_state "break" "$(date +%s)" "0"
                        notify-send "Pomodoro" "Break time! (5 min)" -i dialog-information
                        icon=""
                        remaining=$BREAK_DURATION
                    else
                        rm -f "$STATE_FILE"
                        notify-send "Pomodoro" "Break over! Start another?" -i dialog-information
                        echo '{"text": "", "class": "idle"}'
                        exit 0
                    fi
                fi

                minutes=$(( remaining / 60 ))
                seconds=$(( remaining % 60 ))
                printf '{"text": "%s %02d:%02d", "class": "%s"}\n' "$icon" "$minutes" "$seconds" "$state"
                ;;
        esac
        ;;
esac
