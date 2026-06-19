-- Shared LSP wiring, replacing nvchad.configs.lspconfig.
-- Reused by every server spec (see lua/plugins/nvim-lspconfig.lua, roslyn.lua,
-- rustaceanvim.lua, jdtls.lua).
local M = {}
local map = vim.keymap.set

-- blink.cmp augments the default client capabilities with its completion support
M.capabilities = require('blink.cmp').get_lsp_capabilities()

M.on_attach = function(_, bufnr)
  local function opts(desc)
    return { buffer = bufnr, desc = 'LSP ' .. desc }
  end

  map('n', 'gD', vim.lsp.buf.declaration, opts 'Go to declaration')
  map('n', 'gd', vim.lsp.buf.definition, opts 'Go to definition')
  map('n', 'gi', vim.lsp.buf.implementation, opts 'Go to implementation')
  map('n', 'gs', vim.lsp.buf.signature_help, opts 'Show signature help')
  map('n', 'gr', vim.lsp.buf.references, opts 'Show references')
  map('n', '<leader>D', vim.lsp.buf.type_definition, opts 'Go to type definition')
  map('n', '<leader>wa', vim.lsp.buf.add_workspace_folder, opts 'Add workspace folder')
  map('n', '<leader>wr', vim.lsp.buf.remove_workspace_folder, opts 'Remove workspace folder')
  -- snacks.input gives this prompt its floating UI
  map('n', '<leader>ra', vim.lsp.buf.rename, opts 'Rename symbol')
  map({ 'n', 'v' }, '<leader>ca', vim.lsp.buf.code_action, opts 'Code action')
end

-- disable semantic tokens (kept from the previous nvchad behaviour)
M.on_init = function(client, _)
  if client:supports_method 'textDocument/semanticTokens' then
    client.server_capabilities.semanticTokensProvider = nil
  end
end

function M.diagnostic_config()
  local x = vim.diagnostic.severity
  vim.diagnostic.config {
    virtual_text = { prefix = '' },
    signs = { text = { [x.ERROR] = '󰅙', [x.WARN] = '', [x.INFO] = '󰋼', [x.HINT] = '󰌵' } },
    underline = true,
    float = { border = 'single' },
  }
end

-- Call once (from nvim-lspconfig's config) to install global defaults that all
-- servers inherit, the LspAttach keymaps, diagnostics, and the lua_ls server.
function M.setup()
  M.diagnostic_config()

  vim.api.nvim_create_autocmd('LspAttach', {
    group = vim.api.nvim_create_augroup('lsp_attach_keymaps', { clear = true }),
    callback = function(args)
      M.on_attach(nil, args.buf)
    end,
  })

  -- defaults applied to every server configured via vim.lsp.config
  vim.lsp.config('*', { capabilities = M.capabilities, on_init = M.on_init })

  -- lua_ls: lazydev.nvim supplies the Neovim runtime library, so keep this lean
  vim.lsp.config('lua_ls', {
    settings = {
      Lua = {
        runtime = { version = 'LuaJIT' },
        workspace = { checkThirdParty = false },
        format = { enable = false }, -- stylua via conform handles formatting
      },
    },
  })
  vim.lsp.enable 'lua_ls'
end

return M
