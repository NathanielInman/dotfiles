local autocmd = vim.api.nvim_create_autocmd

-- briefly highlight yanked text
autocmd('TextYankPost', {
  group = vim.api.nvim_create_augroup('highlight_yank', { clear = true }),
  callback = function()
    vim.hl.on_yank { timeout = 200 }
  end,
})

-- NOTE: treesitter highlighting is started per-buffer by a FileType autocmd
-- in lua/plugins/treesitter.lua (nvim-treesitter main branch API).
