#!/bin/bash
#
# cron-sites-nightly-backup.sh
#
# Nightly safety net so an HDD failure can never again eat days of uncommitted
# work. Walks every git repo directly under ~/Sites and, if its working tree is
# dirty, gets that work onto a remote:
#
#   * Owned repos  (nathanielinman | theoestudio | ion-cloud | twinspear-games)
#       -> atomic conventional commit on the branch you're already on, then push.
#          A local commit alone wouldn't survive a dead disk, so we push too.
#
#   * Everything else (e.g. work repos)
#       -> NON-DESTRUCTIVE snapshot. We build a commit of the dirty tree in a
#          throw-away index and push it to a rolling backup/auto/<host>/<branch>
#          branch WITHOUT touching your checkout, index, HEAD or working tree.
#          You wake up exactly as you left it; the work is just also on the remote.
#
# Deliberately does NOT call Claude or any network LLM: the backup must succeed
# unattended at 3am even when rate-limited/offline, so commit messages are
# deterministic. See docs/sites-nightly-backup.md for the full rationale.
#
# Install:  crontab -e  ->  0 3 * * * /home/nate/Sites/dot-files/scripts/cron-sites-nightly-backup.sh
# Dry run:  DRY_RUN=1 /home/nate/Sites/dot-files/scripts/cron-sites-nightly-backup.sh

# --- cron-safe environment -------------------------------------------------
# cron starts with almost no env, so be explicit about HOME and PATH (the latter
# must reach git plus the gh/glab credential helpers used to push over HTTPS).
export HOME="${HOME:-/home/nate}"
export PATH="/usr/local/bin:/usr/bin:/bin:$HOME/.local/bin:$HOME/bin:$HOME/.cargo/bin:$HOME/.npm-global/bin"

alias git='/usr/bin/git'

# --- configuration ---------------------------------------------------------
SITES_DIR="$HOME/Sites"

# Repo owners whose dirty trees get committed straight onto the current branch.
# Matched case-insensitively against the first path segment of the remote URL.
ALLOWLIST=(nathanielinman theoestudio ion-cloud twinspear-games)

# Untracked files that look like secrets/credentials get flagged before they can
# be pushed to a remote. The proper fix is to add them to .gitignore; set
# EXCLUDE_RISKY=1 to also actively hold them out of the backup.
SECRET_PATTERNS=('.env' '*.env' '.env.*' '*.pem' '*.key' '*.p12' '*.pfx'
                 'id_rsa*' '*id_ed25519*' '*credentials*' '*secret*' '*.kdbx')
EXCLUDE_RISKY="${EXCLUDE_RISKY:-0}"

DRY_RUN="${DRY_RUN:-0}"

# --- logging ---------------------------------------------------------------
LOG_DIR="$HOME/.local/state/sites-nightly-backup"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/backup-$(date +%F).log"

log() { printf '%s %s\n' "$(date '+%H:%M:%S')" "$*" | tee -a "$LOG_FILE"; }

TS="$(date '+%Y-%m-%dT%H:%M:%S%z')"
HOST="$(printf '%s' "$(uname -n)" | tr 'A-Z' 'a-z' | tr -c 'a-z0-9._-' '-')"

# --- helpers ---------------------------------------------------------------

# Lowercased first path segment of a remote URL (the github org / gitlab top
# group). Handles https://, ssh://, and scp-style git@host:owner/repo forms.
repo_owner() {
  local url="$1"
  url="${url#*://}"   # strip scheme if present
  url="${url#*@}"     # strip user@
  url="${url/://}"    # scp-style host:owner -> host/owner (first colon only)
  local path="${url#*/}"   # drop host
  local owner="${path%%/*}"
  printf '%s' "${owner,,}"
}

is_owned() {
  local o="$1" a
  for a in "${ALLOWLIST[@]}"; do [[ "$o" == "$a" ]] && return 0; done
  return 1
}

# True if a merge/rebase/cherry-pick/revert is mid-flight; committing then would
# corrupt the operation, so we leave such repos untouched.
op_in_progress() {
  local repo="$1" gitdir
  gitdir="$(git -C "$repo" rev-parse --absolute-git-dir 2>/dev/null)" || return 1
  [[ -e "$gitdir/MERGE_HEAD" || -e "$gitdir/CHERRY_PICK_HEAD" || -e "$gitdir/REVERT_HEAD" \
     || -d "$gitdir/rebase-merge" || -d "$gitdir/rebase-apply" ]]
}

