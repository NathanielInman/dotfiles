#!/bin/bash

# Toggles the Elgato Key Lights for the waybar custom/keylights on-click.
# Addresses each light directly at its permanent IPv6 link-local address
# (derived from the device MAC), so no mDNS discovery is involved. Turning on
# restores the canonical per-light brightness (left 3, right 50), matching the
# lightson/lightsoff shell aliases.
LEFT="fe80::3e6a:9dff:fe14:e88f%enp6s0"
RIGHT="fe80::3e6a:9dff:fe14:e88e%enp6s0"

# Flip to the opposite of the left light's current state.
if curl -s -m1 "http://[$LEFT]:9123/elgato/lights" | grep -q '"on":1'; then
  on=0
else
  on=1
fi

_kl() { # $1=addr  $2=on(1)/off(0)  $3=brightness
  curl -s -m2 -X PUT "http://[$1]:9123/elgato/lights" \
    -d "{\"numberOfLights\":1,\"lights\":[{\"on\":$2,\"brightness\":$3,\"temperature\":344}]}" >/dev/null
}

_kl "$LEFT" "$on" 3 &
_kl "$RIGHT" "$on" 50 &
wait
