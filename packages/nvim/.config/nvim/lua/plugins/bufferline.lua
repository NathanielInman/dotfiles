return {
  -- bufferline replaces NvChad's tabufline (buffer tabs).
  -- Navigated with <leader>bl / <leader>bh (see mappings.lua).
  {
    'akinsho/bufferline.nvim',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    event = 'VeryLazy',
    opts = function()
      return {
        options = {
          always_show_bufferline = true, -- was tabufline lazyload = false
          diagnostics = 'nvim_lsp',
          offsets = {
            { filetype = 'NvimTree', text = 'File Explorer', highlight = 'Directory', separator = true },
          },
        },
        highlights = require('catppuccin.groups.integrations.bufferline').get(),
      }
    end,
  },
}
