#!/bin/bash

# hide all urgent i3 workspace windows
for i in $(xdotool search --class .\*)
do
  xdotool set_window --urgency 0 $i
done

# toggle silencing of notifications
if [ "$(dunstctl is-paused)" = "false" ]; then
  dunstctl set-paused true
elif [ "$(dunstctl is-paused)" = "true" ]; then
  dunstctl set-paused false
fi
