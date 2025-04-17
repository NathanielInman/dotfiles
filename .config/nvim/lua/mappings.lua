local map = vim.keymap.set

-- Core
map('n', '<leader>L', ':Lazy<CR>', { desc = 'Open lazy plugin manager' })
map('n', '<leader>T', ':FzfLua<CR>', { desc = 'Toggle main telescope window' })
map('n', '<leader>zm', ':ZenMode<CR>', { desc = 'Toggle ZenMode' })
map('n', '\\', ':NvimTreeToggle<CR>', { desc = 'Toggle NVim Tree' })
map('n', '<leader>\\', ':NvimTreeFindFile<CR>', { desc = 'Toggle Tree & Open At File' })
map('n', '<leader>cd', ':cd %:p:h<CR>:pwd<CR>')
map('n', '<leader>cc', ':Shades<CR>', { desc = 'Color check shades' })
map('n', '<leader>ch', ':Huefy<CR>', { desc = 'Color check hues' })
map('n', '<leader>ff', ':FzfLua files<CR>', { desc = 'Find files with fzf' })
map('n', '<leader>fl', ':FzfLua files<CR>', { desc = 'Find lines with fzf' })

-- Menus
map({ 'n', 'v' }, '<RightMouse>', function()
  vim.cmd.exec '"normal! \\<RightMouse>"'

  require('plenary.reload').reload_module 'menus'
  require('plenary.reload').reload_module 'menu'

  local options = vim.bo.ft == 'NvimTree' and 'nvimtree' or 'default'
  require('menu').open(options, { mouse = true })
end, { desc = 'Right click menu' })
map({ 'n', 'v' }, '<leader>a', function()
  require('plenary.reload').reload_module 'menus'
  require('plenary.reload').reload_module 'menu'

  local options = vim.bo.ft == 'NvimTree' and 'nvimtree' or 'default'
  require('menu').open(options)
end, { desc = 'General action menu using plenary' })
map({ 'n', 'v' }, '<leader>ga', function()
  require('plenary.reload').reload_module 'menus'
  require('plenary.reload').reload_module 'menu'

  require('menu').open 'gitsigns'
end, { desc = 'Git action menu using plenary' })
map({ 'n', 'v' }, '<leader>e', function()
  require('nvchad.themes').open()
end, { desc = 'Open nvchad base46 themes' })

-- Windows
map('n', '<leader>nj', ':rightbelow sb #<CR>', { desc = 'Open window to the bottom' })
map('n', '<leader>nk', ':leftabove sb #<CR>', { desc = 'Open window to the top' })
map('n', '<leader>nh', ':vert leftabove sb #<CR>', { desc = 'Open window to the left' })
map('n', '<leader>nl', ':vert rightbelow sb #<CR>', { desc = 'Open window to the right' })
map('n', '<leader>j', '<C-w>j', { desc = 'Jump from current window to one below' })
map('n', '<leader>l', '<C-w>l', { desc = 'Jump from current window to one to the right' })
map('n', '<leader>h', '<C-w>h', { desc = 'Jump from current window to one to the left' })
map('n', '<leader>k', '<C-w>k', { desc = 'Jump from current window to one above' })
map('n', '<leader>mk', '<CMD>WinShift up<CR>', { desc = 'Swap current window with one above' })
map('n', '<leader>mj', '<CMD>WinShift down<CR>', { desc = 'Swap current window with one below' })
map('n', '<leader>mh', '<CMD>WinShift left<CR>', { desc = 'Swap current window with one to the left' })
map('n', '<leader>ml', '<CMD>WinShift right<CR>', { desc = 'Swap current window with one to the right' })
map('n', '<leader>mf', '<CMD>WindowsMaximize<CR>', { desc = 'Toggle focus the current window' })

-- Buffers
map('n', '<leader>bn', ':new<CR>', { desc = 'Create a new buffer tab' })
map('n', '<leader>bl', function()
  require('nvchad.tabufline').next()
end, { desc = 'Goto next buffer tab' })
map('n', '<leader>bh', function()
  require('nvchad.tabufline').prev()
end, { desc = 'Goto previous buffer tab' })
map('n', '<leader>bq', ':Bdelete<CR>', { desc = 'Quit current buffer tab' })
map('n', '<leader>bs', ':FzfLua buffers<CR>', { desc = 'List buffer tabs' })

-- Terminals
map('t', '<C-j>', '<C-\\><C-n><C-w>j', { desc = 'Jump from terminal to window below' })
map('t', '<C-l>', '<C-\\><C-n><C-w>l', { desc = 'Jump from terminal to right window' })
map('t', '<C-h>', '<C-\\><C-n><C-w>h', { desc = 'Jump from terminal to left window' })
map('t', '<C-k>', '<C-\\><C-n><C-w>k', { desc = 'Jump from terminal to window above' })

-- LSP Mappings
map('n', 'gD', vim.lsp.buf.declaration, { desc = 'Go to declaration' })

-- Markdown
map('n', '<leader>mt', ':RenderMarkdown toggle<CR>', { desc = 'Toggle markdown preview' })
