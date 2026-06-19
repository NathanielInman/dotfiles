return {
  -- lualine replaces NvChad's ui statusline
  {
    'nvim-lualine/lualine.nvim',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    event = 'VeryLazy',
    opts = function()
      -- mirrors the old chadrc statusline LSP module: show the attached client,
      -- collapsed to just "LSP" on narrow windows. Uses get_clients (not the
      -- deprecated client.attached_buffers).
      local function lsp_clients()
        local clients = vim.lsp.get_clients { bufnr = 0 }
        if #clients == 0 then
          return ''
        end
        if vim.o.columns > 100 then
          return '  LSP ~ ' .. clients[1].name
        end
        return '  LSP'
      end

      return {
        options = {
          -- 'auto' derives colors from the active colorscheme, so it follows
          -- the catppuccin latte/mocha toggle automatically
          theme = 'auto',
          globalstatus = true, -- matches laststatus=3
          section_separators = { left = '', right = '' },
          component_separators = { left = '', right = '' },
        },
        sections = {
          lualine_a = { 'mode' },
          lualine_b = { 'branch', 'diff', 'diagnostics' },
          lualine_c = { { 'filename', path = 1 } },
          lualine_x = { lsp_clients, 'filetype' },
          lualine_y = { 'progress' },
          lualine_z = { 'location' },
        },
      }
    end,
  },
}
