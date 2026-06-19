return {
  -- mostly simple webdev language support
  {
    'nvim-treesitter/nvim-treesitter',
    branch = 'main',
    lazy = false,
    build = ':TSUpdate',
    config = function()
      -- main branch dropped `require('nvim-treesitter.configs').setup` and
      -- `ensure_installed`. Parsers are installed imperatively and the
      -- highlighter is started per-buffer via a FileType autocmd.
      local ensure_installed = {
        'bash',
        'c_sharp',
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
      }

      require('nvim-treesitter').install(ensure_installed)

      vim.api.nvim_create_autocmd('FileType', {
        group = vim.api.nvim_create_augroup('treesitter_start', { clear = true }),
        callback = function(args)
          local lang = vim.treesitter.language.get_lang(vim.bo[args.buf].filetype)
          if lang and pcall(vim.treesitter.language.add, lang) then
            -- start() also enables tree-sitter folds/indent where queries exist
            pcall(vim.treesitter.start, args.buf, lang)
          end
        end,
      })
    end,
  },
}
