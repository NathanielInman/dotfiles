return {
  -- make markdown look beautiful
  {
    'MeanderingProgrammer/render-markdown.nvim',
    dependencies = {
      'nvim-treesitter/nvim-treesitter',
      'nvim-tree/nvim-web-devicons',
    },
    opts = {
      latex = {
        enabled = false,
      },
      -- keep the cursor line rendered in normal mode; raw text only in insert
      anti_conceal = {
        enabled = false,
      },
    },
    ft = { 'markdown', 'norg', 'rmd', 'org', 'vimwiki', 'Avante' },
    config = function(_, opts)
      require('render-markdown').setup(opts)
    end,
  },
}
