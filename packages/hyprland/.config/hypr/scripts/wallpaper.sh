#!/usr/bin/env bash
# Fetches a random wallpaper from Unsplash and sets it with swww.
# Keeps only one wallpaper on disk at a time.
# Send SIGUSR1 to skip the sleep and fetch a new wallpaper immediately.

source ~/.config/unsplash/credentials

WALLPAPER="/tmp/wallpaper.jpg"
INTERVAL=900
QUERY="dark minimalist"

trap 'true' USR1

fetch_wallpaper() {
    encoded_query=$(printf '%s' "$QUERY" | sed 's/ /%20/g')
    url=$(curl -s "https://api.unsplash.com/photos/random?query=${encoded_query}&orientation=landscape&content_filter=high" \
        -H "Authorization: Client-ID ${UNSPLASH_ACCESS_KEY}" \
        | grep -o '"full":"[^"]*"' | head -1 | cut -d'"' -f4)
    if [[ -n "$url" ]]; then
        curl -sL -o "$WALLPAPER" "${url}&w=3840&q=85"
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
