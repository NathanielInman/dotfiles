local plugins = {
  {
    'rmagatti/auto-session',
    lazy = false,
    config = function()
      require('auto-session').setup {
        log_level = 'error',
      }
    end
  },
  -- some basic overwrites to ensure the icons work properly with
  -- PragmataPro
  {
    'nvim-web-devicons',
    config = function ()
      require('nvim-web-devicons').setup {
        override_by_extension = {
          js = {
            icon = ' ',
            color = '#cbcb41',
            name = 'js'
          },
          jsx = {
            icon = ' ',
            color = '#cbcb41',
            name = 'jsx'
          },
          log = {
            icon = ' ',
            color = '#ffffff',
            name = 'log'
          },
          lua = {
            icon = ' ',
            color = '#51a0cf',
            name = 'lua'
          },
          py = {
            icon = ' ',
            color = '#ffbc03',
            name = 'py'
          },
          styl = {
            icon = ' ',
            color = '#8dc149',
            name = 'styl'
          },
          ts = {
            icon = ' ',
            color = '#519aba',
            name = 'ts'
          },
          tsx = {
            icon = ' ',
            color = '#519aba',
            name = 'tsx'
          },
          json = {
            icon = ' ',
            color = '#cbcb41',
            name = 'json'
          },
          yml = {
            icon = ' ',
            color = '#6d8086',
            name = 'yml'
          },
          vue = {
            icon = ' ',
            color = '#8dc149',
            name = 'vue'
          }
        }
      }
    end
  },
  -- bufferline has been slightly altered so it coexists easily with
  -- the nordtheme as well as PragmataPro icons
  {
    'akinsho/bufferline.nvim',
    lazy = false,
    version = '*',
    dependencies = 'nvim-tree/nvim-web-devicons',
    config = function ()
      require('bufferline').setup {
        options = {
          separator_style = 'thick',
          diagnostics = 'nvim_lsp',
          close_icon = '⮾',
          buffer_close_icon = '⮾',
          indicator = {
            style = 'underline'
          },
          offsets = {
            {
              filetype = 'NvimTree',
              text = 'File Explorer',
              text_align = 'center',
              separator = true
            }
          },
        },
        highlights = {
          fill = {
            bg = '#2a303c'
          }
        }
      }
    end
  },
  -- tui to walk through commits easily and view diffs in neovim
  {
    'neogitorg/neogit',
    dependencies = {
      'nvim-lua/plenary.nvim',
      'nvim-telescope/telescope.nvim',
      'sindrets/diffview.nvim',
      'ibhagwan/fzf-lua'
    },
    keys = {
      { "<leader>gs", "<cmd>Neogit<cr>", desc = "Toggle neogit visibility"}
    },
    config = true
  },
  -- underline similar words to that under the cursor
  {
    'rrethy/vim-illuminate',
    lazy = false
  },
  -- easymotion jumping
  {
    'smoka7/hop.nvim',
    version = '*',
    keys = {
      { '<leader><leader>', ':HopPattern<CR>', 'Start easymotion/hop pattern jumping'}
    },
    config = function()
      require('hop').setup {
        keys = 'etovxqpdygfblzhckisuran'
      }
    end
  },
  -- this allows the zooming in and out of windows with animations
  -- to help supplement native window creation
  {
    'anuvyklack/windows.nvim',
    dependencies = {
      'anuvyklack/middleclass',
      'anuvyklack/animation.nvim'
    },
    keys = {
      { '<leader>sz', ':WindowsMaximize<CR>', 'Size the current window to zoom to max' }
    },
    config = function()
      vim.o.minwidth = 10
      vim.o.winminwidth = 10
      vim.o.equalalways = false
      require('windows').setup()
    end
  },
  -- this hides the command bar on the bottom, and instead leverages neovims
  -- built-in hover panel features for a center command bar, as well as fancy
  -- notifications on the top-right instead of letting things slip through
  -- the cracks like usual with LSP and whatnot
  {
    'folke/noice.nvim',
    event = 'VeryLazy',
    dependencies = {
      'MunifTanjim/nui.nvim',
      'rcarriga/nvim-notify'
    },
    config = function()
      require('noice').setup {
        lsp = {
          hover = {
            enabled = false -- handled by nvchad
          },
          signature = {
            enabled = false -- handled by nvchad
          },
          override = {
            ['vim.lsp.util.convert_input_to_markdown_lines'] = true,
            ['vim.lsp.util.stylize_markdown'] = true,
            ['cmp.entry.get_documentation'] = true
          }
        },
        presets = {
          bottom_search = true,
          command_palette = true,
          long_message_to_split = true,
          inc_rename = false,
          lsp_doc_border = false
        }
      }
    end
  },
  -- maintain a history of all yanks but set the default register to the global
  -- clipboard so we can easily swap in-and-out of neovim with other apps
  {
    'ackslD/nvim-neoclip.lua',
    config = function()
      require('neoclip').setup {
        default_register = '"'
      }
    end
  },
  -- zen mode is helpful for presentations at work as well as peer programming
  -- for those with less experience with vim so it's less distracting
  {
    'folke/zen-mode.nvim',
    cmd = 'ZenMode',
    config = function()
      require('zen-mode').setup {
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
  -- sometimes we forget what the hotkeys are, this leverages telescope
  -- plugin to pop-up hotkeys if only part of it was clicked, or after
  -- simply hitting the <leader> key
  {
    'folke/which-key.nvim',
    disable = false
  },
  -- mostly simple webdev language support
  {
    'nvim-treesitter/nvim-treesitter',
    opts = {
      ensure_installed = {
        'bash',
        'css',
        'csv',
        'dockerfile',
        'go',
        'html',
        'javascript',
        'lua',
        'vim',
        'markdown',
        'markdown_inline',
        'regex',
        'rust',
        'scss',
        'typescript',
        'vue',
        'yaml'
      }
    }
  },
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
