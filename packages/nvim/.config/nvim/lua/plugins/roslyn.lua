return {
  -- C#: roslyn.nvim drives Microsoft's Roslyn language server (replaces the
  -- slower, older omnisharp). The `roslyn` server is installed via mason (see
  -- the Crashdummyy registry added in mason.lua). Requires Neovim >= 0.12.
  {
    'seblyng/roslyn.nvim',
    ft = { 'cs' },
    config = function()
      vim.lsp.config('roslyn', {
        capabilities = require('configs.lsp').capabilities,
      })
      require('roslyn').setup {}
    end,
  },
}
