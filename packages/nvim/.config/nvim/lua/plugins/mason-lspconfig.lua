return {
  -- make life really easy with :LspInstall
  {
    'williamboman/mason-lspconfig.nvim',
    event = 'VeryLazy',
    config = function()
      require('mason-lspconfig').setup {
        ensure_installed = { 'gopls', 'html', 'cssls', 'rust_analyzer', 'ts_ls', 'volar', 'lua_ls', 'markdown-oxide' },
      }
    end,
  },
}
