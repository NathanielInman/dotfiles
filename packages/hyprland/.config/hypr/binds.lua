local mod = "SUPER"

-- Applications
hl.bind(mod .. " + Return", hl.dsp.exec_cmd("kitty"))
hl.bind(mod .. " + T", hl.dsp.exec_cmd("kitty --class float-term"))
hl.bind(mod .. " + D", hl.dsp.exec_cmd("walker"))
hl.bind(mod .. " + P", hl.dsp.exec_cmd("~/.config/hypr/scripts/screenshot.sh"))
hl.bind(mod .. " + CTRL + P", hl.dsp.exec_cmd("grim ~/Pictures/Screenshots/fullscreen-$(date +%Y%m%d-%H%M%S).png"))
hl.bind(mod .. " + E", hl.dsp.exec_cmd("thunar"))
hl.bind(mod .. " + V", hl.dsp.exec_cmd("walker --provider files"))
hl.bind(mod .. " + C", hl.dsp.exec_cmd("galculator"))
hl.bind(mod .. " + ALT + V", hl.dsp.exec_cmd("copyq toggle"))
hl.bind(mod .. " + N", hl.dsp.exec_cmd("swaync-client -t -sw"))
hl.bind(mod .. " + Escape", hl.dsp.exec_cmd("hyprlock --immediate-render"))
hl.bind(mod .. " + Slash", hl.dsp.exec_cmd("~/.config/waybar/scripts/hotkeys.sh"))
hl.bind("ALT + Tab", hl.dsp.exec_cmd("walker --provider windows"))
hl.bind("code:191", hl.dsp.exec_cmd("voxtype record start"))
hl.bind("code:191", hl.dsp.exec_cmd("voxtype record stop"), { release = true })
hl.bind("code:192", hl.dsp.exec_cmd("~/.config/waybar/scripts/meeting-record.sh toggle"))

-- Window management
hl.bind(mod .. " + Q", hl.dsp.window.close())        -- graceful close (everyday)
hl.bind(mod .. " + SHIFT + Q", hl.dsp.window.kill()) -- force kill (e.g. neovide with unsaved buffers)
hl.bind(mod .. " + F", hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }))
hl.bind(mod .. " + SHIFT + Space", hl.dsp.window.float({ action = "toggle" }))

-- Focus movement
hl.bind(mod .. " + H", hl.dsp.layout("focus l"))
hl.bind(mod .. " + J", hl.dsp.focus({ direction = "d" }))
hl.bind(mod .. " + K", hl.dsp.focus({ direction = "u" }))
hl.bind(mod .. " + L", hl.dsp.layout("focus r"))

-- Window movement
hl.bind(mod .. " + SHIFT + H", hl.dsp.window.move({ direction = "l" }))
hl.bind(mod .. " + SHIFT + J", hl.dsp.window.move({ direction = "d" }))
hl.bind(mod .. " + SHIFT + K", hl.dsp.window.move({ direction = "u" }))
hl.bind(mod .. " + SHIFT + L", hl.dsp.window.move({ direction = "r" }))

-- Switch workspaces / move window to workspace with mod / mod+SHIFT + [0-9]
for i = 1, 10 do
  local key = i % 10 -- 10 maps to key 0
  hl.bind(mod .. " + " .. key, hl.dsp.focus({ workspace = i }))
  hl.bind(mod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i, follow = true }))
end

-- Move workspace to monitor
hl.bind(mod .. " + ALT + bracketright", hl.dsp.workspace.move({ monitor = "+1" }))
hl.bind(mod .. " + ALT + bracketleft", hl.dsp.workspace.move({ monitor = "-1" }))

-- Scrolling layout column management
hl.bind(mod .. " + CTRL + L", hl.dsp.layout("move +col"))      -- shift column right in the tape
hl.bind(mod .. " + CTRL + H", hl.dsp.layout("move -col"))      -- shift column left in the tape
hl.bind(mod .. " + ALT + L", hl.dsp.layout("colresize +conf")) -- cycle column wider through preset widths
hl.bind(mod .. " + ALT + H", hl.dsp.layout("colresize -conf")) -- cycle column narrower through preset widths
hl.bind(mod .. " + CTRL + F", hl.dsp.layout("fit active"))
hl.bind(mod .. " + ALT + F", hl.dsp.layout("fit all"))
hl.bind(mod .. " + Equal", hl.dsp.layout("colresize +conf"))

-- Waybar toggle
hl.bind(mod .. " + B", hl.dsp.exec_cmd("killall -SIGUSR1 waybar"))

-- Media keys
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("swayosd-client --output-volume +5"), { repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("swayosd-client --output-volume -5"), { repeating = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("swayosd-client --output-volume mute-toggle"))
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("swayosd-client --input-volume mute-toggle"))
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"))
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"))
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"))

-- Utilities
hl.bind(mod .. " + R", hl.dsp.exec_cmd("~/.config/waybar/scripts/screen-record.sh"))
hl.bind(mod .. " + I", hl.dsp.exec_cmd("hyprpicker -a -n"))
hl.bind(mod .. " + O", hl.dsp.exec_cmd("walker --provider symbols"))

-- Mouse bindings
hl.bind(mod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })
