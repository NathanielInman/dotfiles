-- ╔══════════════════════════════════════════════════════════════╗
-- ║  Hyprland Configuration (Lua, Hyprland 0.55+)              ║
-- ╚══════════════════════════════════════════════════════════════╝
-- Split into modules; each require() runs in its own protected scope, so an
-- error in one file does not stop the others. The Nord palette is shared via
-- require("nord"). API reference: /usr/share/hypr/stubs/hl.meta.lua

require("env")
require("monitors")
require("options")
require("rules")
require("binds")
require("autostart")
