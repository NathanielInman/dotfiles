#!/usr/bin/env bash
# Nightly: when the README has drifted from the bar or the apps (a new app,
# a renamed binary, a retired script still in the docs), file it as a Waybill
# task in the dotfiles project so an agent picks it up off the board. One
# open task at a time: a later night appends to its note instead.
#
#   30 3 * * * $HOME/Sites/dot-files/scripts/cron-dotfiles-drift.sh
set -uo pipefail

DOT="$HOME/Sites/dot-files"
WAYBILL="$HOME/.local/bin/waybill"
TITLE="Fix README drift in dot-files"
LOG="$HOME/.local/state/dotfiles-drift.log"
mkdir -p "$(dirname "$LOG")"

out="$(cd "$DOT" && BAR_APPS="$HOME/Sites" python3 docs/bar/build.py --check 2>&1)"
status=$?
echo "$(date -Is) check exited $status" >>"$LOG"
[[ -z "$out" ]] && exit 0

note="$(mktemp)"
trap 'rm -f "$note"' EXIT
{
  echo "\`python3 docs/bar/build.py --check\` in ~/Sites/dot-files on $(date +%F) said:"
  echo
  echo '```'
  echo "$out"
  echo '```'
  echo
  echo "Fix what it names (a suite.toml in the app's repo, the README prose, or story.py),"
  echo "run python3 docs/bar/build.py, and commit. Warnings (the desktop screenshot) need Nate."
} >"$note"

open="$("$WAYBILL" find --project dotfiles --json README drift 2>>"$LOG" |
  python3 -c 'import json,sys; t=[x for x in json.load(sys.stdin) if x["title"]==sys.argv[1]]; print(t[0]["uuid"][:8] if t else "")' "$TITLE")"
if [[ -n "$open" ]]; then
  "$WAYBILL" note "$open" --append "$(cat "$note")" >>"$LOG" 2>&1
else
  "$WAYBILL" add --project dotfiles --note-file "$note" -- "$TITLE" >>"$LOG" 2>&1
fi
