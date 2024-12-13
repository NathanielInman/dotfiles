-- load defaults i.e lua_lsp
require('nvchad.configs.lspconfig').defaults()

local lspconfig = require 'lspconfig'
local nvlsp = require 'nvchad.configs.lspconfig'

lspconfig.html.setup {
  on_attach = nvlsp.on_attach,
  on_init = nvlsp.on_init,
  capabilities = nvlsp.capabilities,
  init_options = {
    configurationSection = { 'html', 'css', 'javascript' },
    embeddedLanguages = {
      css = true,
      javascript = true,
    },
    provideFormatter = true,
  },
}
lspconfig.cssls.setup {
  on_attach = nvlsp.on_attach,
  on_init = nvlsp.on_init,
  capabilities = nvlsp.capabilities,
  init_options = {
    provideFormatter = true,
  },
  settings = {
    css = { validate = true },
    less = { validate = true },
    scss = { validate = true },
  },
}
lspconfig.ts_ls.setup {
  on_attach = nvlsp.on_attach,
  on_init = nvlsp.on_init,
  capabilities = nvlsp.capabilities,
}
lspconfig.volar.setup {
  on_attach = nvlsp.on_attach,
  on_init = nvlsp.on_init,
  capabilities = nvlsp.capabilities,
  init_options = {
    vue = {
      hybridMode = false,
    },
  },
}
