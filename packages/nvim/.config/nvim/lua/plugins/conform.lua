return {
  -- this formats the code on save, very minimal - mostly line length
  {
    'stevearc/conform.nvim',
    event = 'BufWritePre',
    opts = {
      formatters_by_ft = {
        go = { 'goimports', 'gofumpt' },
        lua = { 'stylua' },
        javascript = { 'biome' },
        typescript = { 'biome' },
        javascriptreact = { 'biome' },
        typescriptreact = { 'biome' },
        css = { 'biome' },
        json = { 'biome' },
        vue = { 'biome' },
        markdown = { 'prettier' },
        yaml = { 'prettier' },
        scss = { 'prettier' },
        html = { 'prettier' },
      },
      formatters = {
        biome = {
          -- use umbrella config as fallback when no local biome.json exists
          require_cwd = false,
          cwd = function()
            local root = vim.fs.root(0, { 'biome.json', 'biome.jsonc' })
            return root or vim.env.HOME .. '/.config/biome'
          end,
        },
      },
      format_on_save = {
        timeout_ms = 1000,
        lsp_fallback = true,
      },
    },
  },
}
