-- Headless farm sync for shell launchers:
--   nvim -l workspaces/sync.lua <TICKET>
-- Prints the farm path on success.
local ticket = _G.arg[1]
if not ticket then
  io.stderr:write "usage: sync.lua <TICKET>\n"
  os.exit(64)
end

local ok, result = pcall(function() return require("workspaces.core").sync(ticket:upper()) end)
if not ok then
  io.stderr:write(tostring(result) .. "\n")
  os.exit(1)
end
print(result)
