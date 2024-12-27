return {
  -- mainly the default nvimtree (neovim nerdtree) but a little bit bigger
  -- and default for showing all files nomatter what
  {
    'nvim-tree/nvim-tree.lua',
    dependencies = { 'nvim-web-devicons' },
    config = function()
      require('nvim-tree').setup {
        respect_buf_cwd = true,
        update_focused_file = {
          enable = true,
          update_root = true,
        },
        view = {
          width = 50,
        },
        renderer = {
          highlight_git = true,
        },
        actions = {
          open_file = {
            quit_on_open = true,
          },
        },
        filters = {
          git_ignored = false,
        },
      }
    end,
  },
}
