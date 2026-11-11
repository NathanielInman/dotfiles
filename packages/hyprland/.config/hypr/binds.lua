local mod = "SUPER"

-- Every bind has a description, which Switchyard's Shelf (Super+/) lists
-- and filters on. Under the Lua config `hyprctl binds` can't show what a
-- bind runs, only "HL.Dispatcher(exec_cmd) 33", so the description is the
-- only readable name a bind gets. Words after the "·" are search tags:
-- what you'd type to find the bind when you've forgotten its keys.

-- Applications
hl.bind(mod .. " + Return", hl.dsp.exec_cmd("kitty"), { description = "Terminal · kitty shell console" })
hl.bind(mod .. " + T", hl.dsp.exec_cmd("kitty --class float-term"), { description = "Floating terminal · kitty shell console popup" })
hl.bind(mod .. " + D", hl.dsp.exec_cmd("walker"), { description = "App launcher · walker run open start apps" })
-- Switchyard board, centered on the focused monitor (the waybar signal opens it above itself)
hl.bind(mod .. " + Y", hl.dsp.exec_cmd("~/.local/bin/yard toggle --center"), { description = "Switchyard board · tasks builds deploys" })
hl.bind(mod .. " + P", hl.dsp.exec_cmd("~/.config/hypr/scripts/screenshot.sh"), { description = "Screenshot a region · capture snip print screen" })
hl.bind(mod .. " + CTRL + P", hl.dsp.exec_cmd("grim ~/Pictures/Screenshots/fullscreen-$(date +%Y%m%d-%H%M%S).png"), { description = "Screenshot the whole screen · capture print fullscreen" })
hl.bind(mod .. " + E", hl.dsp.exec_cmd("thunar"), { description = "File manager · thunar folders explorer browse" })
hl.bind(mod .. " + V", hl.dsp.exec_cmd("walker --provider files"), { description = "Find files · walker search open" })
hl.bind(mod .. " + C", hl.dsp.exec_cmd("galculator"), { description = "Calculator · galculator math" })
-- Clipboard history: elephant records it, walker shows it with the launcher's theme
hl.bind(mod .. " + ALT + V", hl.dsp.exec_cmd("walker --provider clipboard"), { description = "Clipboard history · paste copy yank clip" })
hl.bind(mod .. " + N", hl.dsp.exec_cmd("swaync-client -t -sw"), { description = "Notification history · notifications alerts swaync" })
hl.bind(mod .. " + Escape", hl.dsp.exec_cmd("hyprlock --immediate-render"), { description = "Lock screen · hyprlock away" })
-- Key bind cheat sheet: Switchyard's shelf lists every bind (shelf.binds)
hl.bind(mod .. " + Slash", hl.dsp.exec_cmd("~/.local/bin/yard toggle --center"), { description = "Key bind cheat sheet · hotkeys shortcuts keys help" })
hl.bind("ALT + Tab", hl.dsp.exec_cmd("walker --provider windows"), { description = "Switch windows · window list alt-tab" })
hl.bind("code:191", hl.dsp.exec_cmd("voxtype record start"), { description = "Dictation, hold to talk · voice speech voxtype transcribe" })
hl.bind("code:191", hl.dsp.exec_cmd("voxtype record stop"), { release = true, description = "Dictation, release to type · voice speech voxtype transcribe" })
hl.bind("code:192", hl.dsp.exec_cmd("~/.config/waybar/scripts/meeting-record.sh toggle"), { description = "Record a meeting · audio transcribe notes" })

-- Window management
hl.bind(mod .. " + Q", hl.dsp.window.close(), { description = "Close window · quit" })              -- graceful close (everyday)
hl.bind(mod .. " + SHIFT + Q", hl.dsp.window.kill(), { description = "Force kill window · quit hung frozen" }) -- force kill (e.g. neovide with unsaved buffers)
hl.bind(mod .. " + F", hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }), { description = "Fullscreen · maximize" })
hl.bind(mod .. " + SHIFT + Space", hl.dsp.window.float({ action = "toggle" }), { description = "Float or tile window · floating" })

