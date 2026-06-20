-- [nfnl] fnl/utils/init.fnl
local M = {}
M.empty = function(table)
  return ((nil == table) or (nil == next(table)))
end
local debug_log = (vim.fn.stdpath("data") .. "/debug.txt")
M.log = function(...)
  local n = select("#", ...)
  local parts = {}
  for i = 1, n do
    parts[i] = vim.inspect(select(i, ...))
  end
  local f = io.open(debug_log, "a")
  local function close_handlers_13_(ok_14_, ...)
    f:close()
    if ok_14_ then
      return ...
    else
      return error(..., 0)
    end
  end
  local function _2_(...)
    local args_15_ = {...}
    local n_16_ = select("#", ...)
    local unpack_17_ = (_G.unpack or _G.table.unpack)
    local function _3_()
      local function _4_(...)
        return f:write((os.date("%H:%M:%S ") .. table.concat(parts, " ") .. "\n"))
      end
      return _4_(unpack_17_(args_15_, 1, n_16_))
    end
    local _6_
    do
      local t_5_ = _G
      if (nil ~= t_5_) then
        t_5_ = t_5_.package
      else
      end
      if (nil ~= t_5_) then
        t_5_ = t_5_.loaded
      else
      end
      if (nil ~= t_5_) then
        t_5_ = t_5_.fennel
      else
      end
      _6_ = t_5_
    end
    local or_10_ = _6_ or _G.debug
    if not or_10_ then
      local function _11_()
        return ""
      end
      or_10_ = {traceback = _11_}
    end
    return _G.xpcall(_3_, or_10_.traceback)
  end
  return close_handlers_13_(_2_(...))
end
local function _12_()
  return vim.cmd(("vsp " .. debug_log))
end
vim.api.nvim_create_user_command("ViewDebugLog", _12_, {desc = "View debug log."})
return M
