local plugins = {
  {
    "ackslD/nvim-neoclip.lua",
    config = function()
      require("neoclip").setup {
        default_register = '"'
      }
    end
  },
  {
    "folke/zen-mode.nvim",
    cmd = 'ZenMode',
    config = function()
      require("zen-mode").setup {
        window = {
          width = 0.5
        },
        on_open = function()
          vim.opt.guifont = { 'PragmataPro', ':h18' }
        end,
        on_close = function()
          vim.opt.guifont = { 'PragmataPro', ':h14' }
        end
      }
    end
  },
  {
    "folke/which-key.nvim",
    disable = false
  },
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = {
        'html',
        'markdown',
        'yaml',
        'lua',
        'javascript',
        'bash',
        'css',
        'go',
        'rust',
        'scss',
        'vue'
      }
    }
  },
  {
    "nvim-tree/nvim-tree.lua",
    config = function()
      require("nvim-tree").setup {
        respect_buf_cwd = true,
        update_focused_file = {
          enable = true,
          update_root = true
        },
        view = {
          width = 50
        },
        renderer = {
          highlight_git = true
        },
        actions = {
          open_file = {
            quit_on_open = true
          }
        },
        filters = {
          git_ignored = false
        }
      }
    end
  }
}

return plugins
