#!/bin/bash

# Toggles the Elgato Key Lights for the waybar custom/keylights on-click.
# Addresses each light directly at its fixed IoT VLAN address (a UniFi DHCP
# reservation), so no mDNS discovery is involved. Turning on
# restores the canonical lighting, matching the lightson/lightsoff shell
# aliases in .zshrc and env.nu. The left light sits off to the side and is the
# key; the right sits near the camera axis and only fills, since as a key it
# lights the face flat. Left 36 / right 11 at 312 mireds (3200K), tuned on
# camera 2026-11-16: about 3:1 key to fill. 344 (2900K) turned skin orange.
# The lights apply these values on every toggle, so change them here, not
# only in the Elgato app.
LEFT="192.168.20.90"
RIGHT="192.168.20.91"

# Flip to the opposite of the left light's current state.
if curl -s -m1 "http://$LEFT:9123/elgato/lights" | grep -q '"on":1'; then
  on=0
else
  on=1
fi

_kl() { # $1=addr  $2=on(1)/off(0)  $3=brightness
  curl -s -m2 -X PUT "http://$1:9123/elgato/lights" \
    -d "{\"numberOfLights\":1,\"lights\":[{\"on\":$2,\"brightness\":$3,\"temperature\":312}]}" >/dev/null
}

_kl "$LEFT" "$on" 36 &
_kl "$RIGHT" "$on" 11 &
wait

# Redraw custom/keylights now instead of at its next poll
pkill -RTMIN+10 -x waybar 2>/dev/null
