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
opt.guifont = { 'PragmataPro', ':h14' }
opt.list = true
opt.listchars = {
  eol = '¬', nbsp = '¤', space = '⋅', trail = '•',
  tab = '››', extends = '…', precedes = '…', conceal = '‡'
}
opt.showmatch = true
opt.smartcase = true
opt.relativenumber = true
vim.g.mapleader = ' '
