-- [nfnl] fnl/term-wraps.fnl
local M = {}
local max_outputs = 50
local max_bytes = 200000
local states = {}
local function clean(s)
  return (s:gsub("\27%][^\a\27]*\a", ""):gsub("\27%][^\a\27]*\27\\", ""):gsub("\27[P_%^X][^\27]*\27\\", ""):gsub("\27%[[0-?]*[ -/]*[@-~]", ""):gsub("\27[%(%)]%w", ""):gsub("\27.", ""):gsub("\r\n", "\n"):gsub("[^\n]*\r", ""))
end
local function feed(st, chunk)
  st.raw = (st.raw .. chunk)
  local more = true
  while more do
    if st["in-output"] then
      local d = st.raw:find("\27]133;D", 1, true)
      if d then
        table.insert(st.outputs, clean(st.raw:sub(1, (d - 1))))
        if (#st.outputs > max_outputs) then
          table.remove(st.outputs, 1)
        else
        end
        st.raw = st.raw:sub((d + 1))
        st["in-output"] = false
      else
        if (#st.raw > max_bytes) then
          st.raw = st.raw:sub(( - max_bytes))
        else
        end
        more = false
      end
    else
      local c = st.raw:find("\27]133;C", 1, true)
      local _, e
      if c then
        _, e = st.raw:find("\a", c, true)
      else
        _, e = nil
      end
      if e then
        st.raw = st.raw:sub((e + 1))
        st["in-output"] = true
      else
        if c then
          st.raw = st.raw:sub(c)
        else
          st.raw = st.raw:sub(-16)
        end
        more = false
      end
    end
  end
  return nil
end
M.on_stdout = function(term, _job, data)
  local st = (states[term.bufnr] or {raw = "", outputs = {}, ["in-output"] = false})
  states[term.bufnr] = st
  return feed(st, table.concat(data, "\n"))
end
local function newest_first(st)
  local outs
  if st["in-output"] then
    outs = {clean(st.raw)}
  else
    outs = {}
  end
  for i = #st.outputs, 1, -1 do
    table.insert(outs, st.outputs[i])
  end
  return outs
end
local function wrapped_3f(outs, row, nxt)
  local and_9_ = (nxt ~= "")
  if and_9_ then
    local res = nil
    for _, out in ipairs(outs) do
      if (res ~= nil) then break end
      if out:find((row .. nxt), 1, true) then
        res = true
      elseif out:find((row .. "\n"), 1, true) then
        res = false
      else
        res = nil
      end
    end
    and_9_ = res
  end
  return and_9_
end
local function join_wraps()
  do
    local ev = vim.v.event
    local st = states[vim.api.nvim_get_current_buf()]
    if (st and (vim.bo.buftype == "terminal") and (ev.operator == "y") and (ev.regtype:sub(1, 1) ~= "\22")) then
      local info = vim.fn.getwininfo(vim.api.nvim_get_current_win())[1]
      local cols = (info.width - info.textoff)
      local outs = newest_first(st)
      local start = vim.fn.line("'[")
      local out = {ev.regcontents[1]}
      for i = 2, #ev.regcontents do
        local row = vim.fn.getline((start + i + -2))
        local nxt = vim.fn.getline((start + i + -1))
        if ((vim.fn.strdisplaywidth(row) >= (cols - 1)) and wrapped_3f(outs, row, nxt)) then
          out[#out] = (out[#out] .. ev.regcontents[i])
        else
          table.insert(out, ev.regcontents[i])
        end
      end
      vim.fn.setreg(ev.regname, out, ev.regtype)
      if ((ev.regname == "") and vim.o.clipboard:find("unnamedplus")) then
        vim.fn.setreg("+", out, ev.regtype)
      else
      end
    else
    end
  end
  return nil
end
vim.api.nvim_create_autocmd("TextYankPost", {callback = join_wraps, group = vim.api.nvim_create_augroup("term_wraps", {clear = true})})
local function _14_(_241)
  states[_241.buf] = nil
  return nil
end
vim.api.nvim_create_autocmd("BufWipeout", {callback = _14_, group = "term_wraps"})
return M
