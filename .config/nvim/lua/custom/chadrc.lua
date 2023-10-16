local M = {}

M.ui = {
  theme = "onenord",
  theme_toggle = { 'onenord', 'chadtain' },
  hl_override = {
    NnnNormal = { fg = '#ff0000'},
    NnnNormalNC = { fg = '#00ff00'},
    NnnBorder = { fg = '#00ffff'}
  },
  tabufline = {
    enabled = false
  },
  statusline = {
    overriden_modules = function(modules)
      table.remove(modules, 2)
      table.insert(
        modules,
        2,
        (function()
          local function stbufnr()
            return vim.api.nvim_win_get_buf(vim.g.statusline_winid)
          end
          local icon = "  "
          local path = vim.api.nvim_buf_get_name(stbufnr())
          local name = (path == "" and "Empty ") or path:match "^.+[/\\](.+)$"

          if name ~= "Empty " then
            local devicons_present, devicons = pcall(require, "nvim-web-devicons")

            if devicons_present then
              local ft_icon = devicons.get_icon(name)
              icon = (ft_icon ~= nil and " " .. ft_icon) or ""
            end

            name = " " .. name .. " "
          end

          return "%#St_file_info#" .. icon .. name .. "%#St_file_sep#" .. ''
        end)()
      )
      table.remove(modules, 9)
      table.insert(
        modules,
        9,
        (function()
          local dir_icon = '%#St_cwd_icon#' .. ' '
          local dir_name = '%#St_cwd_text#' .. ' ' .. vim.fn.fnamemodify(vim.fn.getcwd(), ':t') .. ' '
          return (vim.o.columns > 85 and ('%#St_cwd_sep#' .. '' .. dir_icon .. dir_name)) or ''
        end)()
      )
    end
  }
}

M.plugins = "custom.plugins"

M.mappings = require('custom.mappings')

return M
