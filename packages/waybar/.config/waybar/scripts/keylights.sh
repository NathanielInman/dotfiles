#!/bin/bash

# Reports Elgato Key Light state for the waybar custom/keylights module by
# querying the left light directly at its fixed IoT VLAN address (a UniFi DHCP
# reservation), so no mDNS discovery is involved. The lights are toggled
# together, so the left light's state represents the pair.
if ! curl -s -m1 "http://192.168.20.90:9123/elgato/lights" | grep -q '"on":1'; then
  echo '{"text": "󰌵", "class": "off"}'
else
  echo '{"text": "󰛨", "class": "on"}'
fi
