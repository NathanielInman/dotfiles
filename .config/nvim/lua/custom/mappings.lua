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
    ['<leader>t'] = {':Telescope<CR>', 'Toggle main telescope window'},
    ['<leader>fd'] = {':Telescope repo list<CR>', 'Show list of repos on machine'},
    ['<leader>nn'] = {':NnnPicker<CR>', 'Show a telescope window of nnn'}
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
    ['<kEnter>'] = {'<CR>', 'Fix for hotkey to open file'},
    ['<S-kEnter>'] = {'<S-CR>', 'Fix for shift+hotkey to open file'}
  }
}

M.bufferAndWindowManagement = {
  n = {
    ['<leader>T'] = {':new<CR>', 'Create a new buffer tab'},
    ['<leader>bl'] = {':bnext<CR>', 'Go to next buffer tab'},
    ['<leader>bh'] = {':bprevious<CR>', 'Go to previous buffer tab'},
    ['<leader>bq'] = {':bp <BAR> bd #<CR>', 'Quit current buffer tab'},
    ['<leader>bs'] = {':ls<CR>', 'List buffer tabs'},
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
    ['<leader>sl'] = {':vertical res +5<CR>', 'Resize to grow current window rightwards'}
  }
}

return M
