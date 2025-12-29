#!/bin/sh

# Change format here. see `man date` for format controls.
FORMAT=" %a %b %d  %H:%M"

# Add the timezones of your choice. see `timedatectl list-timezones`.
# This first timezone is ours and won't show the timezone in the bar,
# the rest will display the timezone to clarify which we're looking at
set -- "America/Chicago" "EET" "America/New_York"

TIMEZONES_LENGTH=$#
current_idx=1

print_date() {
  if [ $current_idx -eq 1 ]; then
    TZ=${current_timezone:?} date +"${FORMAT}" | echo "$(cat -)"
  else
    TZ=${current_timezone:?} date +"${FORMAT}" | echo "${current_timezone:?}: $(cat -)"
  fi
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
