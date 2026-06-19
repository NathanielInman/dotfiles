return {
  -- LSP server configs. Shared on_attach/capabilities/diagnostics live in
  -- lua/configs/lsp.lua. C#, Rust and Java are configured by their own dedicated
  -- plugin specs (roslyn.lua, rustaceanvim.lua, jdtls.lua) and are intentionally
  -- absent here.
  {
    'neovim/nvim-lspconfig',
    event = { 'BufReadPre', 'BufNewFile' },
    dependencies = { 'saghen/blink.cmp' },
    config = function()
      local lsp = require 'configs.lsp'
      lsp.setup() -- diagnostics, LspAttach keymaps, global '*' defaults, lua_ls

      vim.lsp.config('html', {
        init_options = {
          configurationSection = { 'html', 'css', 'javascript' },
          embeddedLanguages = {
            css = true,
            javascript = true,
          },
          provideFormatter = true,
        },
      })
      vim.lsp.config('cssls', {
        init_options = {
          provideFormatter = true,
        },
        settings = {
          css = { validate = true },
          less = { validate = true },
          scss = { validate = true },
        },
      })
      vim.lsp.config('ts_ls', {})
      vim.lsp.config('vue_ls', {
        init_options = {
          vue = {
            hybridMode = false,
          },
        },
      })
      vim.lsp.config('gopls', {
        settings = {
          gopls = {
            analyses = {
              unusedparams = true,
              shadow = true,
            },
            staticcheck = true,
            gofumpt = true,
          },
        },
      })
      vim.lsp.config('markdown_oxide', {})
      vim.lsp.config('lexical', {}) -- elixir

      vim.lsp.enable { 'html', 'cssls', 'ts_ls', 'vue_ls', 'gopls', 'markdown_oxide', 'lexical' }
    end,
  },
}
