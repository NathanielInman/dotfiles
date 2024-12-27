return {
  -- easymotion jumping
  {
    'folke/flash.nvim',
    opts = {
      jump = { nohlsearch = true },
      prompt = {
        win_config = { row = -2 },
      },
      modes = {
        -- Use flash for ? and /
        search = { enabled = true },
      },
    },
    keys = {
      {
        '<leader><leader>',
        mode = { 'n', 'x', 'o' },
        function()
          require('flash').jump()
        end,
        desc = 'Flash',
      },
    },
  },
}
