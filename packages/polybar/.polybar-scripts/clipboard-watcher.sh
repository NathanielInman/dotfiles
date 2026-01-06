#!/bin/bash
# X11 clipboard watcher for cliphist using clipnotify

while clipnotify; do
  xsel --clipboard --output | cliphist store
done
