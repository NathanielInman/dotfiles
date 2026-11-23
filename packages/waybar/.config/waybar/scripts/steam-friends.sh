#!/usr/bin/env bash
# Toggle Steam's floating Friends List window:
# - Visible on a monitor: close it (Steam keeps running in the background)
# - Open on a hidden workspace: pull it onto the active workspace and focus it
# - Not open: open it via steam://open/friends (rules.lua floats and places it)
set -euo pipefail

info="$(hyprctl clients -j | jq -r '
  first(.[] | select(.class == "steam" and (.initialTitle == "Friends List" or .title == "Friends List")))
  | if . then "\(.address) \(.workspace.id)" else "" end
')"

if [[ -n "$info" ]]; then
  read -r addr ws <<< "$info"
  visible="$(hyprctl monitors -j | jq -r --argjson ws "$ws" 'any(.[]; .activeWorkspace.id == $ws)')"
  if [[ "$visible" == "true" ]]; then
    hyprctl dispatch "hl.dsp.window.close({ window = \"address:$addr\" })" >/dev/null
  else
    active_ws="$(hyprctl activeworkspace -j | jq -r '.id')"
    hyprctl dispatch "hl.dsp.window.move({ window = \"address:$addr\", workspace = $active_ws, follow = true })" >/dev/null
  fi
  exit 0
fi

setsid -f steam steam://open/friends </dev/null >/dev/null 2>&1
