-- [nfnl] fnl/utils/init.fnl
local M = {}
M["empty?"] = function(table)
  return ((nil == table) or (nil == next(table)))
end
local debug_log = (vim.fn.stdpath("data") .. "/debug.txt")
M.log = function(...)
  local n = select("#", ...)
  local parts = {}
  for i = 1, n do
    local a = select(i, ...)
    local _1_
    if (type(a) == "table") then
      _1_ = vim.inspect(a)
    else
      _1_ = tostring(a)
    end
    parts[i] = _1_
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
  local function _4_(...)
    local args_15_ = {...}
    local n_16_ = select("#", ...)
    local unpack_17_ = (_G.unpack or _G.table.unpack)
    local function _5_()
      local function _6_(...)
        return f:write((os.date("%H:%M:%S ") .. table.concat(parts, " ") .. "\n"))
      end
      return _6_(unpack_17_(args_15_, 1, n_16_))
    end
    local _8_
    do
      local t_7_ = _G
      if (nil ~= t_7_) then
        t_7_ = t_7_.package
      else
      end
      if (nil ~= t_7_) then
        t_7_ = t_7_.loaded
      else
      end
      if (nil ~= t_7_) then
        t_7_ = t_7_.fennel
      else
      end
      _8_ = t_7_
    end
    local or_12_ = _8_ or _G.debug
    if not or_12_ then
      local function _13_()
        return ""
      end
      or_12_ = {traceback = _13_}
    end
    return _G.xpcall(_5_, or_12_.traceback)
  end
  return close_handlers_13_(_4_(...))
end
M["any?"] = function(pred, list)
  local found_3f = false
  for _, x in ipairs(list) do
    if found_3f then break end
    found_3f = pred(x)
  end
  return found_3f
end
M.tail = function(list)
  return list[#list]
end
M.head = function(list)
  return list[1]
end
M["group-by"] = function(key_fn, coll)
  local acc = {}
  for _, item in ipairs(coll) do
    local k = key_fn(item)
    if (nil == acc[k]) then
      acc[k] = {}
    else
    end
    table.insert(acc[k], item)
    acc = acc
  end
  return acc
end
M.debounce = function(ms, f)
  local timer = vim.uv.new_timer()
  local function _15_()
    timer:stop()
    timer:start(ms, 0, vim.schedule_wrap(f))
    return nil
  end
  return _15_
end
local function _16_()
  return vim.cmd(("vsp " .. debug_log))
end
vim.api.nvim_create_user_command("DebugLogView", _16_, {desc = "View debug log."})
local function _17_()
  return vim.cmd(("!rm -f " .. debug_log))
end
vim.api.nvim_create_user_command("DebugLogClear", _17_, {desc = "View debug log."})
return M
