return {
  -- nvim-autopairs was previously pulled in transitively by NvChad; declare it
  -- standalone now. blink.cmp handles function-call brackets itself.
  {
    'windwp/nvim-autopairs',
    event = 'InsertEnter',
    opts = {},
  },
}
