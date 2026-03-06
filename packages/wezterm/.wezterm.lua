local wezterm = require 'wezterm'
local config = wezterm.config_builder()
local act = wezterm.action

config.font = wezterm.font 'PragmataPro Liga'
config.font_size = 16
config.color_scheme = 'nord'
config.tab_bar_at_bottom = true
config.use_fancy_tab_bar = false
config.hide_tab_bar_if_only_one_tab = true
config.keys = {
  {
    key = 'RightArrow',
    mods = 'CTRL|SHIFT',
    action = wezterm.action.ActivateTabRelative(1)
  },
  {
    key = 'LeftArrow',
    mods = 'CTRL|SHIFT',
    action = wezterm.action.ActivateTabRelative(-1)
  }
}
config.colors = {
  tab_bar = {
    background = '#3b4252',
    active_tab = {
      bg_color = '#4c566a',
      fg_color = '#d8dee9',
      -- Options: Half, Normal, Bold
      -- Default: Normal
      intensity = 'Bold',
      -- Options: None, Single, Double
      -- Default: None
      underline = 'None',
      italic = false,
      strikethrough = false,
    },
    inactive_tab = {
      bg_color = '#2e3440',
      fg_color = '#81a1c1',
    },
    inactive_tab_hover = {
      bg_color = '#2e3440',
      fg_color = '#e5e9f0',
    },
    new_tab = {
      bg_color = '#2e3440',
      fg_color = '#81a1c1',
    },
    new_tab_hover = {
      bg_color = '#2e3440',
      fg_color = '#e5e9f0',
    },
  },
}

return config
