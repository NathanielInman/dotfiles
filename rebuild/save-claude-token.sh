#!/usr/bin/env bash
# Run once on a working machine (as the user, Rime mounted) to make the next
# rebuild skip the Claude login: creates a one-year token with
# `claude setup-token` and stores it on Rime encrypted to the YubiKey.
# bootstrap.sh decrypts it on the live ISO with one touch.
#
#   bash ~/Sites/dot-files/rebuild/save-claude-token.sh
#
# Rerun when it expires (a year from creation) or after revoking it.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=config.sh
source "$HERE/config.sh"

DEST="$HOME/Rime/$RIME_REBUILD_DIR/claude-oauth-token.age"
mkdir -p "$(dirname "$DEST")"

echo "Running \`claude setup-token\`. Approve it in the browser, then copy the token it prints."
claude setup-token
echo
read -rsp "Paste the token: " token
echo
[[ -n "$token" ]] || { echo "No token given; nothing saved."; exit 1; }

printf '%s' "$token" | age -r "$AGE_RECIPIENT" -o "$DEST.new"
mv "$DEST.new" "$DEST"
unset token
date -d '+1 year' '+%F' > "$DEST.expires"
echo "Saved to ${DEST/#$HOME/\~} (encrypted to the YubiKey). Expires around $(cat "$DEST.expires")."
