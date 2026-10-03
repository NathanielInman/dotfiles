-- Keeps the G9 dark when it relinks itself after an Idle.
--
-- Entering standby, the G9 (behind the KVM) drops both DP links and relinks
-- about a second later. Hyprland treats that as a new monitor and powers it
-- on, which wakes the panel. Turning it off here, inside the compositor the
-- moment it is added, beats the first frame; idle-dpms-guard.py (waybar
-- scripts) catches anything this misses.
--
-- Only acts while the guard is alive. The guard exits on real input, so a
-- relink during a real wake lights up as normal, and a stale pidfile from a
-- killed guard is ignored.

local pidfile = (os.getenv("XDG_RUNTIME_DIR") or "/tmp") .. "/idle-dpms-guard.pid"

local function guard_active()
  local f = io.open(pidfile)
  if not f then return false end
  local pid = f:read("*l")
  f:close()
  if not pid or not pid:match("^%d+$") then return false end
  local c = io.open("/proc/" .. pid .. "/cmdline")
  if not c then return false end
  local cmd = c:read("*a")
  c:close()
  return cmd:find("idle-dpms-guard", 1, true) ~= nil
end

local function dpms_off(name)
  hl.dispatch(hl.dsp.dpms({ action = "off", monitor = name }))
end

hl.on("monitor.added", function(mon)
  local ok, name = pcall(function() return mon.name end)
  if not ok or type(name) ~= "string" then name = tostring(mon) end
  if name == "FALLBACK" or not guard_active() then return end
  dpms_off(name)
  -- Again once setup has settled, in case applying the monitor rule
  -- re-enabled it after this handler ran
  hl.timer(function()
    if guard_active() then dpms_off(name) end
  end, { timeout = 100, type = "oneshot" })
end)
