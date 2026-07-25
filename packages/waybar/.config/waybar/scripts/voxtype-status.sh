#!/bin/bash
#
# Waybar runs this as the custom/voxtype exec. On bar teardown (monitor
# sleep or hotplug) waybar kills only its direct child; a bare
# `voxtype | jq` pipeline would leave both processes orphaned, and any
# waybar pipe fds they inherited stay open forever, which wedges other
# modules' exec threads (frozen buttons, zombie children). Trap the
# teardown signal and take the whole pipeline down with us.

trap 'pkill -P $$; exit 0' TERM INT HUP

voxtype status --follow --format json | jq -c --unbuffered '. + {text: .alt}' &
wait $!
