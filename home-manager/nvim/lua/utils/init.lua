-- [nfnl] fnl/utils/init.fnl
local M = {}
M.empty = function(table)
  return ((nil == table) or (nil == next(table)))
end
return M
