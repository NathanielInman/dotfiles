# Nightly `~/Sites` Backup

A safety-net cron that guarantees no uncommitted work in `~/Sites` can be lost to a
dead disk. After an HDD failure ate days of work, the rule is simple: every night,
any dirty repo gets its working tree onto a remote.

> [!IMPORTANT]
> `~/Sites` is exclusively git repositories. The cron assumes every directly-nested
> directory is a git repo with a remote. A dirty repo with **no** remote can't be
> backed up off the disk and is logged as a loud warning.

Script: [`scripts/cron-sites-nightly-backup.sh`](../scripts/cron-sites-nightly-backup.sh)

## What it does

Every night at 3am it walks each repo directly under `~/Sites`. Clean repos are
skipped. For a dirty repo, behavior depends on who owns the remote:

| Repo owner | Action | Result in the morning |
| --- | --- | --- |
| `nathanielinman`, `theoestudio`, `ion-cloud`, `twinspear-games` | Atomic conventional commit on the branch you're on, then `git push` | Your changes are a real commit on your branch, on the remote |
| Anything else (e.g. work repos) | **Non-destructive snapshot** pushed to `backup/auto/<host>/<branch>` | Working tree untouched — you wake up exactly as you left it, but a copy is on the remote |

Owner is matched case-insensitively against the first path segment of the `origin`
URL (the GitHub org or top-level GitLab group), so `https://gitlab.com/digitalturbine/...`
→ `digitalturbine` (not owned → snapshot), `https://github.com/NathanielInman/...`
→ `nathanielinman` (owned → commit + push).

> [!TIP]
> The asymmetry is intentional. Auto-committing onto a shared work branch would
> pollute it and disrupt teammates/CI, so work repos get an isolated backup branch
> instead — and they get it *without* moving your checkout, so your active branch and
> dirty files are exactly where you left them.

### The non-destructive snapshot

For non-owned repos the script never runs `git add`/`commit`/`checkout` against your
repo. It stages the working tree (tracked **and** untracked, honoring `.gitignore`)
into a throw-away index, writes a tree and a commit object from that, and force-pushes
just that commit to a backup ref:

```bash
GIT_INDEX_FILE=$tmp git read-tree HEAD      # seed temp index from HEAD
GIT_INDEX_FILE=$tmp git add -A              # capture the dirty tree (temp index only)
tree=$(GIT_INDEX_FILE=$tmp git write-tree)
commit=$(git commit-tree "$tree" -p HEAD -m "chore(backup): nightly snapshot ...")
git push --force origin "$commit:refs/heads/backup/auto/<host>/<branch>"
```

Your real index, `HEAD`, current branch, and working files are never touched. The
backup branch is a single rolling snapshot per source branch (force-updated nightly) —
because uncommitted work is cumulative, last night's snapshot already contains
everything you haven't self-committed, so no branch sprawl or history pruning is needed.

### No LLM by design

Commit messages are deterministic (`chore: nightly backup <ts>` /
`chore(backup): nightly snapshot <ts>`) — Claude is intentionally **not** invoked. The
backup has to succeed unattended at 3am even when rate-limited or offline, so it must
never depend on a network LLM or an OAuth token refresh.

## Recovering work from a backup branch

```bash
# See what backup snapshots exist for a repo
git -C ~/Sites/<repo> ls-remote --heads origin 'backup/auto/*'

# Fetch and inspect a snapshot without disturbing your current work
git fetch origin 'refs/heads/backup/auto/<host>/<branch>:refs/backups/<branch>'
git diff HEAD refs/backups/<branch>          # what the snapshot has that you don't
git checkout refs/backups/<branch> -- path/to/file   # restore a single file
```

For owned repos that failed their upstream push (diverged branch), the work is
committed locally **and** force-pushed to `backup/auto/<host>/<branch>` as a fallback,
so it's recoverable the same way.

## Safeguards

- **In-progress operations** (merge/rebase/cherry-pick/revert) and repos with no
  commits yet are skipped — committing into them would corrupt state.
- **Secret/credential guard**: untracked files matching `.env`, `*.pem`, `*.key`,
  `id_rsa*`, `*credentials*`, etc. are logged as warnings before they'd reach a remote.
  The right fix is to add them to `.gitignore`; run with `EXCLUDE_RISKY=1` to actively
  hold them out of the backup. Tune `SECRET_PATTERNS` at the top of the script.
- **Per-repo isolation**: a failure in one repo is logged and the run continues.
- Logs are written to `~/.local/state/sites-nightly-backup/backup-<date>.log`.

## Install

The cron isn't managed by stow — add it to your crontab once:

```bash
# Make sure cronie is running (see setting-up-archlinux.md)
sudo systemctl enable cronie.service --now

# crontab -e, then add:
0 3 * * * /home/nate/Sites/dot-files/scripts/cron-sites-nightly-backup.sh
```

> [!TIP]
> Push works in cron because `~/.git-credentials` holds plaintext HTTPS tokens for
> `github.com` and `gitlab.com` (the `store` credential helper), so auth doesn't depend
> on a graphical keyring/DBus session that won't exist at 3am. If you ever rotate to a
> keyring-only setup, re-add the tokens to `~/.git-credentials` or the cron pushes will
> silently fail — check the logfile.

## Dry run / testing

```bash
# Show what each repo would do, without committing or pushing anything
DRY_RUN=1 ~/Sites/dot-files/scripts/cron-sites-nightly-backup.sh

# Inspect the latest log
cat ~/.local/state/sites-nightly-backup/backup-$(date +%F).log
```

## Disable

Remove the `0 3 * * *` line from `crontab -e`.
