return {
  {
    'vyfor/cord.nvim',
    lazy = false,
    build = ':Cord update',
    config = function()
      require('cord').setup {
        idle = {
          enabled = false,
        },
      }
    end,
  },
}
