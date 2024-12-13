local map = vim.keymap.set
-- vim.keymap.set({mode},{lhs},{rhs},{opts}) -- https://neovim.io/doc/user/lua.html#vim.keymap.set()
-- local nomap = vim.keymap.del
-- vim.keymap.del({modes},{lhs},{opts}) -- https://neovim.io/doc/user/lua.html#vim.keymap.del()

-- Start by removing some default nvchad maps that don't make sense
-- nomap('n', '<Bslash>') -- TODO: may not be used
-- nomap('n', '\\') -- TODO: may not be used
-- nomap('n', '<leader>n') -- toggles between relative line number

-- Core
map('n', '<leader>L', ':Telescope<CR>', { desc = 'Toggle main telescope window' })
map('n', '<leader>y', ':Telescope neoclip<CR>', { desc = 'Switch global buffer with previous yank' })
map('n', '<leader>zm', ':ZenMode<CR>', { desc = 'Toggle ZenMode' })
map('n', '\\', ':NvimTreeToggle<CR>', { desc = 'Toggle NVim Tree' })
map('n', '<leader>\\', ':NvimTreeFindFile<CR>', { desc = 'Toggle Tree & Open At File' })
map('n', '<leader>cd', ':cd %:p:h<CR>:pwd<CR>')
map('n', '<leader>cc', ':Shades<CR>', { desc = 'Color check shades' })
map('n', '<leader>ch', ':Huefy<CR>', { desc = 'Color check hues' })
map({ 'n', 'v' }, '<RightMouse>', function()
  vim.cmd.exec '"normal! \\<RightMouse>"'

  require('plenary.reload').reload_module 'menus'
  require('plenary.reload').reload_module 'menu'

  local options = vim.bo.ft == 'NvimTree' and 'nvimtree' or 'default'
  require('menu').open(options, { mouse = true })
end, {})

-- Windows
map('n', '<leader>nj', ':rightbelow sb #<CR>', { desc = 'Open window to the bottom' })
map('n', '<leader>nk', ':leftabove sb #<CR>', { desc = 'Open window to the top' })
map('n', '<leader>nh', ':vert leftabove sb #<CR>', { desc = 'Open window to the left' })
map('n', '<leader>nl', ':vert rightbelow sb #<CR>', { desc = 'Open window to the right' })
map('n', '<leader>j', '<C-w>j', { desc = 'Jump from current window to one below' })
map('n', '<leader>l', '<C-w>l', { desc = 'Jump from current window to one to the right' })
map('n', '<leader>h', '<C-w>h', { desc = 'Jump from current window to one to the left' })
map('n', '<leader>k', '<C-w>k', { desc = 'Jump from current window to one above' })
map('n', '<leader>mk', '<C-w>K', { desc = 'Swap current window with one above' })
map('n', '<leader>mj', '<C-w>K<C-w>r', { desc = 'Swap current window with one below' })
map('n', '<leader>mh', '<C-w>H', { desc = 'Swap current window with one to the left' })
map('n', '<leader>ml', '<C-w>H<C-w>r', { desc = 'Swap current window with one to the right' })
map('n', '<leader>sk', ':res +5<CR>', { desc = 'Resize to grow current window upwards' })
map('n', '<leader>sj', ':res -5<CR>', { desc = 'Resize to shrink current window downwards' })
map('n', '<leader>sh', ':vertical res -5<CR>', { desc = 'Resize to shrink current window leftwards' })
map('n', '<leader>sl', ':vertical res +5<CR>', { desc = 'Resize to grow current window rightwards' })

-- Buffers
map('n', '<leader>T', ':new<CR>', { desc = 'Create a new buffer tab' })
map('n', '<leader>bl', ':BufferLineCycleNext<CR>', { desc = 'Goto next buffer tab' })
map('n', '<leader>bh', ':BufferLineCyclePrev<CR>', { desc = 'Goto previous buffer tab' })
map('n', '<leader>bq', ':Bdelete<CR>', { desc = 'Quit current buffer tab' })
map('n', '<leader>bpq', ':BufferLinePickClose<CR>', { desc = 'Choose a buffer to close' })
map('n', '<leader>bpj', ':BufferLinePick<CR>', { desc = 'Choose a buffer to jump to' })
map('n', '<leader>bml', ':BufferLineMoveNext<CR>', { desc = 'Move buffer to next spot' })
map('n', '<leader>bmh', ':BufferLineMovePrev<CR>', { desc = 'Move buffer to previous spot' })
map('n', '<leader>bt', ':BufferLineTogglePin<CR>', { desc = 'Toggle lock on buffer to keep in place' })
map('n', '<leader>bs', ':Telescope buffers<CR>', { desc = 'List buffer tabs' })
