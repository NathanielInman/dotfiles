return {
  -- this helps maintain sessions per folder
  {
    'rmagatti/auto-session',
    lazy = false,
    keys = {
      -- Will use Telescope if installed or a vim.ui.select picker otherwise
      { '<leader>ws', '<cmd>AutoSession save<CR>', desc = 'Save session' },
      { '<leader>wd', '<cmd>AutoSession delete<CR>', desc = 'Session delete' },
      { '<leader>wf', '<cmd>AutoSession search<CR>', desc = 'Session load (pick)' },
      { '<leader>wl', '<cmd>AutoSession search<CR>', desc = 'Session load (pick)' },
      { '<leader>wr', '<cmd>AutoSession restore<CR>', desc = 'Session restore (cwd)' },
      { '<leader>wt', '<cmd>AutoSession toggle<CR>', desc = 'Toggle autosave' },
    },
    config = function()
      require('auto-session').setup {
        log_level = 'error',
        auto_restore_enabled = true,
        auto_save_enabled = true,
        auto_session_enable_last_session = false,
        auto_session_use_git_branch = false,
      }
    end,
  },
}
