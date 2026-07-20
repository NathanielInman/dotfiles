#!/usr/bin/env bash
# Take a screenshot with grim+slurp+swappy, then symlink the latest as current.png

DIR="$HOME/Pictures/Screenshots"
CURRENT="$HOME/Downloads/current.png"
LAST="$HOME/Downloads/last.png"

# Record newest file before screenshot
before=$(ls -t "$DIR"/swappy-*.png 2>/dev/null | head -1)

# Two-click region select instead of press-and-hold drag: click one corner,
# then the opposite corner. The MX Master's worn left switch drops contact
# mid-hold, which ended drag selections early; short clicks are unaffected.
p1=$(slurp -p -f '%x %y') || exit 0
p2=$(slurp -p -f '%x %y') || exit 0
read -r x1 y1 <<< "$p1"
read -r x2 y2 <<< "$p2"
x=$(( x1 < x2 ? x1 : x2 ))
y=$(( y1 < y2 ? y1 : y2 ))
w=$(( x1 < x2 ? x2 - x1 : x1 - x2 ))
h=$(( y1 < y2 ? y2 - y1 : y1 - y2 ))
(( w < 1 )) && w=1
(( h < 1 )) && h=1

grim -g "${x},${y} ${w}x${h}" - | swappy -f -

# Find newest file after screenshot
after=$(ls -t "$DIR"/swappy-*.png 2>/dev/null | head -1)

# If a new file appeared, update the symlink
if [[ -n "$after" && "$after" != "$before" ]]; then
    # Move current to last before updating
    if [[ -L "$CURRENT" ]]; then
        ln -sf "$(readlink "$CURRENT")" "$LAST"
    fi
    ln -sf "$after" "$CURRENT"
fi
