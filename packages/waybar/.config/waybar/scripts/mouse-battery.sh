#!/usr/bin/env bash
# Waybar module: Logitech mouse battery via the kernel hidpp driver.
# The hidpp_battery_N index increments on every reconnect, so glob each run.

for d in /sys/class/power_supply/hidpp_battery_*; do
    [[ -r "$d/capacity" ]] || continue
    cap=$(<"$d/capacity")
    status=$(<"$d/status")
    model=$(<"$d/model_name")

    class="ok"
    icon="󰍽"
    if [[ "$status" == "Charging" ]]; then
        class="charging"
        icon="󰚥"
    elif (( cap <= 10 )); then
        class="critical"
    elif (( cap <= 25 )); then
        class="low"
    fi

    printf '{"text": "%s %s%%", "class": "%s", "tooltip": "%s: %s%% (%s)"}\n' \
        "$icon" "$cap" "$class" "$model" "$cap" "$status"
    exit 0
done

# No battery device (mouse off or on another host): hide the module
echo '{"text": ""}'
