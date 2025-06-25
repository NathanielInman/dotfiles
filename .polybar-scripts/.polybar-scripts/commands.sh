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
    --column=Command: \
    --column=Description: \
    --timeout-indicator=bottom \
"ESC" "close this app" \
"scc" "count lines of code in repo per language" \
"tokei" "count lines of code per language in repo" \
"onefetch" "gets generic repo information like work per author" \
"cronie" "cron service managed by the cli" \
"okular" "pdf, epub, cbr, cbz reader" \
"lsusb" "list current usb port devices meta info" \
"peek" "gif and mp4 recorder" \
"duf" "better alternative of df (disk free)" \
"didyoumean" "spell-checking app for terminal" \
"translate-shell" "translation app for terminal" \
"udict" "urban dictionary for terminal" \
"sdcv" "dictionary for the terminal" \
"xsv" "cli tool for splitting/joining/analyzing csv files" \
"dog" "dns lookup cli info tool" \
"neofetch" "basic computer information tool splash" \
"inxi" "system information tool like HWiNFO for cli" \
"xfd" "font dictionary gui tool that lists all glyphs" \
"ncdu" "ncurses disk usage analyzer like df (disk free)"
"glow" "markdown viewer for the terminal"
"glances" "alternative to top command" \
"gping" "ping multiple targets at the same time for comparison" \
"pueue" "shell execution queue tool" \
"feh" "image viewer tool" \
"bandwhich" "bandwidth utilization monitor" \
"vfox" "aternative to asdf that manages prog lang tools" \
