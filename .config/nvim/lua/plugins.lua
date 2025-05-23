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
  -- this ensures buffers are deleted without messing up ui
  {
    'famiu/bufdelete.nvim',
    lazy = false,
  },
  -- this helps maintain sessions per folder
  {
    'rmagatti/auto-session',
    lazy = false,
    config = function()
      require('auto-session').setup {
        log_level = 'error',
      }
    end,
  },
  -- some basic overwrites to ensure the icons work properly with
  -- PragmataPro
  {
    'nvim-web-devicons',
    config = function()
      require('nvim-web-devicons').setup {
        override_by_extension = {
          js = {
            icon = ' ',
            color = '#cbcb41',
            name = 'js',
          },
          jsx = {
            icon = ' ',
            color = '#cbcb41',
            name = 'jsx',
          },
          log = {
            icon = ' ',
            color = '#ffffff',
            name = 'log',
          },
          lua = {
            icon = ' ',
            color = '#51a0cf',
            name = 'lua',
          },
          py = {
            icon = ' ',
            color = '#ffbc03',
            name = 'py',
          },
          styl = {
            icon = ' ',
            color = '#8dc149',
            name = 'styl',
          },
          ts = {
            icon = ' ',
            color = '#519aba',
            name = 'ts',
          },
          tsx = {
            icon = ' ',
            color = '#519aba',
            name = 'tsx',
          },
          json = {
            icon = ' ',
            color = '#cbcb41',
            name = 'json',
          },
          yml = {
            icon = ' ',
            color = '#6d8086',
            name = 'yml',
          },
          vue = {
            icon = ' ',
            color = '#8dc149',
            name = 'vue',
          },
        },
      }
    end,
  },
  -- bufferline has been slightly altered so it coexists easily with
  -- the nordtheme as well as PragmataPro icons
  {
    'akinsho/bufferline.nvim',
    lazy = false,
    version = '*',
    dependencies = 'nvim-tree/nvim-web-devicons',
    config = function()
      require('bufferline').setup {
        options = {
          separator_style = 'thin',
          diagnostics = 'nvim_lsp',
          close_icon = '⮾',
          buffer_close_icon = '⮾',
          indicator = {
            style = 'none',
          },
          offsets = {
            {
              filetype = 'NvimTree',
              text = 'File Explorer',
              text_align = 'center',
              separator = true,
            },
          },
        },
        highlights = {
          fill = {
            bg = '#2a303c', -- inactive titlebar
          },
          background = {
            bg = '#2a303c', -- inactive tabs
          },
          close_button = {
            bg = '#2a303c',
            fg = '#777777',
          },
          buffer_selected = {
            bg = '#1e222a',
          },
          close_button_selected = {
            bg = '#1e222a',
            fg = '#777777',
          },
          error = {
            bg = '#2a303c', -- LSP error
            fg = '#ffc0b9',
          },
          error_selected = {
            bg = '#1e222a',
          },
          hint = {
            bg = '#2a303c',
            fg = '#a6dbff',
          },
          indicator_selected = {
            bg = '#1e222a', -- separator closest
          },
          modified = {
            bg = '#2a303c',
          },
          modified_selected = {
            bg = '#1e222a', -- save icon
          },
          separator = {
            bg = '#2a303c', -- separator furthest
            fg = '#2a303c', -- separator close
          },
        },
      }
    end,
  },
  -- tui to walk through commits easily and view diffs in neovim
  {
    'neogitorg/neogit',
    dependencies = {
      'nvim-lua/plenary.nvim',
      'nvim-telescope/telescope.nvim',
      'sindrets/diffview.nvim',
      'ibhagwan/fzf-lua',
    },
    keys = {
      { '<leader>gs', '<cmd>Neogit<cr>', desc = 'Toggle neogit visibility' },
    },
    config = true,
  },
  -- underline similar words to that under the cursor
  {
    'rrethy/vim-illuminate',
    lazy = false,
  },
  -- easymotion jumping
  {
    'smoka7/hop.nvim',
    version = '*',
    keys = {
      { '<leader><leader>', ':HopPattern<CR>', 'Start easymotion/hop pattern jumping' },
    },
    config = function()
      require('hop').setup {
        keys = 'etovxqpdygfblzhckisuran',
      }
    end,
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
      'rcarriga/nvim-notify',
    },
    config = function()
      require('noice').setup {
        lsp = {
          hover = {
            enabled = false, -- handled by nvchad
          },
          signature = {
            enabled = false, -- handled by nvchad
          },
          override = {
            ['vim.lsp.util.convert_input_to_markdown_lines'] = true,
            ['vim.lsp.util.stylize_markdown'] = true,
            ['cmp.entry.get_documentation'] = true,
          },
        },
        presets = {
          bottom_search = true,
          command_palette = true,
          long_message_to_split = true,
          inc_rename = false,
          lsp_doc_border = false,
        },
      }
    end,
  },
  -- zen mode is helpful for presentations at work as well as peer programming
  -- for those with less experience with vim so it's less distracting
  {
    'folke/zen-mode.nvim',
    cmd = 'ZenMode',
    config = function()
      require('zen-mode').setup {
        window = {
          width = 0.5,
        },
        on_open = function()
          vim.opt.guifont = { 'PragmataPro', ':h20' }
        end,
        on_close = function()
          vim.opt.guifont = { 'PragmataPro', ':h16' }
        end,
      }
    end,
  },
  -- sometimes we forget what the hotkeys are, this leverages telescope
  -- plugin to pop-up hotkeys if only part of it was clicked, or after
  -- simply hitting the <leader> key
  {
    'folke/which-key.nvim',
    disable = false,
  },
  {
    'folke/trouble.nvim',
    opts = {}, -- for default options, refer to the configuration section for custom setup.
    cmd = 'Trouble',
    keys = {
      {
        '<leader>xx',
        '<cmd>Trouble diagnostics toggle<cr>',
        desc = 'Diagnostics (Trouble)',
      },
    },
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
        'yaml',
      },
    },
  },
  -- styling and linting tools to get us insight
  {
    'williamboman/mason.nvim',
    opts = {
      ensure_installed = {
        'prettier', -- used by conform
        'typescript-language-server', -- used by conform, lspconfig
        'lua-language-server', -- used by conform, lspconfig
      },
    },
  },
  -- make life really easy with :LspInstall
  {
    'williamboman/mason-lspconfig.nvim',
    config = function()
      require('mason-lspconfig').setup {
        ensure_installed = { 'html', 'cssls', 'ts_ls', 'volar', 'lua_ls' },
      }
    end,
  },
  {
    'neovim/nvim-lspconfig',
    config = function()
      require 'configs.lspconfig'
    end,
  },
  -- mainly the default nvimtree (neovim nerdtree) but a little bit bigger
  -- and default for showing all files nomatter what
  -- this formats the code on save
  {
    'stevearc/conform.nvim',
    event = 'BufWritePre',
    opts = require 'configs.conform',
  },
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
