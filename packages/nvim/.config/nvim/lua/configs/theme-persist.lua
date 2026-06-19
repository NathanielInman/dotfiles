-- Persist the active colorscheme across restarts.
-- Stored outside the repo in nvim's state dir so the choice is per-machine.
local M = {}

local file = vim.fn.stdpath 'state' .. '/last-colorscheme'

-- Returns the saved colorscheme name, or nil if none/unreadable.
function M.load()
  local f = io.open(file, 'r')
  if not f then
    return nil
  end
  local name = f:read '*l'
  f:close()
  if name and name ~= '' then
    return name
  end
end

function M.save(name)
  if not name or name == '' then
    return
  end
  local f = io.open(file, 'w')
  if not f then
    return
  end
  f:write(name)
  f:close()
end

return M
