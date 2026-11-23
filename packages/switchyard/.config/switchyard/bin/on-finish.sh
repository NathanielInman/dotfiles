#!/usr/bin/env bash
# Switchyard's hooks.on_finish (config.toml). A run nobody started by hand
# (a schedule, a one-off --at, a watched timer) that failed opens one alarm
# task in Waybill's ops project: high priority, tagged alarm, so the Waybill
# lamp turns red. Later failures of the same job update that task's note
# (a count and the latest log) and add a visit only when the error changes.
# The next green run of the job, by hand or not, closes it.
#
# Nothing here calls an agent. An agent sees the task when Nate starts one,
# and may refile it under the right project.
#
# Switchyard passes YARD_TASK, YARD_LABEL, YARD_OUTCOME (ok|failed),
# YARD_TRIGGER (manual|schedule|timer), YARD_MESSAGE, YARD_ERROR, YARD_LOG,
# YARD_ENDED. Its output lands in ~/.local/state/switchyard/hooks.log.
set -uo pipefail

WAYBILL="${WAYBILL:-$HOME/.local/bin/waybill}"
ref="yard:$YARD_TASK"

# The open alarm for this job, found by its ref.
open_task() {
  "$WAYBILL" find --project ops --json "$ref" |
    python3 -c '
import json, sys
for t in json.load(sys.stdin):
    if "ref" in t.get("matched", []) and t.get("status") != "done":
        print(t["uuid"][:8]); break'
}

when() { date -d "@${1%.*}" '+%a %b %-d %H:%M'; }

id="$(open_task)" || { echo "error: waybill find failed" >&2; exit 1; }

if [[ $YARD_OUTCOME == ok ]]; then
  [[ -z $id ]] && exit 0
  "$WAYBILL" done "$id" "green again $(when "$YARD_ENDED") ($YARD_TRIGGER run)"
  exit
fi

# A failure you started by hand is one you are already looking at.
[[ $YARD_TRIGGER == manual ]] && exit 0

now="$(when "$YARD_ENDED")"
error="${YARD_ERROR:-$YARD_MESSAGE}"
error="${error%%$'\n'*}"

count=1
first="$now"
last_error=""
if [[ -n $id ]]; then
  # `waybill note ID` prints the title, then "  note  <path>".
  note="$("$WAYBILL" note "$id" | sed -n 's/^ *note  *//p' | head -1)"
  if [[ -f $note ]]; then
    count=$(( $(sed -n 's/^Failed \([0-9]*\) times\{0,1\} since .*/\1/p' "$note" | head -1) + 1 ))
    first="$(sed -n 's/^Failed [0-9]* times\{0,1\} since \(.*\)\.$/\1/p' "$note" | head -1)"
    last_error="$(sed -n 's/^    //p' "$note" | head -1)"
  fi
  [[ -z $first ]] && first="$now"
fi

file="$(mktemp)"
trap 'rm -f "$file"' EXIT
{
  echo "Switchyard's \`$YARD_LABEL\` (\`$YARD_TASK\`) is failing."
  echo
  echo "Failed $count time$( ((count == 1)) || echo s) since $first."
  echo
  echo "Last failure: $now, ${YARD_MESSAGE:-failed}:"
  echo
  echo "    ${error:-no error line found}"
  echo
  echo "- Log: \`$YARD_LOG\`"
  echo "- History: \`yard history $YARD_TASK\`"
  echo "- Run it again: \`yard run $YARD_TASK\` (a green run closes this task)"
  echo
  echo "Filed by Switchyard's on-finish hook. If the cause belongs to a project,"
  echo "refile it there and keep the alarm tag until it is fixed."
} >"$file"

if [[ -z $id ]]; then
  title="Fix $YARD_LABEL"
  "$WAYBILL" add --project ops --priority H --tag alarm --ref "$ref" --note-file "$file" -- "${title:0:50}"
else
  "$WAYBILL" note "$id" --set-file "$file"
  if [[ $error != "$last_error" ]]; then
    "$WAYBILL" visit "$id" "failing differently at $now: $error"
  fi
fi
