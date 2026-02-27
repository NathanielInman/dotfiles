#!/bin/bash

# Detect current width and height
resolution=$(hyprctl monitors -j | jq -r '.[0].width, .[0].height' 2>/dev/null)
width=$(echo "$resolution" | head -1)
height=$(echo "$resolution" | tail -1)

# Fallback if hyprctl fails
width=${width:-2560}
height=${height:-1440}

# Set maximum width and height
max_width=1200
max_height=1000

# Set percentage of screen size for dynamic adjustment
percentage_width=70
percentage_height=70

# Calculate dynamic width and height
dynamic_width=$((width * percentage_width / 100))
dynamic_height=$((height * percentage_height / 100))

# Limit width and height to maximum values
dynamic_width=$(($dynamic_width > $max_width ? $max_width : $dynamic_width))
dynamic_height=$(($dynamic_height > $max_height ? $max_height : $dynamic_height))

# Launch yad with calculated width and height
yad --width=$dynamic_width --height=$dynamic_height \
    --center \
    --title="Keybindings" \
    --no-buttons \
    --list \
    --column=Key: \
    --column=Description: \
    --column=Command: \
    --timeout-indicator=bottom \
"ESC" "close this app" "" "=" "SUPER KEY (Windows Key)" "(SUPER KEY)" \
" /" "Opens this help window" "(hotkeys)" \
" t" "Opens a floating terminal" "(ghostty)" \
" e" "Opens a file manager" "(thunar)" \
" enter" "Opens a terminal" "(ghostty)" \
" v" "Opens rofi file browser" "(rofi)" \
" c" "Start a calculator" "(galculator)" \
" r" "Toggle screen recording" "(wf-recorder)" \
" i" "Pick color from screen to clipboard" "(hyprpicker)" \
" o" "Open emoji picker" "(rofi-emoji)" \
" b" "Toggle visibility of waybar" "(waybar)" \
" Alt l" "Trigger the lock screen" "(swaylock)" \
" Alt v" "Launch clipboard manager" "(copyq)" \
" p" "Open area-specific screenshot tool" "(grim+slurp)" \
" n" "Launch notification center" "(swaync)" \
" d" "Search for an application to run" "(rofi)" \
" Shift Q" "Close the focused window" "(hyprland)" \
" h" "Change focus to tile on the left" "(hyprland)" \
" j" "Change focus to tile below current" "(hyprland)" \
" k" "Change focus to tile above current" "(hyprland)" \
" l" "Change focus to tile on the right" "(hyprland)" \
" Shift h" "Move focused tile leftwards" "(hyprland)" \
" Shift j" "Move focused tile downwards" "(hyprland)" \
" Shift k" "Move focused tile upwards" "(hyprland)" \
" Shift l" "Move focused tile rightwards" "(hyprland)" \
" f" "Change focused window to fullscreen" "(hyprland)" \
" Shift space" "Toggle focused window between tiling and floating" "(hyprland)" \
" #" "Change focused workspace to specified number 0-9" "(hyprland)" \
" Shift #" "Move focused window to specified workspace 0-9" "(hyprland)" \
" Ctrl l" "Move current workspace to monitor on the right" "(hyprland)" \
" Ctrl h" "Move current workspace to monitor on the left" "(hyprland)" \
" ." "Scroll columns right" "(hyprscrolling)" \
" ," "Scroll columns left" "(hyprscrolling)" \
" Shift ." "Move window to right column" "(hyprscrolling)" \
" Shift ," "Move window to left column" "(hyprscrolling)" \
" Ctrl f" "Fit focused column to screen" "(hyprscrolling)" \
" Ctrl Shift f" "Fit all visible columns" "(hyprscrolling)" \
" w" "Cycle column wider" "(hyprscrolling)" \
" Shift w" "Cycle column narrower" "(hyprscrolling)" \
" =" "Cycle column wider" "(hyprscrolling)" \
" -" "Cycle column narrower" "(hyprscrolling)" \
" LMB drag" "Move floating window" "(hyprland)" \
" RMB drag" "Resize floating window" "(hyprland)" \
