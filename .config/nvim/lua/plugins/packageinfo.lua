return {
  {
    'vuki656/package-info.nvim',
    ft = 'json',
    dependencies = 'MunifTanjim/nui.nvim',
    config = function()
      require('package-info').setup {}
    end,
  },
}
