#!/bin/bash

# Actions:
# CTRL Del to delete an entry
# ALT Del to wipe clipboard contents

while true; do
  result=$(
    rofi -dmenu \
      -config ~/.config/rofi/config.rasi < <(dunstctl history | jq '.data[] | .[] | [.id.data, .body.data] | join("     ")' | tr -d '"')
  )

  case "$?" in
    1)
      exit
      ;;
    0)
      dunstctl history-pop $($result | awk '{print $1;}')
      exit
      ;;
  esac
done
