-- [nfnl] fnl/cmds/lsp.fnl
local M = {}
local _local_1_ = require("utils")
local group_by = _local_1_["group-by"]
local head = _local_1_.head
local empty_3f = _local_1_["empty?"]
local debounce = _local_1_.debounce
local nvim_buf_clear_namespace = vim.api.nvim_buf_clear_namespace
local nvim_buf_get_lines = vim.api.nvim_buf_get_lines
local nvim_buf_is_valid = vim.api.nvim_buf_is_valid
local nvim_buf_set_extmark = vim.api.nvim_buf_set_extmark
local nvim_create_augroup = vim.api.nvim_create_augroup
local nvim_create_autocmd = vim.api.nvim_create_autocmd
local nvim_create_namespace = vim.api.nvim_create_namespace
local nvim_win_get_buf = vim.api.nvim_win_get_buf
local nvim_win_get_cursor = vim.api.nvim_win_get_cursor
local nvim_echo = vim.api.nvim_echo
local nvim_get_current_win = vim.api.nvim_get_current_win
local nvim_set_option_value = vim.api.nvim_set_option_value
local ns = nvim_create_namespace("code_action_sign")
local function first_viewport_line()
  return vim.fn.line("w0")
end
local function last_viewport_line()
  return vim.fn.line("w$")
end
local function current_line()
  return head(nvim_win_get_cursor(0))
