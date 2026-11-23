#!/usr/bin/env bash
# Nightly (Switchyard's platform-sweep task): runs each app's own pre-push
# check, the build for every platform its suite.toml claims, so a break that
# got pushed past the hook (or came in with a dependency) shows up the next
# morning as a red lamp and a Waybill alarm, not on the next CI run.
#
# Repos are the ones beside dot-files with a suite.toml, plus the shared
# crates. Prints one `error:` line per broken repo and exits 1.
set -uo pipefail
SITES="${BAR_APPS:-$HOME/Sites}"
repos=()
for m in "$SITES"/*/docs/assets/suite.toml "$SITES"/*/artwork/hero/suite.toml; do
  [[ -f $m ]] && repos+=("$(git -C "$(dirname "$m")" rev-parse --show-toplevel)")
done
[[ -d $SITES/bar-anchor ]] && repos+=("$SITES/bar-anchor")

failed=()
for r in "${repos[@]}"; do
  name="$(basename "$r")"
  if [[ ! -x $r/.githooks/pre-push ]]; then
    failed+=("$name has no .githooks/pre-push")
    continue
  fi
  echo "== $name"
  if ! (cd "$r" && .githooks/pre-push); then
    failed+=("$name: a claimed platform does not build; run .githooks/pre-push there")
  fi
done
for f in "${failed[@]}"; do echo "error: $f"; done
echo "checked ${#repos[@]} repos, ${#failed[@]} broken"
(( ${#failed[@]} == 0 ))
