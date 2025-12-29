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
    },
    ft = { 'markdown', 'norg', 'rmd', 'org', 'vimwiki', 'Avante' },
    config = function(_, opts)
      require('render-markdown').setup(opts)
    end,
  },
}
