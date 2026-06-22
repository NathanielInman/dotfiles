return {
  -- Nord is the default scheme (matches the rest of the distro). catppuccin
  -- stays installed for variety in the picker (<leader>uC) and the light/dark
  -- toggle (<leader>e: latte <-> mocha). Both feed the persistence layer below.
  {
    'catppuccin/nvim',
    name = 'catppuccin',
    lazy = true,
    opts = {
      flavour = 'mocha',
      background = { light = 'latte', dark = 'mocha' },
      -- keep the custom Nord terminal colors set in options.lua
      term_colors = false,
      styles = {
        comments = { 'italic' }, -- was hl_override Comment/@comment italic
      },
      integrations = {
        blink_cmp = true,
        flash = true,
        fzf = true,
        gitsigns = true,
        illuminate = true,
        lsp_trouble = true,
        markdown = true,
        mason = true,
        native_lsp = { enabled = true },
        noice = true,
        nvimtree = true,
        render_markdown = true,
        snacks = true,
        treesitter = true,
        which_key = true,
      },
    },
    config = function(_, opts)
      require('catppuccin').setup(opts)
    end,
  },
  {
    'gbprod/nord.nvim',
    lazy = false,
    priority = 1000,
    -- pull catppuccin in (and run its setup) before we apply a saved scheme,
    -- so a persisted catppuccin flavour is ready on startup.
    dependencies = { 'catppuccin/nvim' },
    opts = {
      -- keep the custom Nord terminal colors set in options.lua
      terminal_colors = false,
      styles = {
        comments = { italic = true },
      },
    },
    config = function(_, opts)
      require('nord').setup(opts)

      local persist = require 'configs.theme-persist'

      -- Persist any colorscheme change (toggle, picker, manual :colorscheme).
      vim.api.nvim_create_autocmd('ColorScheme', {
        callback = function(ev)
          persist.save(ev.match or vim.g.colors_name)
        end,
      })

      -- Restore the last-used scheme, falling back to nord if it's gone/unset.
      local saved = persist.load()
      if not (saved and pcall(vim.cmd.colorscheme, saved)) then
        vim.cmd.colorscheme 'nord'
      end
    end,
  },
}
