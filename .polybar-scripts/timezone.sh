#!/bin/sh

# Change format here. see `man date` for format controls.
FORMAT=" %a %b %d  %H:%M"

# Add the timezones of your choice. see `timedatectl list-timezones`.
set -- "America/Chicago" "EET" "America/New_York"

TIMEZONES_LENGTH=$#
current_idx=1

print_date() {
  TZ=${current_timezone:?} date +"${FORMAT}" | echo "${current_timezone:?}: $(cat -)"
}

update_current_timezone() {
  current_idx=$(($((current_idx+1)) % $(("$TIMEZONES_LENGTH"+1))))
  if [ $current_idx -lt 1 ]; then
    current_idx=1
  fi
}

click() {
  update_current_timezone
  print_date
}

trap "click" USR1

while true; do
  eval "current_timezone=\${$current_idx}"
  print_date current_timezone
  sleep 5 &
  wait
done
