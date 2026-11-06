# shellcheck shell=bash
# shellcheck disable=SC2016  # backticks in printf formats are Markdown, not command substitution
# Step runner shared by the rebuild phases. Source it, call rb_init, then run
# each piece of work as a step:
#
#   step critical bootloader "Install Limine"      do_bootloader
#   step minor    cargo      "cargo install tools" do_cargo
#
# Each step runs in its own subshell with `set -Eeuo pipefail`, so the first
# failing command fails the step. Output goes to the terminal and the phase log.
#
# - critical: the machine is unusable or later steps depend on it. The phase
#   stops right away with the log tail and how to resume. Fix it (or ask
#   Claude), then rerun the same script: finished steps are skipped.
# - minor: the step is written to the followups file and the phase carries on.
#   After first boot, Claude works through that file.
#
# Steps can also call `followup "text"` to record a partial problem (one AUR
# package out of thirty) without failing.
#
# Environment:
#   REBUILD_SKIP=id,id     skip these steps (they are recorded as skipped)
#   REBUILD_RETRY_MINOR=1  rerun minor steps that failed on an earlier run
#   REBUILD_REDO=id,id     rerun these steps even if they finished

RB_RED=$'\033[0;31m'
RB_YEL=$'\033[0;33m'
RB_GRN=$'\033[0;32m'
RB_BLU=$'\033[0;34m'
RB_OFF=$'\033[0m'

# rb_init <phase> <log dir>
rb_init() {
    RB_PHASE="$1"
    RB_DIR="$2"
    mkdir -p "$RB_DIR"
    RB_LOG="$RB_DIR/$RB_PHASE.log"
    RB_STATE="$RB_DIR/$RB_PHASE.state"
    RB_FOLLOWUPS="$RB_DIR/followups.md"
    RB_FAILED_MINOR=0
    touch "$RB_LOG" "$RB_STATE"
    if [[ ! -s "$RB_FOLLOWUPS" ]]; then
        cat > "$RB_FOLLOWUPS" <<'EOF'
# Rebuild followups

Minor steps that failed or were skipped during the rebuild, plus notes steps
left for later. Nothing here stopped the install. Work through them after first
boot; each entry names its phase log. Delete an entry once it is handled.
EOF
    fi
    export RB_PHASE RB_DIR RB_LOG RB_STATE RB_FOLLOWUPS
    printf '\n===== %s %s =====\n' "$RB_PHASE" "$(date '+%F %T')" >> "$RB_LOG"
}

rb_say()  { printf '%s\n' "$*" | tee -a "$RB_LOG"; }
rb_warn() { printf '%s%s%s\n' "$RB_YEL" "$*" "$RB_OFF"; printf '%s\n' "$*" >> "$RB_LOG"; }

# followup "text": record something for after first boot, without failing.
followup() {
    {
        printf '\n## %s: %s\n\n' "$RB_PHASE" "${RB_STEP:-note}"
        printf '%s\n' "$*"
        printf '\nLog: `%s`\n' "$RB_LOG"
    } >> "$RB_FOLLOWUPS"
    printf '%s  followup: %s%s\n' "$RB_YEL" "$*" "$RB_OFF"
    printf '  followup: %s\n' "$*" >> "$RB_LOG"
}

rb_listed() { [[ ",${2:-}," == *",$1,"* ]]; }

# rb_done <id>: true if the step finished on an earlier run.
rb_done() { [[ "$(awk -v id="$1" '$1 == id { s = $2 } END { print s }' "$RB_STATE")" == "done" ]]; }

# rb_forget <id>: make a step run again next time (for idempotent steps such
# as mounts that must hold on every run).
rb_forget() { sed -i "/^$1 /d" "$RB_STATE"; }

