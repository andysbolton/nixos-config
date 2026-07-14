-- Generic pre-write guard for external editors/agents:
--   nvim -l workspaces/guard.lua <file>
-- Claims the farm repo containing <file> if it is still unclaimed; no-op for
-- any other path. Exit 0 = safe to write, non-zero = the claim failed and the
-- write should be blocked.
local file = _G.arg[1]
if not file then
  io.stderr:write "usage: guard.lua <file>\n"
  os.exit(64)
end

local ok, err = pcall(function()
  local core = require "workspaces.core"
  local ticket, repo, claimed = core.parse(file)
  if ticket and not claimed then core.claim(ticket, repo) end
end)
if not ok then
  io.stderr:write(tostring(err) .. "\n")
  os.exit(1)
end
