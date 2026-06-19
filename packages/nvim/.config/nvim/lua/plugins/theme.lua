return {
  -- catppuccin replaces NvChad's base46 theming. latte (light) <-> mocha (dark)
  -- gives the same light/dark toggle the old onedark/github_light pair did.
  {
    'catppuccin/nvim',
    name = 'catppuccin',
    lazy = false,
    priority = 1000,
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
      vim.cmd.colorscheme 'catppuccin'
    end,
  },
}
