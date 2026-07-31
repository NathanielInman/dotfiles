local nord = require("nord")

hl.config({
  -- Scrolling layout: built into Hyprland core since 0.55 (the old
  -- hyprscrolling plugin was dropped; its plugin{} block used the now-ignored
  -- plugin:hyprscrolling namespace).
  scrolling = {
    column_width = 0.5,   -- new columns take half the monitor
    follow_focus = false, -- focus (incl. focus-follows-mouse) never auto-scrolls the viewport
    -- explicit_column_widths defaults to "0.333, 0.5, 0.667, 1.0" (used by colresize +conf/-conf)
  },

  cursor = {
    no_hardware_cursors = true,
  },

  input = {
    numlock_by_default = true,
    repeat_rate = 50,
    repeat_delay = 300,
    follow_mouse = 1,
  },

  general = {
    layout = "scrolling",
    gaps_in = 4,
    gaps_out = 4,
    border_size = 3,
    col = {
      active_border = nord.nord9,
      inactive_border = nord.nord3,
    },
  },

  misc = {
    focus_on_activate = false,
    mouse_move_enables_dpms = true,
    key_press_enables_dpms = true,
  },

  ecosystem = {
    no_donation_nag = true,
  },

  decoration = {
    rounding = 6,

    -- Blur (on by default in Hyprland) samples the transparent margins of
    -- GTK menu surfaces, producing a smeared "halo" around Slack's dropdowns
    -- (Slack runs --gtk-version=3, so its menus are native GTK). Disabled.
    blur = {
      enabled = false,
    },
  },

  group = {
    col = {
      border_active = nord.nord9,
      border_inactive = nord.nord3,
    },

    groupbar = {
      enabled = true,
      height = 18,
      font_size = 12,
      font_family = "PragmataPro Liga",
      render_titles = true,
      col = {
        active = nord.nord9,
        inactive = nord.nord3,
      },
      text_color = nord.nord4,
    },
  },

  animations = {
    enabled = true,
  },
})

hl.curve("ease", { type = "bezier", points = { { 0.25, 0.1 }, { 0.25, 1.0 } } })
hl.animation({ leaf = "windows",    enabled = true, speed = 4, bezier = "ease" })
hl.animation({ leaf = "fade",       enabled = true, speed = 4, bezier = "ease" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 4, bezier = "ease" })
