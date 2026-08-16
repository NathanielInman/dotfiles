#!/bin/bash
# Pick the default audio output (sink) or input (source) via a walker dmenu.
# Usage: audio-switch.sh [output|input]   (default: output)
# Streams that follow the default device (almost all of them) move over immediately.

kind="${1:-output}"
case "$kind" in
    output) section="Sinks"; placeholder="Audio output" ;;
    input)  section="Sources"; placeholder="Audio input" ;;
    *) echo "usage: $0 [output|input]" >&2; exit 2 ;;
esac

# wpctl status lines look like:  " │  *   34. Some Device Name   [vol: 0.19]"
# Print "id<TAB>label", marking the current default with a bullet.
mapfile -t entries < <(
    wpctl status | sed -n "/ ├─ ${section}:/,/^ [│ ]*$/p" | tail -n +2 \
    | sed -nE 's/^[ │]*(\*)?[ ]*([0-9]+)\. (.*[^ ])[ ]+\[vol: [0-9.]+\].*$/\2\t\1\t\3/p' \
    | awk -F'\t' '{ mark = ($2 == "*") ? "● " : "   "; printf "%s\t%s%s\n", $1, mark, $3 }'
)

if [ ${#entries[@]} -eq 0 ]; then
    notify-send -a audio-switch "No audio ${kind}s found" 2>/dev/null
    exit 1
fi

chosen=$(printf '%s\n' "${entries[@]}" | cut -f2- | walker --dmenu --placeholder "$placeholder")
[ -z "$chosen" ] && exit 0

id=$(printf '%s\n' "${entries[@]}" | awk -F'\t' -v c="$chosen" '$2 == c { print $1; exit }')
[ -n "$id" ] && wpctl set-default "$id"
