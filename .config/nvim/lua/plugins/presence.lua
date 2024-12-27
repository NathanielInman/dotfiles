return {
  {
    'andweeb/presence.nvim',
    event = 'UIEnter',
    config = function()
      require('presence').setup {}
    end,
  },
}
