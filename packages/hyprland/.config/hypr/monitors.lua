-- Monitors
hl.monitor({ output = "DP-1", mode = "2560x1440@59.95", position = "0x0", scale = 1 })
hl.monitor({ output = "DP-2", mode = "2560x1440@59.95", position = "2560x0", scale = 1 })
-- Fallback: any output not matched above (e.g. a different connector name
-- through the KVM, like HDMI-A-1) still lights up at its preferred mode.
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1 })

-- Workspace assignments
local assignments = {
  ["DP-1"] = { 1, 4, 5, 6 },
  ["DP-2"] = { 2, 3, 7, 8, 9, 10 },
}
for monitor, workspaces in pairs(assignments) do
  for _, ws in ipairs(workspaces) do
    hl.workspace_rule({ workspace = tostring(ws), monitor = monitor, persistent = true })
  end
end
