#!/bin/bash

# Group all windows on the active workspace into a single group
workspace=$(hyprctl activeworkspace -j | jq '.id')
windows=($(hyprctl clients -j | jq -r ".[] | select(.workspace.id == $workspace) | .address"))

if [ ${#windows[@]} -lt 2 ]; then
  exit 0
fi

# Focus the first window and start a group
hyprctl dispatch focuswindow "address:${windows[0]}"
hyprctl dispatch togglegroup

# Move all other windows into the group by trying every direction
for addr in "${windows[@]:1}"; do
  hyprctl dispatch focuswindow "address:$addr"
  hyprctl dispatch moveintogroup l
  hyprctl dispatch moveintogroup r
  hyprctl dispatch moveintogroup u
  hyprctl dispatch moveintogroup d
done
