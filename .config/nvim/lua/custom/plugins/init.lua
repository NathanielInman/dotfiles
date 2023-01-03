return {
  ['cljoly/telescope-repo.nvim'] = {}, -- allows <leader>fd to find repos on machine
  ['AckslD/nvim-neoclip.lua'] = {
    config = function()
      require('neoclip').setup()
    end
  },
  ['luukvbaal/nnn.nvim'] = {
    config = function()
      require('nnn').setup({
        picker = {
          cmd = "NNN_COLORS='1234' NNN_FCOLORS='c1e2272e006033f7c6d6abc4' nnn -deoHS",
          style = { border = 'rounded' }
        },
        auto_close = true,
        windownav = {
          left = '<leader>h',
          right = '<leader>l'
        },
        buflisted = true
      })
    end
  },
  ['folke/zen-mode.nvim'] = {
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
          vim.opt.guifont = { 'PragmataPro', ':h12' }
        end
      }
    end
  },
  ['folke/which-key.nvim'] = {
    disable = false
  },
  ['nvim-treesitter/nvim-treesitter'] = {
    override_options = {
      ensure_installed = {
        'html',
        'markdown',
        'yaml',
        'lua',
        'javascript'
      }
    }
  },
  ['kyazdani42/nvim-tree.lua'] = {
    override_options = {
      respect_buf_cwd = true,
      update_focused_file = {
        enable = true,
        update_root = true,
      },
      git = {
        enable = true
      },
      renderer = {
        highlight_git = true,
        icons = {
          show = {
            git = true
          }
        }
      },
      actions = {
        open_file = {
          quit_on_open = true
        }
      }
    }
  },
  ['williamboman/mason.nvim'] = {
    override_options = {
      ensure_installed = {
        'lua-language-server',
        'marksman',
        'html-lsp',
        'yaml-language-server'
      }
    }
  }
}
