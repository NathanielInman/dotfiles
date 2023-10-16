local M = {}

M.disabled = {
  n = {
    ['<Bslash>'] = '',
    ['\\'] = '',
    ['<leader>n'] = ''
  }
}

M.telescope = {
  n = {
    ['<leader>L'] = {':Telescope<CR>', 'Toggle main telescope window'},
    ['<leader>y'] = {':Telescope neoclip<CR>', 'Switch global buffer with previous yanks'}
  }
}

M.trueZen = {
  n = {
    ['<leader>zm'] = {':ZenMode<CR>', 'Toggle ZenMode'},
  }
}

M.nvimTree = {
  n = {
    ['\\'] = {':NvimTreeToggle<CR>', 'Toggle NVim Tree'},
    ['<leader>\\'] = {':NvimTreeFindFile<CR>', 'Toggle Tree & Open At File'},
    ['<leader>cd'] = {':cd %:p:h<CR>:pwd<CR>'},
  }
}

M.windows = {
  n = {
    ['<leader>nj'] = {':rightbelow sb #<CR>', 'Open window to the bottom'},
    ['<leader>nk'] = {':leftabove sb #<CR>', 'Open window to the top'},
    ['<leader>nh'] = {':vert leftabove sb #<CR>', 'Open window to the left'},
    ['<leader>nl'] = {':vert rightbelow sb #<CR>', 'Open window to the right'},
    ['<leader>j'] = {'<C-w>j', 'Jump from current window to one below'},
    ['<leader>l'] = {'<C-w>l', 'Jump from current window to one to the right'},
    ['<leader>h'] = {'<C-w>h', 'Jump from current window to one to the left'},
    ['<leader>k'] = {'<C-w>k', 'Jump from current window to one above'},
    ['<leader>mk'] = {'<C-w>K', 'Swap current window with one above'},
    ['<leader>mj'] = {'<C-w>K<C-w>r', 'Swap current window with one below'},
    ['<leader>mh'] = {'<C-w>H', 'Swap current window with one to the left'},
    ['<leader>ml'] = {'<C-w>H<C-w>r', 'Swap current window with one to the right'},
    ['<leader>sk'] = {':res +5<CR>', 'Resize to grow current window upwards'},
    ['<leader>sj'] = {':res -5<CR>', 'Resize to shrink current window downwards'},
    ['<leader>sh'] = {':vertical res -5<CR>', 'Resize to shrink current window leftwards'},
    ['<leader>sl'] = {':vertical res +5<CR>', 'Resize to grow current window rightwards'},
  }
}

M.buffers = {
  n = {
    ['<leader>T'] = {':new<CR>', 'Create a new buffer tab'},
    ['<leader>bl'] = {':bnext<CR>', 'Go to next buffer tab'},
    ['<leader>bh'] = {':bprevious<CR>', 'Go to previous buffer tab'},
    ['<leader>bq'] = {':bp <BAR> bd #<CR>', 'Quit current buffer tab'},
    ['<leader>bpq'] = {':BufferLinePickClose<CR>', 'Choose a buffer to close'},
    ['<leader>bpj'] = {':BufferLinePick<CR>', 'Choose a buffer to jump to'},
    ['<leader>bml'] = {':BufferLineMoveNext<CR>', 'Move buffer to next spot'},
    ['<leader>bmh'] = {':BufferLineMovePrev<CR>', 'Move buffer to previous spot'},
    ['<leader>bt'] = {':BufferLineTogglePin<CR>', 'Toggle lock on buffer to keep in place'},
    ['<leader>bs'] = {':ls<CR>', 'List buffer tabs'},
  }
}

return M
