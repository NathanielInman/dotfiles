#!/bin/bash

cd /home/nate/Sites/notes || exit # short-cut if not setup

alias git='/usr/bin/git'

# Fail loudly: Switchyard turns the task red on a non-zero exit, and the
# error matcher shows this line.
fail() { echo "error: $* (~/Sites/notes)" >&2; exit 1; }

g="$(git rev-parse --git-dir)"
if [[ -d $g/rebase-merge || -d $g/rebase-apply || -f $g/MERGE_HEAD ]]; then
  fail "a rebase or merge is in progress; finish it by hand"
fi

git remote update || fail "could not reach origin"

LOCAL=$(git rev-parse @) # HEAD
REMOTE=$(git rev-parse @\{u\}) # origin/master
BASE=$(git merge-base @ @\{u\}) # see where they diverge for rebase

if [[ $LOCAL = "$REMOTE" ]]; then
  echo "up-to-date"
elif [[ $LOCAL = "$BASE" ]]; then
  git pull --rebase --autostash || fail "pull --rebase failed" # local is behind origin/master
elif [[ $REMOTE = "$BASE" ]]; then
  git push -u origin master || fail "push failed" # origin/master is behind local
else
  fail "master and origin/master have diverged; rebase by hand"
fi

CHANGES_NUM=$(git status --porcelain | wc -l)

if [[ $CHANGES_NUM != 0 ]]; then
  git add -A
  git commit -am "cron auto-update $(date)" || fail "commit failed"
  git push -u origin master || fail "push failed"
fi
