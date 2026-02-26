#!/usr/bin/env bash
# Take a screenshot with grim+slurp+swappy, then symlink the latest as current.png

DIR="$HOME/Pictures/Screenshots"
CURRENT="$DIR/current.png"

# Record newest file before screenshot
before=$(ls -t "$DIR"/swappy-*.png 2>/dev/null | head -1)

grim -g "$(slurp)" - | swappy -f -

# Find newest file after screenshot
after=$(ls -t "$DIR"/swappy-*.png 2>/dev/null | head -1)

# If a new file appeared, update the symlink
if [[ -n "$after" && "$after" != "$before" ]]; then
    ln -sf "$after" "$CURRENT"
fi
