return {
  {
    'nfrid/due.nvim',
    event = 'UIEnter',
    config = function()
      require('due_nvim').setup {
        pattern_start = '[TODO][',
        pattern_end = ']',
      }
    end,
  },
}
