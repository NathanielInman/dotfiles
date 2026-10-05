#!/bin/bash

# Launch neovide at login, relaunching it if no window maps. At boot neovide
# sometimes connects to Wayland and nvim but never opens a window (likely a race
# with the G9 links settling), leaving a headless process behind.
# Usage: neovide-autostart.sh <file>

attempts=3
timeout=15

sleep 5

for ((attempt = 1; attempt <= attempts; attempt++)); do
  neovide --no-fork "$@" &
  pid=$!

  for ((i = 0; i < timeout * 2; i++)); do
    sleep 0.5
    kill -0 "$pid" 2>/dev/null || break
    if hyprctl clients -j | jq -e --argjson pid "$pid" 'any(.[]; .pid == $pid)' >/dev/null; then
      exit 0
    fi
  done

  kill "$pid" 2>/dev/null
  wait "$pid" 2>/dev/null
done

notify-send "Neovide autostart" "No window after $attempts attempts" 2>/dev/null
