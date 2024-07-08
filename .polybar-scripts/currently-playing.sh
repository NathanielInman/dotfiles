#!/bin/sh

player_status=$(playerctl status 2> /dev/null)
album=$(playerctl metadata album 2> /dev/null | cut -c 1-20)
artist=$(playerctl metadata artist 2> /dev/null | cut -c 1-20)
title=$(playerctl metadata title 2> /dev/null | cut -c 1-20)

if [ "$player_status" = "Playing" ] && [ "$album" != "" ]; then
  echo "  [$album] $artist - $title"
elif [ "$player_status" = "Paused" ] && [ "$album" != "" ]; then
  echo "  [$album] $artist - $title"
elif [ "$player_status" = "Playing" ]; then
  echo "  $artist - $title"
elif [ "$player_status" = "Paused" ]; then
  echo "  $artist - $title"
else
  echo ""
fi
