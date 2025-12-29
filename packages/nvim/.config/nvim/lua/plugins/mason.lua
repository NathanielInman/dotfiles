return {
  -- lets us install styling and linting tools to get us insight
  {
    'williamboman/mason.nvim',
    opts = {
      ensure_installed = {
        'eslint_d', -- used by nvim-lint
        'lua-language-server', -- used by conform, lspconfig
        'prettier', -- used by conform
        'typescript-language-server', -- used by conform, lspconfig
        'vue-language-server', -- used by conform
        'markdown_oxide', -- used for blink
      },
    },
  },
}