# Builds an array `EXCLUDES` of pathspecs for risky untracked files, logging a
# warning for each. Whether they're actually excluded depends on EXCLUDE_RISKY.
EXCLUDES=()
scan_risky() {
  local repo="$1" f pat
  EXCLUDES=()
  while IFS= read -r f; do
    [[ -z "$f" ]] && continue
    for pat in "${SECRET_PATTERNS[@]}"; do
      # shellcheck disable=SC2053
      if [[ "${f##*/}" == $pat || "$f" == $pat ]]; then
        log "  ! risky untracked file: $f (matches '$pat')"
        EXCLUDES+=(":(exclude)$f")
        break
      fi
    done
  done < <(git -C "$repo" ls-files --others --exclude-standard)

  if [[ ${#EXCLUDES[@]} -gt 0 && "$EXCLUDE_RISKY" != "1" ]]; then
    log "  ! ${#EXCLUDES[@]} risky file(s) WILL be backed up (set EXCLUDE_RISKY=1 or add to .gitignore to prevent)"
    EXCLUDES=()   # warn-only by default
  fi
}

# Non-destructive snapshot: stage the whole working tree into a temporary index,
# write a tree+commit from it, and push that commit straight to a backup ref.
# Never mutates the repo's real index, HEAD, branch or working tree.
snapshot_and_push() {
  local repo="$1" branch="$2"
  local ref="refs/heads/backup/auto/$HOST/${branch:-detached}"
  if [[ "$DRY_RUN" == "1" ]]; then
    log "  [dry-run] would snapshot -> $ref"
    return 0
  fi

  local idx tree commit
  idx="$(mktemp)"
  GIT_INDEX_FILE="$idx" git -C "$repo" read-tree HEAD
  GIT_INDEX_FILE="$idx" git -C "$repo" add -A -- . "${EXCLUDES[@]}"
  tree="$(GIT_INDEX_FILE="$idx" git -C "$repo" write-tree)"
  rm -f "$idx"

  commit="$(git -C "$repo" commit-tree "$tree" -p HEAD \
              -m "chore(backup): nightly snapshot $TS")" || {
    log "  ERROR: failed to build snapshot commit"; return 1; }

  if git -C "$repo" push --force origin "$commit:$ref" >>"$LOG_FILE" 2>&1; then
    log "  snapshot pushed -> $ref"
  else
    log "  !!! ERROR: snapshot push FAILED -> $ref (backup did not reach remote)"
    return 1
  fi
}

# Owned repos: commit on the current branch and push it. If the upstream push is
# rejected (diverged), fall back to force-pushing a backup ref so the work still
# leaves the disk rather than relying on the local commit alone.
commit_and_push() {
  local repo="$1" branch="$2"
  if [[ "$DRY_RUN" == "1" ]]; then
    log "  [dry-run] would commit on '$branch' and push"
    return 0
  fi

  git -C "$repo" add -A -- . "${EXCLUDES[@]}"
  git -C "$repo" commit -m "chore: nightly backup $TS" >>"$LOG_FILE" 2>&1 || {
    log "  nothing staged to commit (all changes excluded?)"; return 0; }

  if git -C "$repo" push >>"$LOG_FILE" 2>&1; then
    log "  committed + pushed on '$branch'"
  else
    local ref="refs/heads/backup/auto/$HOST/$branch"
    log "  ! upstream push rejected; force-pushing backup ref instead"
    if git -C "$repo" push --force origin "HEAD:$ref" >>"$LOG_FILE" 2>&1; then
      log "  committed locally + pushed -> $ref"
    else
      log "  !!! ERROR: commit made locally but BOTH pushes FAILED (not on remote)"
      return 1
    fi
  fi
}

# --- main ------------------------------------------------------------------
log "=== nightly ~/Sites backup ($TS) host=$HOST dry_run=$DRY_RUN ==="

shopt -s nullglob
for repo in "$SITES_DIR"/*/; do
  repo="${repo%/}"
  [[ -d "$repo/.git" ]] || continue
  name="${repo##*/}"

  # Skip repos with no commits yet (commit-tree -p HEAD needs a parent).
  if ! git -C "$repo" rev-parse -q --verify HEAD >/dev/null 2>&1; then
    log "$name: skip (no commits yet)"; continue
  fi
  if op_in_progress "$repo"; then
    log "$name: skip (merge/rebase in progress)"; continue
  fi
  if [[ -z "$(git -C "$repo" status --porcelain)" ]]; then
    log "$name: clean"; continue
  fi

  url="$(git -C "$repo" remote get-url origin 2>/dev/null)"
  if [[ -z "$url" ]]; then
    log "$name: !!! DIRTY but has NO remote — cannot back up off this disk"; continue
  fi

  branch="$(git -C "$repo" symbolic-ref --quiet --short HEAD 2>/dev/null)"
  owner="$(repo_owner "$url")"
  log "$name: dirty (owner=$owner branch=${branch:-<detached>})"

  scan_risky "$repo"

  # Detached HEAD has no branch to commit onto, so always snapshot it.
  if is_owned "$owner" && [[ -n "$branch" ]]; then
    commit_and_push "$repo" "$branch"
  else
    [[ -z "$branch" ]] && log "  detached HEAD -> snapshot"
    snapshot_and_push "$repo" "$branch"
  fi
done

log "=== done ==="
