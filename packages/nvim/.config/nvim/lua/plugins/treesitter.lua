return {
  -- mostly simple webdev language support
  {
    'nvim-treesitter/nvim-treesitter',
    opts = {
      ensure_installed = {
        'bash',
        'css',
        'csv',
        'dockerfile',
        'go',
        'gomod',
        'gosum',
        'gowork',
        'html',
        'javascript',
        'lua',
        'elixir',
        'vim',
        'markdown',
        'markdown_inline',
        'regex',
        'rust',
        'scss',
        'typescript',
        'vue',
        'yaml',
      },
    },
  },
}
