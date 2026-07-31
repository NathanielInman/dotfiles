#!/bin/bash

# Group all windows on the active workspace into a single group
workspace=$(hyprctl activeworkspace -j | jq '.id')
windows=($(hyprctl clients -j | jq -r ".[] | select(.workspace.id == $workspace) | .address"))

if [ ${#windows[@]} -lt 2 ]; then
  exit 0
fi

# Try the legacy keyword form first, then the lua-config (Hyprland 0.55+) form
dispatch() {
  [ "$(hyprctl dispatch $1 2>/dev/null)" = "ok" ] || hyprctl dispatch "$2" >/dev/null
}

# Focus the first window and start a group
dispatch "focuswindow address:${windows[0]}" "hl.dsp.focus({ window = \"address:${windows[0]}\" })"
dispatch "togglegroup" "hl.dsp.group.toggle()"

# Move all other windows into the group by trying every direction
for addr in "${windows[@]:1}"; do
  dispatch "focuswindow address:$addr" "hl.dsp.focus({ window = \"address:$addr\" })"
  for dir in l r u d; do
    dispatch "moveintogroup $dir" "hl.dsp.window.move({ into_group = \"$dir\" })"
  done
done
