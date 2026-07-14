#!/bin/sh

# When notifications are silenced (swaync DND on) treat it as "in a meeting"
# and hide the now-playing title, so screen-shared music titles stay private.
if [ "$(swaync-client -D 2> /dev/null)" = "true" ]; then
  echo ""
  exit 0
fi

player_status=$(playerctl status 2> /dev/null)
album=$(playerctl metadata album 2> /dev/null | cut -c 1-20)
artist=$(playerctl metadata artist 2> /dev/null | cut -c 1-20)
title=$(playerctl metadata title 2> /dev/null | cut -c 1-20)

if [ "$player_status" = "Playing" ] && [ "$album" != "" ] && [ "$artist" != "" ]; then
  echo "  [$album] $artist - $title"
elif [ "$player_status" = "Paused" ] && [ "$album" != "" ] && [ "$artist" != "" ]; then
  echo "  [$album] $artist - $title"
elif [ "$player_status" = "Playing" ] && [ "$artist" != "" ]; then
  echo "  $artist - $title"
elif [ "$player_status" = "Paused" ] && [ "$artist" != "" ]; then
  echo "  $artist - $title"
elif [ "$player_status" = "Playing" ]; then
  echo "  $title"
elif [ "$player_status" = "Paused" ]; then
  echo "  $title"
else
  echo ""
fi