end
local function line_length_0_indexed(bufnr, line)
  return math.max((#head(nvim_buf_get_lines(bufnr, (line - 1), line, false)) - 1), 0)
end
local function code_action_clients(bufnr)
  return vim.lsp.get_clients({bufnr = bufnr, method = "textDocument/codeAction"})
end
local function make_given_range_params(context, bufnr, start_pos, end_pos, offset)
  local tmp_9_ = vim.lsp.util.make_given_range_params(start_pos, end_pos, bufnr, offset)
  tmp_9_["context"] = context
  return tmp_9_
end
local function make_range_params(context, offset_encoding)
  local tmp_9_ = vim.lsp.util.make_range_params(0, offset_encoding)
  tmp_9_["context"] = context
  return tmp_9_
end
local function request_code_actions(client, bufnr, params, cb)
  local function _2_(err, result, context)
    if err then
      nvim_echo({{("LSP client request failed: " .. err.message), "ErrorMsg", true, {err = true}}})
    else
    end
    return cb((result or {}), context)
  end
  return client:request("textDocument/codeAction", params, _2_, bufnr)
end
local function request_all(_4_)
  local clients = _4_.clients
  local bufnr = _4_.bufnr
  local context = _4_.context
  local on_actions = _4_["on-actions"]
  local on_done = _4_["on-done"]
  local start_pos = _4_["start-pos"]
  local end_pos = _4_["end-pos"]
  local pending = #clients
  for _, client in ipairs(clients) do
    local offset = client.offset_encoding
    local params
    if not (start_pos and end_pos) then
      params = make_range_params(context, offset)
    else
      params = make_given_range_params(context, bufnr, start_pos, end_pos, offset)
    end
    local function _6_(actions, context0)
      on_actions(actions, context0)
      pending = (pending - 1)
      if (pending == 0) then
        if on_done then
          return on_done()
        else
          return nil
        end
      else
        return nil
      end
    end
    request_code_actions(client, bufnr, params, _6_)
  end
  return nil
end
local function quickfix_3f(a)
  return vim.startswith((a.kind or ""), "quickfix")
end
local function apply_action(action, _9_)
  local client_id = _9_.client_id
  local bufnr = _9_.bufnr
  local client = vim.lsp.get_client_by_id(client_id)
  local do_apply
  local function _10_(act)
    if act.edit then
      vim.lsp.util.apply_workspace_edit(act.edit, client.offset_encoding)
    else
    end
    if act.command then
      local command
      if (type(act.command) == "table") then
        command = act.command
      else
        command = act
      end
      return client:exec_cmd(command, {bufnr = bufnr})
    else
      return nil
    end
  end
  do_apply = _10_
  if (not action.edit and client:supports_method("codeAction/resolve")) then
    local function _14_(err, resolved)
      local function _15_()
        if (err or not resolved) then
          return action
        else
          return resolved
        end
      end
      return do_apply(_15_())
    end
    return client:request("codeAction/resolve", action, _14_, bufnr)
  else
    return do_apply(action)
  end
end
local function select_and_apply(items)
  local function _17_(item)
    local a = item.action
    local _18_
    if a.kind then
      _18_ = ("  [" .. a.kind .. "]")
    else
      _18_ = ""
    end
    return ((a.title or "") .. _18_)
  end
  local function _20_(choice)
    if choice then
      return apply_action(choice.action, choice.context)
    else
      return nil
    end
  end
  return vim.ui.select(items, {prompt = "Code action:", format_item = _17_}, _20_)
end
local function action_lines(actions, buf_uri)
  local seen = {}
  local lines = {}
  local add
  local function _22_(range)
    local line
    do
      local t_23_ = range
      if (nil ~= t_23_) then
        t_23_ = t_23_.start
      else
      end
      if (nil ~= t_23_) then
        t_23_ = t_23_.line
      else
      end
      line = t_23_
    end
    if (line and not seen[line]) then
      table.insert(lines, line)
      seen[line] = true
      return nil
    else
      return nil
    end
  end
  add = _22_
  for _, a in ipairs(actions) do
    local _28_
    do
      local t_27_ = a
      if (nil ~= t_27_) then
        t_27_ = t_27_.kind
      else
      end
      _28_ = t_27_
    end
    if (_28_ == "quickfix") then
      local diagnostics
      local _31_
      do
        local t_30_ = a
        if (nil ~= t_30_) then
          t_30_ = t_30_.diagnostics
        else
        end
        _31_ = t_30_
      end
      diagnostics = (_31_ or {})
      if (#diagnostics > 0) then
        for _0, d in ipairs(diagnostics) do
          add(d.range)
        end
      else
        local edit
        do
          local t_33_ = a
          if (nil ~= t_33_) then
            t_33_ = t_33_.edit
          else
          end
          edit = t_33_
        end
        if edit then
          local _36_
          do
            local t_35_ = edit
            if (nil ~= t_35_) then
              t_35_ = t_35_.changes
            else
            end
            if (nil ~= t_35_) then
              t_35_ = t_35_[buf_uri]
            else
            end
            _36_ = t_35_
          end
          for _0, te in ipairs((_36_ or {})) do
            add(te.range)
          end
          local _40_
          do
            local t_39_ = edit
            if (nil ~= t_39_) then
              t_39_ = t_39_.documentChanges
            else
            end
            _40_ = t_39_
          end
          for _0, dc in ipairs((_40_ or {})) do
            local _43_
            do
              local t_42_ = dc
              if (nil ~= t_42_) then
                t_42_ = t_42_.textDocument
              else
              end
              if (nil ~= t_42_) then
                t_42_ = t_42_.uri
              else
              end
              _43_ = t_42_
            end
            if (_43_ == buf_uri) then
              local _47_
              do
                local t_46_ = dc
                if (nil ~= t_46_) then
                  t_46_ = t_46_.edits
                else
                end
                _47_ = t_46_
              end
              for _1, te in ipairs((_47_ or {})) do
                add(te.range)
              end
            else
            end
          end
        else
        end
      end
    else
    end
  end
  return lines
end
local function codeaction_line_callback(bufnr)
  do
    local clients = code_action_clients(bufnr)
    if (#clients > 0) then
      local first_line = first_viewport_line()
      local ll = last_viewport_line()
      local ll_cols = line_length_0_indexed(bufnr, ll)
      local buf_uri = vim.uri_from_bufnr(bufnr)
      local context
      local function _53_(d)
        local _54_ = d.lnum
        return (((first_line - 1) <= _54_) and (_54_ <= (ll - 1)))
      end
      context = {diagnostics = vim.lsp.diagnostic.from(vim.tbl_filter(_53_, vim.diagnostic.get(bufnr))), only = {"quickfix"}, triggerKind = 1}
      local seen = {}
      local function _55_(actions)
        for _, line in ipairs(action_lines(actions, buf_uri)) do
          seen[line] = true
        end
        return nil
      end
      local function _56_()
        if nvim_buf_is_valid(bufnr) then
          nvim_buf_clear_namespace(bufnr, ns, 0, -1)
          for line, _ in pairs(seen) do
            nvim_buf_set_extmark(bufnr, ns, line, 0, {sign_text = "\239\130\173", sign_hl_group = "DiagnosticSignWarn", priority = 35})
          end
          return nil
        else
          return nil
        end
      end
      request_all({clients = clients, bufnr = bufnr, context = context, ["start-pos"] = {first_line, 0}, ["end-pos"] = {ll, ll_cols}, ["on-actions"] = _55_, ["on-done"] = _56_})
    else
    end
  end
  return nil
end
local kind_styles = {{prefix = "quickfix", icon = "\239\130\173", hl = "Warn"}, {prefix = "source", icon = "\239\128\147", hl = "Hint"}, {prefix = "refactor", icon = "\238\171\169", hl = "Info"}, {prefix = "gopls", icon = "\238\152\166", hl = "Hint"}}
local default_kind_style = {icon = "\238\169\188", hl = "Warning", rank = (1 + #kind_styles)}
local function kind_style(kind)
  local _59_
  do
    local match1 = nil
    for i, _60_ in ipairs(kind_styles) do
      local prefix = _60_.prefix
      local icon = _60_.icon
      local hl = _60_.hl
      if match1 then break end
      if vim.startswith((kind or ""), prefix) then
        match1 = {icon = icon, hl = hl, rank = i}
      else
        match1 = nil
      end
    end
    _59_ = match1
  end
  return (_59_ or default_kind_style)
end
local function set_winbar_count(bufnr, actions_by_kind)
  if not empty_3f(actions_by_kind) then
    local win = nvim_get_current_win()
    if (nvim_win_get_buf(win) == bufnr) then
      local entries
      do
        local tbl_26_ = {}
        local i_27_ = 0
        for kind, actions in pairs(actions_by_kind) do
          local val_28_ = {n = #actions, style = kind_style(kind)}
          if (nil ~= val_28_) then
            i_27_ = (i_27_ + 1)
            tbl_26_[i_27_] = val_28_
          else
          end
        end
        entries = tbl_26_
      end
      local function _63_(_241, _242)
        return (_241.style.rank < _242.style.rank)
      end
      table.sort(entries, _63_)
      local _64_
      do
        local s = ""
        for _, entry in ipairs(entries) do
          local n = entry.n
          local _let_65_ = entry.style
          local icon = _let_65_.icon
          local hl = _let_65_.hl
          s = (s .. "%#DiagnosticSign" .. hl .. "#" .. icon .. " " .. n .. "%* ")
        end
        _64_ = s
      end
      return nvim_set_option_value("winbar", _64_, {win = win})
    else
      return nil
    end
  else
    return nil
  end
end
local function codeaction_position_callback(bufnr)
  if (nvim_win_get_buf(0) == bufnr) then
    local clients = code_action_clients(bufnr)
    if (#clients == 0) then
      set_winbar_count(bufnr, {})
    else
      local row = current_line()
      local actions = {}
      local function _68_(as)
        for _, a in ipairs(as) do
          table.insert(actions, a)
        end
        return nil
      end
      local function _69_()
        if nvim_buf_is_valid(bufnr) then
          local function _70_(action)
            local case_71_ = string.match(action.kind, "^([^.]*)")
            if (nil ~= case_71_) then
              local key = case_71_
              return key
            else
              return nil
            end
          end
          return set_winbar_count(bufnr, group_by(_70_, actions))
        else
          return nil
        end
      end
      request_all({clients = clients, bufnr = bufnr, context = {triggerKind = 1, diagnostics = M.line_diagnostics(bufnr, row)}, ["on-actions"] = _68_, ["on-done"] = _69_})
    end
  else
  end
  return nil
end
M.line_diagnostics = function(bufnr, row)
  return vim.lsp.diagnostic.from(vim.diagnostic.get(bufnr, {lnum = (row - 1)}))
end
M.code_action = function()
  local bufnr = 0
  local row = current_line()
  local clients = code_action_clients(bufnr)
  local context = {triggerKind = 1, diagnostics = M.line_diagnostics(bufnr, row)}
  local items = {}
  local row_cols = line_length_0_indexed(bufnr, row)
  local gather
  local function _76_(result, context0, keep)
    for _, action in ipairs(result) do
      if keep(action) then
        table.insert(items, {action = action, context = context0})
      else
      end
    end
    return nil
  end
  gather = _76_
  local pending = (#clients * 2)
  local done
  local function _78_()
    pending = (pending - 1)
    if (pending == 0) then
      if (#items == 0) then
        return vim.notify("No code actions available", vim.log.levels.INFO)
      else
        return select_and_apply(items)
      end
    else
      return nil
    end
  end
  done = _78_
  local function _81_(actions, context0)
    gather(actions, context0, quickfix_3f)
    return done()
  end
  request_all({clients = clients, bufnr = bufnr, context = context, ["start-pos"] = {row, 0}, ["end-pos"] = {row, row_cols}, ["on-actions"] = _81_})
  local function _82_(actions, context0)
    local function _83_(_241)
      return not quickfix_3f(_241)
    end
    gather(actions, context0, _83_)
    return done()
  end
  return request_all({clients = clients, bufnr = bufnr, context = context, ["on-actions"] = _82_})
end
M.setup_codeactions = function(bufnr)
  if not vim.b[bufnr].code_action_setup then
    vim.b[bufnr]["code_action_setup"] = true
    local group = nvim_create_augroup(("code_action_bufnr_" .. bufnr), {clear = true})
    local function _84_()
      return codeaction_line_callback(bufnr)
    end
    nvim_create_autocmd({"DiagnosticChanged", "WinScrolled"}, {group = group, buffer = bufnr, callback = debounce(100, _84_)})
    local function _85_()
      return codeaction_position_callback(bufnr)
    end
    nvim_create_autocmd({"CursorHold", "BufEnter", "InsertLeave", "DiagnosticChanged"}, {group = group, buffer = bufnr, callback = _85_})
    local function _86_()
      set_winbar_count(bufnr, {})
      return nil
    end
    return nvim_create_autocmd({"BufLeave"}, {group = group, buffer = bufnr, callback = _86_})
  else
    return nil
  end
end
return M
