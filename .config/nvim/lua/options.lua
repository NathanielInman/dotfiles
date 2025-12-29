require 'nvchad.options'

local opt = vim.opt

-- Disable neovim's built-in markdown 4-space indentation
vim.g.markdown_recommended_style = 0

-- Start general configurations
-- autoindent is default to on in neovim
-- backspace=indent,eol,start is default on neovim
-- encoding is always utf-8 in neovim
-- hlsearch is default to on in neovim
-- incsearch is default to on in neovim
-- tabstop=2, shiftwidth=2 and expandtab = true defaults
-- belloff=all is default in neovim
-- mouse=a default
opt.guifont = 'PragmataPro Liga:h16'

-- enable list mode and swap some normally hidden chars
-- for those that can help distinguish between them
-- for identifying compiler errors or other anomalies
opt.list = true
opt.listchars = {
  eol = '¬',
  nbsp = '¤',
  space = '⋅',
  trail = '•',
  tab = '››',
  extends = '…',
  precedes = '…',
  conceal = '‡',
}

-- views can only be fully collapsed with the global statusline
opt.laststatus = 3

-- highlight the matched bracket
opt.showmatch = true

-- smartly ignore case restrictions in the case ignorecase is on
-- and search includes a capitalized character
opt.smartcase = true

-- enable relative line numbers
opt.relativenumber = true

-- make sure the cursor isn't at the end of screen when scrolling
opt.scrolloff = 15

-- ensure when sessions are loaded all settings are loaded
opt.sessionoptions = 'blank,buffers,curdir,folds,help,tabpages,winsize,winpos,terminal'

-- the only configuration parameter that matters
vim.g.mapleader = ' '

-- vim.api.nvim_exec('language en_US.UTF-8', true)
vim.api.nvim_set_hl(0, 'IlluminatedWordWrite', { underline = true })
vim.api.nvim_set_hl(0, 'IlluminatedWordRead', { underline = true })
vim.api.nvim_set_hl(0, 'IlluminatedWordText', { underline = true })

-- neovim terminal colors
vim.g.terminal_color_0 = '#3b4252'
vim.g.terminal_color_1 = '#bf616a'
vim.g.terminal_color_2 = '#a3be8c'
vim.g.terminal_color_3 = '#ebcb8b'
vim.g.terminal_color_4 = '#81a1c1'
vim.g.terminal_color_5 = '#b48ead'
vim.g.terminal_color_6 = '#88c0d0'
vim.g.terminal_color_7 = '#e5e9f0'
vim.g.terminal_color_8 = '#4c566a'
vim.g.terminal_color_9 = '#bf616a'
vim.g.terminal_color_10 = '#a3be8c'
vim.g.terminal_color_11 = '#ebcb8b'
vim.g.terminal_color_12 = '#81a1c1'
vim.g.terminal_color_13 = '#b48ead'
vim.g.terminal_color_14 = '#8fbcbb'
vim.g.terminal_color_15 = '#eceff4'
