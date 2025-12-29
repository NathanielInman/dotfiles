return {
  -- this helps maintain sessions per folder
  {
    'rmagatti/auto-session',
    lazy = false,
    keys = {
      -- Will use Telescope if installed or a vim.ui.select picker otherwise
      { '<leader>ws', '<cmd>AutoSession save<CR>', desc = 'Save session' },
      { '<leader>wf', '<cmd>AutoSession search<CR>', desc = 'Session find' },
      { '<leader>wd', '<cmd>AutoSession delete<CR>', desc = 'Session delete' },
      { '<leader>wl', '<cmd>SessionRestore<CR>', desc = 'Session load' },
      { '<leader>wt', '<cmd>SessionToggleAutoSave<CR>', desc = 'Toggle autosave' },
    },
    config = function()
      require('auto-session').setup {
        log_level = 'error',
      }
    end,
  },
}
