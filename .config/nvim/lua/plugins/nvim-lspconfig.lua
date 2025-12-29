return {
  -- bundled configs to ease lsp
  {
    'neovim/nvim-lspconfig',
    config = function()
      local nvlsp = require 'nvchad.configs.lspconfig'
      local map = vim.keymap.set

      -- load defaults i.e lua_lsp
      nvlsp.defaults()
      nvlsp.on_attach = function(_, bufnr)
        local function opts(desc)
          return { buffer = bufnr, desc = 'LSP ' .. desc }
        end

        map('n', 'gD', vim.lsp.buf.declaration, opts 'Go to declaration')
        map('n', 'gd', vim.lsp.buf.definition, opts 'Go to definition')
        map('n', 'gi', vim.lsp.buf.implementation, opts 'Go to implementation')
        map('n', 'gs', vim.lsp.buf.signature_help, opts 'Go to signature help')
        map('n', 'gr', vim.lsp.buf.references, opts 'Show references')
        map('n', '<leader>D', vim.lsp.buf.type_definition, opts 'Go to type definition')
        map('n', '<leader>wa', vim.lsp.buf.add_workspace_folder, opts 'Add workspace folder')
        map('n', '<leader>wr', vim.lsp.buf.remove_workspace_folder, opts 'Remove workspace folder')
        map('n', '<leader>ra', require 'nvchad.lsp.renamer', opts 'NvRenamer')
        map({ 'n', 'v' }, '<leader>ca', vim.lsp.buf.code_action, opts 'Code action')
      end
      vim.lsp.config('html', {
        on_attach = nvlsp.on_attach,
        on_init = nvlsp.on_init,
        capabilities = require('blink.cmp').get_lsp_capabilities(nvlsp.capabilities),
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
        on_attach = nvlsp.on_attach,
        on_init = nvlsp.on_init,
        capabilities = require('blink.cmp').get_lsp_capabilities(nvlsp.capabilities),
        init_options = {
          provideFormatter = true,
        },
        settings = {
          css = { validate = true },
          less = { validate = true },
          scss = { validate = true },
        },
      })
      vim.lsp.config('ts_ls', {
        on_attach = nvlsp.on_attach,
        on_init = nvlsp.on_init,
        capabilities = require('blink.cmp').get_lsp_capabilities(nvlsp.capabilities),
      })
      vim.lsp.config('volar', {
        on_attach = nvlsp.on_attach,
        on_init = nvlsp.on_init,
        capabilities = require('blink.cmp').get_lsp_capabilities(nvlsp.capabilities),
        init_options = {
          vue = {
            hybridMode = false,
          },
        },
      })
      vim.lsp.config('markdown_oxide', {
        on_attach = nvlsp.on_attach,
        on_init = nvlsp.on_init,
        capabilities = require('blink.cmp').get_lsp_capabilities(nvlsp.capabilities),
      })
    end,
  },
}
