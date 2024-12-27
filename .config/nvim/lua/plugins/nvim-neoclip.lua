return {
  -- maintain a history of all yanks but set the default register to the global
  -- clipboard so we can easily swap in-and-out of neovim with other apps
  {
    'ackslD/nvim-neoclip.lua',
    config = function()
      require('neoclip').setup {
        default_register = '"',
      }
    end,
  },
}
