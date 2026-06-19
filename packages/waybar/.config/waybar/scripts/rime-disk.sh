#!/usr/bin/env bash
# Waybar custom module: Rime SMB share (TrueNAS //192.168.1.51/private -> ~/Rime)
#
# Shows used/total only when the share is ACTUALLY mounted, and never triggers
# the on-demand automount itself (it reads /proc/self/mountinfo instead of
# stat-ing the mountpoint, which would force a mount). When unmounted it shows
# "idle" if the NAS is reachable, or "offline" if it isn't.

set -uo pipefail

MOUNT=/home/nate/Rime
ICON=$'\uf473'
SERVER=192.168.1.51
PORT=445

# Human-readable binary units, matching the built-in disk module's style.
hum() {
  awk -v b="$1" 'BEGIN{
    split("B KiB MiB GiB TiB PiB", u, " ");
    i = 1;
    while (b >= 1024 && i < 6) { b /= 1024; i++ }
    if (i == 1) printf "%d %s", b, u[i];
    else        printf "%.1f %s", b, u[i];
  }'
}

# Mounted? Inspect mountinfo directly — do NOT stat $MOUNT, which would trigger
# the autofs mount we are deliberately leaving on-demand.
if awk -v m="$MOUNT" '$5==m && / cifs /{f=1} END{exit !f}' /proc/self/mountinfo; then
  read -r used size avail < <(df -B1 --output=used,size,avail "$MOUNT" 2>/dev/null | tail -1)
  if [ -n "${size:-}" ] && [ "${size:-0}" -gt 0 ]; then
    pct=$(( used * 100 / size ))
    text="$ICON Rime $(hum "$used")/$(hum "$size")"
    tip="Rime (//$SERVER/private): $(hum "$used") used · $(hum "$avail") free · $(hum "$size") total (${pct}%)"
    printf '{"text":"%s","tooltip":"%s","class":"mounted"}\n' "$text" "$tip"
    exit 0
  fi
fi

# Not mounted: fast, non-blocking reachability probe (never touches $MOUNT).
if timeout 1 bash -c "exec 3<>/dev/tcp/$SERVER/$PORT" 2>/dev/null; then
  printf '{"text":"%s","tooltip":"%s","class":"idle"}\n' \
    "$ICON Rime idle" "Rime available — mounts automatically when you open $MOUNT"
else
  printf '{"text":"%s","tooltip":"%s","class":"offline"}\n' \
    "$ICON Rime offline" "Rime — NAS $SERVER unreachable"
fi
