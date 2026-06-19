return {
  -- lets us install styling and linting tools to get us insight
  {
    'williamboman/mason.nvim',
    cmd = { 'Mason', 'MasonInstall', 'MasonUpdate' },
    event = 'VeryLazy',
    opts = {
      PATH = 'prepend',
      -- Crashdummyy registry provides the `roslyn` C# server (roslyn.nvim)
      registries = {
        'github:mason-org/mason-registry',
        'github:Crashdummyy/mason-registry',
      },
    },
    config = function(_, opts)
      require('mason').setup(opts)

      local ensure_installed = {
        'biome', -- used by nvim-lint, conform
        'eslint_d', -- used by nvim-lint
        'gofumpt', -- used by conform
        'goimports', -- used by conform
        'golangci-lint', -- used by nvim-lint
        'gopls', -- used by lspconfig
        'lua-language-server', -- used by conform, lspconfig
        'roslyn', -- C# LSP (roslyn.nvim)
        'csharpier', -- C# formatter (conform)
        'jdtls', -- Java LSP (nvim-jdtls)
        'google-java-format', -- Java formatter (conform)
        'lexical', -- Elixir LSP (lspconfig)
        'rust-analyzer', -- used by rustaceanvim
        'prettier', -- used by conform
        'typescript-language-server', -- used by conform, lspconfig
        'vue-language-server', -- used by conform
        -- markdown_oxide LSP is installed via mason-lspconfig (server-name mapping)
        'markdownlint', -- markdown linter (nvim-lint)
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
