return {
  -- this formats the code on save, very minimal - mostly line length
  {
    'stevearc/conform.nvim',
    event = 'BufWritePre',
    opts = {
      formatters_by_ft = {
        lua = { 'stylua' },
        javascript = { 'prettier' },
        typescript = { 'prettier' },
        markdown = { 'prettier' },
        yaml = { 'prettier' },
        css = { 'prettier' },
        scss = { 'prettier' },
        html = { 'prettier' },
        json = { 'jq' },
        vue = { 'prettier' },
      },
      formatters = {
        prettier = {
          prepend_args = { '--print-width', '80', '--bracket-same-line', 'false', '--single-attribute-per-line', '--tab-width', '2' },
        },
      },
      format_on_save = {
        timeout_ms = 1000,
        lsp_fallback = true,
      },
    },
  },
}
