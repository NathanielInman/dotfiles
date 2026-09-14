-- Window rules

-- Simple floating dialogs
for _, class in ipairs({
  "gnome-calendar",
  "galculator",
  "pavucontrol",
  "blueman-manager",
  "yad",
  "hyprland-share-picker",
}) do
  hl.window_rule({ name = "float-" .. class, match = { class = class }, float = true })
end

hl.window_rule({
  name  = "portal-gtk",
  match = { class = "xdg-desktop-portal-gtk" },
  float  = true,
  size   = { "(monitor_w*0.5)", "(monitor_h*0.6)" },
  center = true,
})

hl.window_rule({
  name  = "float-term",
  match = { class = "float-term" },
  float  = true,
  size   = { "(monitor_w*0.6)", "(monitor_h*0.6)" },
  center = true,
})

-- Blender's temporary File Browser window (native Wayland) always maps at
-- its 320x240 minimum under Hyprland: Blender commits before it has sent its
-- real size, so the compositor's initial configure answers with the min-size
-- hint. Upstream: https://projects.blender.org/blender/blender/issues/162315
-- Force a usable size until Blender fixes GHOST_WindowWayland.
hl.window_rule({
  name  = "blender-filebrowser",
  match = { class = "blender", title = "^(Blender File View)$" },
  float  = true,
  size   = { "(monitor_w*0.6)", "(monitor_h*0.7)" },
  center = true,
})

-- Android emulator: tiling squashes its fixed phone aspect ratio and pads the
-- leftover space with a grey background. Float both its windows (device +
-- control toolbar share class "Emulator") and center only the device window;
-- the emulator docks the toolbar to it. No size rule: let it keep phone size.
hl.window_rule({ name = "emulator-float", match = { class = "Emulator" }, float = true })
hl.window_rule({
  name  = "emulator-center",
  match = { class = "Emulator", title = "Android Emulator" },
  center = true,
})

hl.window_rule({ name = "zoom-workspace", match = { class = "zoom" }, workspace = "2" })
hl.window_rule({
  name  = "zoom-no-steal-focus",
  match = { class = "zoom", title = "zoom" },
  suppress_event = "activate",
})
hl.window_rule({ name = "slack-workspace", match = { class = "Slack" }, workspace = "2" })
hl.window_rule({ name = "discord-workspace", match = { class = "discord" }, workspace = "3" })
