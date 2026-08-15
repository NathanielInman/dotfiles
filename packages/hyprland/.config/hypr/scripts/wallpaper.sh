#!/usr/bin/env bash
# Fetches a random wallpaper from Wallhaven and sets it with awww.
# Keeps only one wallpaper on disk at a time.
# Send SIGUSR1 to skip the sleep and fetch a new wallpaper immediately.
# Send SIGUSR2 to blocklist the current wallpaper and fetch a new one.

WALLPAPER="/tmp/wallpaper.jpg"
INTERVAL=900
# One entry is picked at random per fetch. Wallhaven syntax: -tag excludes a
# tag, like:<id> searches for wallpapers similar to a favorite.
QUERIES=(
    "dark+minimalist+-satanic"
    "like:7jgx79"
)

STATE_DIR="$HOME/.local/state/wallpaper"
HISTORY="$STATE_DIR/history"    # last 20 shown ids, avoids quick repeats
BLOCKLIST="$STATE_DIR/blocklist" # banned ids, one per line
CURRENT="$STATE_DIR/current"     # id currently on screen

mkdir -p "$STATE_DIR"
touch "$HISTORY" "$BLOCKLIST"

search() {
    curl -sf --max-time 30 \
        "https://wallhaven.cc/api/v1/search?q=$1&sorting=random&atleast=2560x1440&categories=100&purity=100$2"
}

fetch_wallpaper() {
    local query page_json last_page seed page pick id url
    query=$(printf '%s\n' "${QUERIES[@]}" | shuf -n1)
    query="${query//:/%3A}"

    page_json=$(search "$query") || return
    last_page=$(jq -er '.meta.last_page' <<<"$page_json") || return
    seed=$(jq -r '.meta.seed // empty' <<<"$page_json")
    page=$(shuf -i "1-$last_page" -n1)
    if [[ "$page" != 1 ]]; then
        page_json=$(search "$query" "&page=${page}&seed=${seed}") || return
    fi

    # Drop blocklisted ids always; drop recently shown ids unless that would
    # leave nothing to pick from.
    pick=$(jq -r --rawfile bl "$BLOCKLIST" --rawfile hist "$HISTORY" '
        ($bl | split("\n") | map(select(length > 0))) as $blocked |
        ($hist | split("\n") | map(select(length > 0))) as $seen |
        [.data[] | select(.id as $i | $blocked | index($i) | not)] as $allowed |
        [$allowed[] | select(.id as $i | $seen | index($i) | not)] as $fresh |
        (if ($fresh | length) > 0 then $fresh else $allowed end) |
        .[] | "\(.id) \(.path)"' <<<"$page_json" | shuf -n1)
    [[ -n "$pick" ]] || return
    id=${pick%% *}
    url=${pick#* }

    curl -sfL --max-time 60 -o "$WALLPAPER.tmp" "$url" || return
    [[ -s "$WALLPAPER.tmp" ]] || return
    mv "$WALLPAPER.tmp" "$WALLPAPER"
    awww img "$WALLPAPER" --transition-type fade --transition-duration 2

    echo "$id" >"$CURRENT"
    printf '%s\n' "$id" >>"$HISTORY"
    tail -20 "$HISTORY" >"$HISTORY.tmp" && mv "$HISTORY.tmp" "$HISTORY"
}

ban_current() {
    local id
    id=$(cat "$CURRENT" 2>/dev/null)
    [[ -n "$id" ]] && echo "$id" >>"$BLOCKLIST"
}

BAN=0
trap 'true' USR1
trap 'BAN=1' USR2

while true; do
    if ((BAN)); then
        BAN=0
        ban_current
    fi
    fetch_wallpaper
    sleep "$INTERVAL" &
    SLEEP_PID=$!
    wait "$SLEEP_PID"
    kill "$SLEEP_PID" 2>/dev/null
done
