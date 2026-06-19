return {
  -- make life really easy with :LspInstall
  {
    'williamboman/mason-lspconfig.nvim',
    event = 'VeryLazy',
    config = function()
      require('mason-lspconfig').setup {
        ensure_installed = { 'gopls', 'html', 'cssls', 'ts_ls', 'vue_ls', 'lua_ls', 'markdown_oxide' },
        -- we enable servers ourselves (nvim-lspconfig.lua + roslyn/rustaceanvim/jdtls);
        -- let mason-lspconfig auto-enable would double-configure rust/c#/java
        automatic_enable = false,
      }
    end,
  },
}
