#!/bin/bash

# Reports Elgato Key Light state for the waybar custom/keylights module by
# querying the left light directly at its permanent IPv6 link-local address
# (derived from the device MAC), so no mDNS discovery is involved. The lights
# are toggled together, so the left light's state represents the pair.
if ! curl -s -m1 "http://[fe80::3e6a:9dff:fe14:e88f%enp6s0]:9123/elgato/lights" | grep -q '"on":1'; then
  echo '{"text": "", "class": "off"}'
else
  echo '{"text": "", "class": "on"}'
fi
