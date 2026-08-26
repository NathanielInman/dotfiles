#!/bin/bash
# Follow the Arctis Nova Pro Wireless headset, however it happens to be linked:
#   headset ON  -> make the headset the default audio output
#   headset OFF -> hand the default output back to the desk speakers
#
# The headset reaches the PC two ways and each needs its own probe:
#
#   2.4 GHz base station - a plain USB sound card whose sink exists whether or
#   not the headset is powered, so PipeWire cannot tell on its own.
#   headsetcontrol asks the base over HID for the headset battery:
#   BATTERY_AVAILABLE/CHARGING means the headset is linked, BATTERY_UNAVAILABLE
#   means it is off or out of range.
#
#   Bluetooth - headsetcontrol cannot see this link at all, but the bluez sink
#   only exists while the headset is connected, so the sink itself is the probe.
#
# The base station wins when both are live. Output only: the Yeti X stays the
# mic (set SWITCH_MIC=1 to also move it, base station only - A2DP has no mic).
#
# Runs as headset-autoswitch.service (systemd --user). Only acts on state
# transitions, and only leaves the headset if it is still the default, so a
# manual pick in the waybar switcher is respected.

BASE_SINK='alsa_output.usb-SteelSeries_Arctis_Nova_Pro_Wireless-00.analog-stereo'
BASE_SOURCE='alsa_input.usb-SteelSeries_Arctis_Nova_Pro_Wireless-00.mono-fallback'
BT_SINK_PREFIX='bluez_output.28_9A_4B_3D_60_CB'
SPEAKER_SINK='alsa_output.pci-0000_0a_00.4.analog-stereo'
DESK_SOURCE='alsa_input.usb-Blue_Microphones_Yeti_X_2045SG003DV8_888-000313110306-00.analog-stereo'
SWITCH_MIC="${SWITCH_MIC:-0}"
POLL=2        # seconds between polls
CONFIRM=2     # consecutive identical readings before acting (HID reads flake)

# The bluez sink carries a profile suffix that changes with the profile, so
# match on the device prefix instead of pinning one name.
bt_sink() {
  pactl list short sinks 2>/dev/null \
    | awk -v p="$BT_SINK_PREFIX" 'index($2, p) == 1 { print $2; exit }'
}

base_linked() {
  local out st
  out="$(timeout 5 headsetcontrol -o json 2>/dev/null)" || return 1
  st="$(printf '%s' "$out" | jq -r '.devices[0].battery.status // "none"' 2>/dev/null)"
  [ "$st" = BATTERY_AVAILABLE ] || [ "$st" = BATTERY_CHARGING ]
}

# prints the sink the headset should be on, or nothing when it is not reachable
headset_sink() {
  if base_linked; then
    echo "$BASE_SINK"
  else
    bt_sink
  fi
}

is_headset_sink() {
  case "$1" in
    "$BASE_SINK")      return 0 ;;
    "$BT_SINK_PREFIX"*) return 0 ;;
  esac
  return 1
}

default_sink() { pactl get-default-sink 2>/dev/null; }

state=unknown; last=unset; streak=0
while true; do
  cur="$(headset_sink)"
  if [ "$cur" = "$last" ]; then streak=$((streak+1)); else streak=1; last="$cur"; fi
  if [ "$streak" -ge "$CONFIRM" ] && [ "$cur" != "$state" ]; then
    if [ -n "$cur" ]; then
      if pactl set-default-sink "$cur" 2>/dev/null; then
        if [ "$SWITCH_MIC" = 1 ] && [ "$cur" = "$BASE_SINK" ]; then
          pactl set-default-source "$BASE_SOURCE" 2>/dev/null
        fi
        if [ "$cur" = "$BASE_SINK" ]; then link="base station"; else link="Bluetooth"; fi
        notify-send -a headset -u low -i audio-headset \
          "Arctis on" "Audio output moved to the headset ($link)" 2>/dev/null
        state="$cur"
      fi
    else
      if is_headset_sink "$(default_sink)"; then
        if pactl set-default-sink "$SPEAKER_SINK" 2>/dev/null; then
          [ "$SWITCH_MIC" = 1 ] && pactl set-default-source "$DESK_SOURCE" 2>/dev/null
          notify-send -a headset -u low -i audio-speakers \
            "Arctis off" "Audio output back on the speakers" 2>/dev/null
        fi
      fi
      state=""
    fi
  fi
  sleep "$POLL"
done
