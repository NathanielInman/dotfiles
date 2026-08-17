#!/bin/bash
# Follow the Arctis Nova Pro Wireless headset (2.4 GHz base station over USB):
#   headset ON  -> make the base station the default audio output
#   headset OFF -> hand the default output back to the desk speakers
#
# The base station is a plain USB sound card whose sink exists whether or not
# the headset is powered, so PipeWire cannot tell on its own. headsetcontrol
# asks the base over HID for the headset battery: BATTERY_AVAILABLE/CHARGING
# means the headset is linked, BATTERY_UNAVAILABLE means it is off / out of
# range. Output only: the Yeti X stays the mic (set SWITCH_MIC=1 to also move it).
#
# Runs as headset-autoswitch.service (systemd --user). Only acts on state
# transitions, and only leaves the base station if it is still the default,
# so a manual pick in the waybar switcher is respected.

BASE_SINK='alsa_output.usb-SteelSeries_Arctis_Nova_Pro_Wireless-00.analog-stereo'
BASE_SOURCE='alsa_input.usb-SteelSeries_Arctis_Nova_Pro_Wireless-00.mono-fallback'
SPEAKER_SINK='alsa_output.pci-0000_0a_00.4.analog-stereo'
DESK_SOURCE='alsa_input.usb-Blue_Microphones_Yeti_X_2045SG003DV8_888-000313110306-00.analog-stereo'
SWITCH_MIC="${SWITCH_MIC:-0}"
POLL=2        # seconds between polls
CONFIRM=2     # consecutive identical readings before acting (HID reads flake)

# prints: on | off | absent
headset_state() {
  local out st
  out="$(timeout 5 headsetcontrol -o json 2>/dev/null)" || { echo absent; return; }
  st="$(printf '%s' "$out" | jq -r '.devices[0].battery.status // "none"' 2>/dev/null)"
  case "$st" in
    BATTERY_AVAILABLE|BATTERY_CHARGING) echo on ;;
    BATTERY_UNAVAILABLE)                echo off ;;
    *)                                  echo absent ;;
  esac
}

default_sink() { pactl get-default-sink 2>/dev/null; }

state=unknown; last=""; streak=0
while true; do
  cur="$(headset_state)"
  if [ "$cur" = "$last" ]; then streak=$((streak+1)); else streak=1; last="$cur"; fi
  if [ "$streak" -ge "$CONFIRM" ] && [ "$cur" != "$state" ]; then
    case "$cur" in
      on)
        if pactl set-default-sink "$BASE_SINK" 2>/dev/null; then
          [ "$SWITCH_MIC" = 1 ] && pactl set-default-source "$BASE_SOURCE" 2>/dev/null
          notify-send -a headset -u low -i audio-headset "Arctis on" "Audio output moved to the headset" 2>/dev/null
          state=on
        fi
        ;;
      off|absent)
        if [ "$(default_sink)" = "$BASE_SINK" ]; then
          if pactl set-default-sink "$SPEAKER_SINK" 2>/dev/null; then
            [ "$SWITCH_MIC" = 1 ] && pactl set-default-source "$DESK_SOURCE" 2>/dev/null
            notify-send -a headset -u low -i audio-speakers "Arctis off" "Audio output back on the speakers" 2>/dev/null
          fi
        fi
        state="$cur"
        ;;
    esac
  fi
  sleep "$POLL"
done
