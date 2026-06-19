return {
  -- Rust: rustaceanvim configures rust-analyzer itself (do NOT also set it up via
  -- nvim-lspconfig). Adds runnables, code actions, macro expansion, etc.
  {
    'mrcjkb/rustaceanvim',
    lazy = false, -- it is a filetype plugin; it wires itself up
    init = function()
      vim.g.rustaceanvim = {
        server = {
          capabilities = require('configs.lsp').capabilities,
          default_settings = {
            ['rust-analyzer'] = {
              check = {
                command = 'clippy',
              },
            },
          },
        },
      }
    end,
  },
}
