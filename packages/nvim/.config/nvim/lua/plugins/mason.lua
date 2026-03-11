return {
  -- lets us install styling and linting tools to get us insight
  {
    'williamboman/mason.nvim',
    cmd = { 'Mason', 'MasonInstall', 'MasonUpdate' },
    event = 'VeryLazy',
    opts = {
      PATH = 'prepend',
    },
    config = function(_, opts)
      dofile(vim.g.base46_cache .. 'mason')
      require('mason').setup(opts)

      local ensure_installed = {
        'biome', -- used by nvim-lint, conform
        'eslint_d', -- used by nvim-lint
        'gofumpt', -- used by conform
        'goimports', -- used by conform
        'golangci-lint', -- used by nvim-lint
        'gopls', -- used by lspconfig
        'lua-language-server', -- used by conform, lspconfig
        'rust-analyzer', -- used by lspconfig
        'prettier', -- used by conform
        'typescript-language-server', -- used by conform, lspconfig
        'vue-language-server', -- used by conform
        'markdown_oxide', -- used for blink
      }

      local mr = require 'mason-registry'
      mr.refresh(function()
        for _, tool in ipairs(ensure_installed) do
          local ok, p = pcall(mr.get_package, tool)
          if ok and not p:is_installed() then
            p:install()
          end
        end
      end)
    end,
  },
}
