-- Custom default action menu. Overrides nvzone/menu's shipped menus.default so
-- the "Open in terminal" action uses snacks' terminal instead of the removed
-- nvchad.term. The "lsp", "nvimtree", and "gitsigns" submenus still come from
-- the plugin's shipped definitions (they have no NvChad coupling).
return {
  {
    name = 'Format Buffer',
    cmd = function()
      require('conform').format { lsp_fallback = true }
    end,
    rtxt = '<leader>fm',
  },
  {
    name = 'Code Actions',
    cmd = vim.lsp.buf.code_action,
    rtxt = '<leader>ca',
  },

  { name = 'separator' },

  {
    name = '  Lsp Actions',
    hl = 'Exblue',
    items = 'lsp',
  },

  { name = 'separator' },

  {
    name = 'Edit Config',
    cmd = function()
      vim.cmd 'tabnew'
      vim.cmd('tcd ' .. vim.fn.stdpath 'config' .. ' | e init.lua')
    end,
    rtxt = 'ed',
  },
  {
    name = 'Copy Content',
    cmd = '%y+',
    rtxt = '<C-c>',
  },
  {
    name = 'Delete Content',
    cmd = '%d',
    rtxt = 'dc',
  },

  { name = 'separator' },

  {
    name = '  Open in terminal',
    hl = 'ExRed',
    cmd = function()
      local old_buf = require('menu.state').old_data.buf
      local dir = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(old_buf), ':h')
      require('snacks').terminal(nil, { cwd = dir })
    end,
  },

  { name = 'separator' },

  {
    name = '  Color Picker',
    cmd = function()
      require('minty.huefy').open()
    end,
  },
}
