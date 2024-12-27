return {
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
}
