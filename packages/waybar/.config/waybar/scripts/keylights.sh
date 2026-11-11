#!/bin/bash

# Reports Elgato Key Light state for the waybar key lights modules by
# querying the left light directly at its fixed IoT VLAN address (a UniFi DHCP
# reservation), so no mDNS discovery is involved. The lights are toggled
# together, so the left light's state represents the pair.
#
# With no argument the lamp always shows. `on` or `off` prints it only in that
# state and an empty text otherwise, which hides the module: the bar keeps a
# lit lamp outside the desk drawer and the unlit one inside it.
only="$1"

if curl -s -m1 "http://192.168.20.90:9123/elgato/lights" | grep -q '"on":1'; then
  state=on text="󰛨"
else
  state=off text="󰌵"
fi

if [ -n "$only" ] && [ "$only" != "$state" ]; then
  text=""
fi
echo "{\"text\": \"$text\", \"class\": \"$state\"}"
