-- [nfnl] fnl/utils/macros.fnl
local function tx(...)
  local args = {...}
  local to_merge
  if __fnl_global__table_3f(args[#args]) then
    to_merge = table.remove(args)
  else
    to_merge = nil
  end
  if to_merge then
    for key, value in pairs(to_merge) do
      args[key] = value
    end
    return args
  else
    return args
  end
end
return {tx = tx}
