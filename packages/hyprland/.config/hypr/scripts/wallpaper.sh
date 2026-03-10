#!/usr/bin/env bash
# Fetches a random wallpaper from Wallhaven and sets it with swww.
# Keeps only one wallpaper on disk at a time.
# Send SIGUSR1 to skip the sleep and fetch a new wallpaper immediately.

WALLPAPER="/tmp/wallpaper.jpg"
INTERVAL=900
QUERY="dark+minimalist"

trap 'true' USR1

fetch_wallpaper() {
    url=$(curl -s "https://wallhaven.cc/api/v1/search?q=${QUERY}&sorting=random&atleast=2560x1440&categories=100&purity=100" \
        | grep -o '"path":"[^"]*"' | head -1 | cut -d'"' -f4 | sed 's/\\//g')
    if [[ -n "$url" ]]; then
        curl -sL -o "$WALLPAPER" "$url"
        if [[ -s "$WALLPAPER" ]]; then
            swww img "$WALLPAPER" --transition-type fade --transition-duration 2
        fi
    fi
}

while true; do
    fetch_wallpaper
    sleep "$INTERVAL" &
    wait $!
done
