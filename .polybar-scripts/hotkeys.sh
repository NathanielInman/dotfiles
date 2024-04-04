#!/bin/bash

# Detect current width and height
width=$(xrandr --current | grep '*' | uniq | awk '{print $1}' | cut -d 'x' -f1)
height=$(xrandr --current | grep '*' | uniq | awk '{print $1}' | cut -d 'x' -f2)

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
"ESC" "close this app" "" "=" "SUPER KEY (Windows Key)" "(SUPER KEY)" \
" /" "Opens this help window" "(kitty)" \
" t" "Opens a floating terminal" "(kitty)" \
" e" "Opens a file manager" "(thunar)" \
" enter" "Opens a terminal" "(kitty)" \
" v" "Opens rofi to search for file, then opens neovim" "(neovim)" \
" c" "Start a calculator" "(galculator)" \
" b" "Toggle visibility of polybar" "(polybar)" \
" Alt l" "Trigger the screensaver" "(xscreensaver)" \
" Alt v" "Launch clipboard manager" "(cliphist)" \
" p" "Open area-specific screen shotting tool" "(flameshot)" \
" n" "Launch a history of notifications" "(dunst)" \
" d" "Search for an application to run" "(rofi)" \
" Ctrl w" "Search for a window to open" "(rofi)" \
" Ctrl d" "Search for an ssh window to open" "(rofi)" \
" Shift Q" "Close the focused window" "(i3)" \
" h" "Change focus to tile on the left" "(i3)" \
" j" "Change focus to tile below current" "(i3)" \
" k" "Change focus to tile above current" "(i3)" \
" l" "Change focus to tile on the right" "(i3)" \
" Shift h" "Move focused tile leftwards" "(i3)" \
" Shift j" "Move focused tile downwards" "(i3)" \
" Shift k" "Move focused tile upwards" "(i3)" \
" Shift l" "Move focused tile rightwards" "(i3)" \
" \"" "Change split orientation to horizontal" "(i3)" \
" |" "Change split orientation to vertical" "(i3)" \
" f" "Change focused window to fullscreen" "(i3)" \
" s" "Change container to stacking layout" "(i3)" \
" w" "Change container to tabbed layout" "(i3)" \
" x" "Change container to split layout" "(i3)" \
" Shift space" "Toggle focused window between tiling and floating" "(i3)" \
" space" "Toggle focus between tiling and floating windows" "(i3)" \
" a" "Change focus to parent container" "(i3)" \
" #" "Change focused workspace to specified number 0-9" "(i3)" \
" Shift #" "Move focused window to specified workspace 0-9" "(i3)" \
" Shift #" "Move focused window to specified workspace 0-9" "(i3)" \
" Ctrl l" "Move current workspace to monitor on the right" "(i3)" \
" Ctrl h" "Move current workspace to monitor on the left" "(i3)" \
" Shift c" "Reload the i3 configuration file" "(i3)" \
" Shift r" "Restart i3 inplace" "(i3)" \
" Shift e" "Logout" "(i3)" \
" r" "Toggle resizing mode on current window" "(i3)" \
