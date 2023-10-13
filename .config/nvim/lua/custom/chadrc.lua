local M = {}

M.ui = {
  theme = "onenord",
  theme_toggle = { 'onenord', 'chadtain' },
  hl_override = {
    NnnNormal = { fg = '#ff0000'},
    NnnNormalNC = { fg = '#00ff00'},
    NnnBorder = { fg = '#00ffff'}
  },
}

M.plugins = "custom.plugins"

M.mappings = require('custom.mappings')

return M
