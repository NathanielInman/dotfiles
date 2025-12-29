return {
  base46 = {
    theme = 'onedark',
    theme_toggle = { 'onedark', 'github_light' },
    hl_override = {
      Comment = { italic = true },
      ['@comment'] = { italic = true },
    },
  },
  ui = {
    tabufline = {
      -- keep it displayed even with 1 tab
      lazyload = false,
    },
  },
}
