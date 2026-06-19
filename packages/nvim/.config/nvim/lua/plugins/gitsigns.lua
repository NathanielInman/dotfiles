return {
  -- gitsigns was previously pulled in transitively by NvChad; declare it
  -- standalone now. Powers the git statusline segment and the gitsigns menu.
  {
    'lewis6991/gitsigns.nvim',
    event = { 'BufReadPre', 'BufNewFile' },
    opts = {},
  },
}
