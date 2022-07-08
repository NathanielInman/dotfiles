#!/bin/bash

cd /home/nate/.task

alias git='/usr/bin/git'

git remote update

LOCAL=$(git rev-parse @) # HEAD
REMOTE=$(git rev-parse @{u}) # origin/master
BASE=$(git merge-base @ @{u}) # see where they diverge for rebase

if [ $LOCAL = $REMOTE ]; then
  # up-to-date
elif [ $LOCAL = $BASE ]; then
  git pull --rebase --autostash # local is behind origin/master
elif [ $REMOTE = $BASE ]; then
  git push -u origin master # origin/master is behind local
fi

CHANGES_NUM=$(git status --porcelain | wc -l)

if [ $CHANGES_NUM != 0]; then
  git add -A
  git commit -am "cron auto-update `date`"
  git push -u origin master
fi

