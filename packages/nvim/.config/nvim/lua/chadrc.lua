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
    statusline = {
      modules = {
        -- override lsp to use get_clients with bufnr filter
        -- instead of deprecated client.attached_buffers
        lsp = function()
          local clients = vim.lsp.get_clients { bufnr = vim.api.nvim_win_get_buf(vim.g.statusline_winid or 0) }
          if #clients > 0 then
            return (vim.o.columns > 100 and "%#St_Lsp#   LSP ~ " .. clients[1].name .. " ") or "%#St_Lsp#   LSP "
          end
          return ""
        end,
      },
    },
  },
}
