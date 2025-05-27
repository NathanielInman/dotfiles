#!/bin/bash

if [ "$(dunstctl is-paused)" = "false" ]; then
  echo ""
elif [ "$(dunstctl is-paused)" = "true" ]; then
  echo ""
fi
