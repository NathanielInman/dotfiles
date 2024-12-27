return {
  {
    'andweeb/presence.nvim',
    event = 'UIEnter',
    config = function()
      require('presence').setup {
        auto_update = true,
        main_image = 'file',
        debounce_timeout = 10,
        enable_line_number = false,
        buttons = true,
        show_time = true,
      }
    end,
  },
}
