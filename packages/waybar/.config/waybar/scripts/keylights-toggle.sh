#!/bin/bash

lights=$(keylightctl discover 2> /dev/null | grep "Light" | cut -c 25-29)
state="unknown"

for light in $lights; do
  if [ "$state" = "unknown" ]; then
    if [ "$(keylightctl describe --light $light | grep $light | cut -c 34-36)" = "off" ]; then
      state="on"
    else
      state="off"
    fi
  fi
  if [ "$state" = "on" ]; then
    keylightctl switch --all on
  elif [ "$state" = "off" ]; then
    keylightctl switch --all off
  fi
done
