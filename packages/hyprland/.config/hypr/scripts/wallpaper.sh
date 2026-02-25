#!/usr/bin/env bash
# Fetches a random wallpaper from Unsplash and sets it with swww.
# Keeps only one wallpaper on disk at a time.

WALLPAPER="/tmp/wallpaper.jpg"
INTERVAL=900
URL="https://picsum.photos/3840/2160"

while true; do
    curl -sL -o "$WALLPAPER" "$URL"
    if [[ -s "$WALLPAPER" ]]; then
        swww img "$WALLPAPER" --transition-type fade --transition-duration 2
    fi
    sleep "$INTERVAL"
done