-- Focus movement
hl.bind(mod .. " + H", hl.dsp.layout("focus l"), { description = "Focus column left · navigate" })
hl.bind(mod .. " + J", hl.dsp.focus({ direction = "d" }), { description = "Focus window below · navigate" })
hl.bind(mod .. " + K", hl.dsp.focus({ direction = "u" }), { description = "Focus window above · navigate" })
hl.bind(mod .. " + L", hl.dsp.layout("focus r"), { description = "Focus column right · navigate" })

-- Window movement
hl.bind(mod .. " + SHIFT + H", hl.dsp.window.move({ direction = "l" }), { description = "Move window left · swap" })
hl.bind(mod .. " + SHIFT + J", hl.dsp.window.move({ direction = "d" }), { description = "Move window down · swap" })
hl.bind(mod .. " + SHIFT + K", hl.dsp.window.move({ direction = "u" }), { description = "Move window up · swap" })
hl.bind(mod .. " + SHIFT + L", hl.dsp.window.move({ direction = "r" }), { description = "Move window right · swap" })

-- Switch workspaces / move window to workspace with mod / mod+SHIFT + [0-9]
for i = 1, 10 do
  local key = i % 10 -- 10 maps to key 0
  hl.bind(mod .. " + " .. key, hl.dsp.focus({ workspace = i }), { description = "Go to workspace " .. i .. " · switch desktop" })
  hl.bind(mod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i, follow = true }), { description = "Move window to workspace " .. i .. " · send desktop" })
end

-- Move workspace to monitor
hl.bind(mod .. " + ALT + bracketright", hl.dsp.workspace.move({ monitor = "+1" }), { description = "Move workspace to next monitor · screen display" })
hl.bind(mod .. " + ALT + bracketleft", hl.dsp.workspace.move({ monitor = "-1" }), { description = "Move workspace to previous monitor · screen display" })

-- Scrolling layout column management
hl.bind(mod .. " + CTRL + L", hl.dsp.layout("move +col"), { description = "Shift column right · reorder tape" })   -- shift column right in the tape
hl.bind(mod .. " + CTRL + H", hl.dsp.layout("move -col"), { description = "Shift column left · reorder tape" })    -- shift column left in the tape
hl.bind(mod .. " + ALT + L", hl.dsp.layout("colresize +conf"), { description = "Widen column · resize grow bigger" })     -- cycle column wider through preset widths
hl.bind(mod .. " + ALT + H", hl.dsp.layout("colresize -conf"), { description = "Narrow column · resize shrink smaller" }) -- cycle column narrower through preset widths
hl.bind(mod .. " + CTRL + F", hl.dsp.layout("fit active"), { description = "Fit column to screen · resize" })
hl.bind(mod .. " + ALT + F", hl.dsp.layout("fit all"), { description = "Fit all columns to screen · resize overview" })
hl.bind(mod .. " + Equal", hl.dsp.layout("colresize +conf"), { description = "Widen column · resize grow bigger" })

-- Waybar toggle
hl.bind(mod .. " + B", hl.dsp.exec_cmd("killall -SIGUSR1 waybar"), { description = "Show or hide the bar · waybar panel" })

-- Media keys
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("swayosd-client --output-volume +5"), { repeating = true, description = "Volume up · sound audio louder" })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("swayosd-client --output-volume -5"), { repeating = true, description = "Volume down · sound audio quieter" })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("swayosd-client --output-volume mute-toggle"), { description = "Mute · sound audio volume" })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("swayosd-client --input-volume mute-toggle"), { description = "Mute microphone · mic input" })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("~/.local/bin/tannoy play-pause"), { description = "Play or pause · music media tannoy" })
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("~/.local/bin/tannoy next"), { description = "Next track · music media skip" })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("~/.local/bin/tannoy previous"), { description = "Previous track · music media" })

-- Utilities
hl.bind(mod .. " + R", hl.dsp.exec_cmd("~/.config/waybar/scripts/screen-record.sh"), { description = "Record screen · video capture screencast" })
hl.bind(mod .. " + I", hl.dsp.exec_cmd("hyprpicker -a -n"), { description = "Pick a color · eyedropper colour hex" })
hl.bind(mod .. " + O", hl.dsp.exec_cmd("walker --provider symbols"), { description = "Symbols and emoji · unicode glyph" })

-- Mouse bindings
hl.bind(mod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true, description = "Drag window · move mouse" })
hl.bind(mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true, description = "Resize window · mouse" })