# step <critical|minor> <id> <description> <command> [args...]
step() {
    local sev="$1" id="$2" desc="$3"
    shift 3
    if [[ "$sev" != critical && "$sev" != minor ]]; then
        echo "step: bad severity '$sev' for $id" >&2
        exit 2
    fi

    local prior
    prior=$(awk -v id="$id" '$1 == id { s = $2 } END { print s }' "$RB_STATE")
    if ! rb_listed "$id" "${REBUILD_REDO:-}"; then
        if [[ "$prior" == "done" ]]; then
            rb_say "${RB_BLU}--  $id: already done${RB_OFF}"
            return 0
        fi
        if [[ "$prior" == failed-minor && "${REBUILD_RETRY_MINOR:-0}" != 1 ]]; then
            rb_say "${RB_BLU}--  $id: failed earlier, in followups (REBUILD_RETRY_MINOR=1 retries)${RB_OFF}"
            return 0
        fi
    fi
    if rb_listed "$id" "${REBUILD_SKIP:-}"; then
        rb_say "${RB_YEL}--  $id: skipped (REBUILD_SKIP)${RB_OFF}"
        if [[ "$prior" != skipped ]]; then
            RB_STEP="$id" followup "Skipped by REBUILD_SKIP: $desc"
            printf '%s skipped %s\n' "$id" "$(date +%s)" >> "$RB_STATE"
        fi
        return 0
    fi

    rb_say "${RB_BLU}==> [$sev] $id: $desc${RB_OFF}"
    local from rc
    from=$(($(wc -l < "$RB_LOG") + 1))
    # Not in an if/|| context, so set -e inside the subshell really applies.
    ( RB_STEP="$id"; set -Eeuo pipefail; "$@" ) 2>&1 | tee -a "$RB_LOG"
    rc=${PIPESTATUS[0]}

    if (( rc == 0 )); then
        printf '%s done %s\n' "$id" "$(date +%s)" >> "$RB_STATE"
        if [[ "$prior" == failed-* ]]; then
            printf '\n## %s: %s resolved\n\nThe earlier failure above was fixed; this step finished on a later run.\n' \
                "$RB_PHASE" "$id" >> "$RB_FOLLOWUPS"
        fi
        return 0
    fi

    local tail_text
    tail_text=$(sed -n "${from},\$p" "$RB_LOG" | sed 's/\x1b\[[0-9;]*m//g' | tail -n 25)
    if [[ "$sev" == minor ]]; then
        printf '%s failed-minor %s\n' "$id" "$(date +%s)" >> "$RB_STATE"
        RB_FAILED_MINOR=$((RB_FAILED_MINOR + 1))
        {
            printf '\n## %s: %s (minor, exit %s)\n\n' "$RB_PHASE" "$id" "$rc"
            printf '%s. Function `%s` in `rebuild/`. Log: `%s` from line %s.\n\n' "$desc" "$1" "$RB_LOG" "$from"
            printf '```\n%s\n```\n' "$tail_text"
        } >> "$RB_FOLLOWUPS"
        rb_warn "!!  $id failed (exit $rc): minor, recorded in $RB_FOLLOWUPS"
        return 0
    fi

    printf '%s failed-critical %s\n' "$id" "$(date +%s)" >> "$RB_STATE"
    {
        printf '\n## %s: %s (CRITICAL, exit %s)\n\n' "$RB_PHASE" "$id" "$rc"
        printf '%s. The phase stopped here. Log: `%s` from line %s.\n' "$desc" "$RB_LOG" "$from"
    } >> "$RB_FOLLOWUPS"
    printf '\n%s!!!! CRITICAL step failed: %s (%s), exit %s%s\n' "$RB_RED" "$id" "$desc" "$rc" "$RB_OFF"
    printf '%s\n\n' "$tail_text"
    printf 'Full log: %s (from line %s)\n' "$RB_LOG" "$from"
    printf 'Fix the cause, then rerun the same command. Finished steps are skipped.\n'
    printf 'To move on without it: REBUILD_SKIP=%s (only if you are sure).\n' "$id"
    type rb_on_critical &>/dev/null && rb_on_critical
    exit 1
}

# rb_summary: print how the phase went and where the followups are.
rb_summary() {
    printf '\n%s===== %s finished =====%s\n' "$RB_GRN" "$RB_PHASE" "$RB_OFF"
    if (( RB_FAILED_MINOR > 0 )); then
        printf '%s minor step(s) failed; they are in %s\n' "$RB_FAILED_MINOR" "$RB_FOLLOWUPS"
    else
        printf 'No minor failures this run. Followups: %s\n' "$RB_FOLLOWUPS"
    fi
}

# rb_ask_secret <prompt> <var>: read a value twice without echo.
rb_ask_secret() {
    local prompt="$1" var="$2" a b
    while true; do
        read -rsp "$prompt: " a; echo
        read -rsp "$prompt (again): " b; echo
        [[ -n "$a" && "$a" == "$b" ]] && break
        echo "Empty or did not match, try again."
    done
    printf -v "$var" '%s' "$a"
}
