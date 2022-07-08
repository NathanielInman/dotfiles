#!/bin/bash

cd /home/nate/Sites/notes

alias git='/usr/bin/git'

git remote update

LOCAL=$(git rev-parse @)
REMOTE=$(git rev-parse HEAD)

if [ $LOCAL != $REMOTE ]; then
  git pull --rebase --autostash
  git add -A
  git commit -am "cron auto-update `date`"
  git push -u origin master
fi
