return {
  -- make life really easy with :LspInstall
  {
    'williamboman/mason-lspconfig.nvim',
    config = function()
      require('mason-lspconfig').setup {
        ensure_installed = { 'html', 'cssls', 'ts_ls', 'volar', 'lua_ls', 'markdown-oxide' },
      }
    end,
  },
}
