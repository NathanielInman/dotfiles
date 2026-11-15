-- The G9 (PBP, DP-2 + DP-3) relinks: it drops both DP links and comes back
-- about two seconds later, as if the cables were replugged. Hyprland removes
-- both monitors and re-adds them lit. It does this in two places:
--
-- 1. About ten seconds into standby, with nobody at the desk. Re-added lit,
--    the screens wake themselves. A half that was dark when it went away is
--    turned straight back off.
-- 2. Waking from standby, right after the key press lit it. The re-added
--    halves are modeset while the panel is still settling and the G9 can
--    miss it: the kernel and Hyprland report both lit at 2560x1440 while
--    the panel stays black, until something modesets again. So once the
--    relink settles, the lit halves get a short dpms off/on.
--
-- The decision is the half's dpms state when it was removed, not a guess at
-- whether someone touched the desk, so a real wake can't be put back to sleep.

local SETTLE_MS = 2000 -- after the last monitor add in a relink burst
local OFF_MS = 500

local dark_when_removed = {}
local burst = 0

local function name_of(mon)
  local ok, name = pcall(function() return mon.name end)
  return ok and type(name) == "string" and name or nil
end

local function dpms(action, name)
  hl.dispatch(hl.dsp.dpms({ action = action, monitor = name }))
end

hl.on("monitor.removed", function(mon)
  local name = name_of(mon)
  if not name or name == "FALLBACK" then return end
  local ok, on = pcall(function() return mon.dpms_status end)
  dark_when_removed[name] = ok and on == false
end)

hl.on("monitor.added", function(mon)
  local name = name_of(mon)
  if not name or name == "FALLBACK" then return end

  if dark_when_removed[name] then
    dark_when_removed[name] = nil
    dpms("off", name)
    -- Again once setup has settled, in case the monitor rule re-lit it
    hl.timer(function() dpms("off", name) end, { timeout = 100, type = "oneshot" })
    return
  end
  dark_when_removed[name] = nil

  burst = burst + 1
  local mine = burst
  hl.timer(function()
    if mine ~= burst then return end -- a later add restarted the wait
    local lit = {}
    for _, m in ipairs(hl.get_monitors()) do
      if m.name ~= "FALLBACK" and m.dpms_status then lit[#lit + 1] = m.name end
    end
    for _, n in ipairs(lit) do dpms("off", n) end
    hl.timer(function()
      for _, n in ipairs(lit) do dpms("on", n) end
    end, { timeout = OFF_MS, type = "oneshot" })
  end, { timeout = SETTLE_MS, type = "oneshot" })
end)
