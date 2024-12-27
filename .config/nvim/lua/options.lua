require 'nvchad.options'

local opt = vim.opt

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

-- highlight the matched bracket
opt.showmatch = true

-- smartly ignore case restrictions in the case ignorecase is on
-- and search includes a capitalized character
opt.smartcase = true

-- enable relative line numbers
opt.relativenumber = true

-- make sure the cursor isn't at the end of screen when scrolling
opt.scrolloff = 15

-- the only configuration parameter that matters
vim.g.mapleader = ' '

-- vim.api.nvim_exec('language en_US.UTF-8', true)
vim.api.nvim_set_hl(0, 'IlluminatedWordWrite', { underline = true })
vim.api.nvim_set_hl(0, 'IlluminatedWordRead', { underline = true })
vim.api.nvim_set_hl(0, 'IlluminatedWordText', { underline = true })
