#!/bin/bash

# After the power-menu Idle action, the G9's secondary PBP input (DP-2)
# drops its DisplayPort link on the way into standby; the resulting hotplug
# makes Hyprland recommit that connector and the right half lights back up.
# DP-1 never does this, so "DP-2 on while DP-1 off" can only be that
# spurious wake. Deliberately weak so it can never trap the screens off:
#   - only ever touches DP-2, so DP-1 always wakes normally
#   - exits as soon as DP-1 is on (a real wake turns on all monitors)
#   - re-reads state after a 1s grace so a real wake that happens to light
#     DP-2 a beat before DP-1 is not stomped
#   - gives up after MAX_FORCES re-assertions (back to pre-guard behavior)

PIDFILE="${XDG_RUNTIME_DIR:-/tmp}/idle-dpms-guard.pid"
MAX_FORCES=10

# Single instance: a new Idle click replaces the previous guard. Verify the
# stale pid is actually us before killing, in case the pid got recycled.
oldpid=$(cat "$PIDFILE" 2>/dev/null)
if [ -n "$oldpid" ] && grep -q idle-dpms-guard "/proc/$oldpid/cmdline" 2>/dev/null; then
    kill "$oldpid" 2>/dev/null
fi
echo $$ > "$PIDFILE"
# Only remove the pidfile if it still points at us: a replacement instance
# may have already overwritten it by the time our exit trap runs.
trap '[ "$(cat "$PIDFILE" 2>/dev/null)" = "$$" ] && rm -f "$PIDFILE"' EXIT

dpms_state() { # prints "true"/"false" for monitor $1, empty on failure
    hyprctl monitors -j 2>/dev/null \
        | jq -r --arg m "$1" '.[] | select(.name == $m).dpmsStatus' 2>/dev/null
}

forces=0
while [ "$forces" -lt "$MAX_FORCES" ]; do
    sleep 2
    dp1=$(dpms_state DP-1)
    dp2=$(dpms_state DP-2)
    { [ -z "$dp1" ] || [ -z "$dp2" ]; } && exit 0 # compositor gone
    [ "$dp1" = "true" ] && exit 0                 # real wake
    if [ "$dp2" = "true" ]; then
        sleep 1
        [ "$(dpms_state DP-1)" = "true" ] && exit 0
        [ "$(dpms_state DP-2)" = "true" ] || continue
        # Legacy keyword form first, then the lua-config (Hyprland 0.55+) form
        [ "$(hyprctl dispatch dpms off DP-2 2>/dev/null)" = "ok" ] \
            || hyprctl dispatch 'hl.dsp.dpms({ action = "off", monitor = "DP-2" })'
        forces=$((forces + 1))
    fi
done
