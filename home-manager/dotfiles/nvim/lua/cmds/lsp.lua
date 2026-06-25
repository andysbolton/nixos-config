-- [nfnl] fnl/cmds/lsp.fnl
local M = {}
local _local_1_ = require("utils")
local group_by = _local_1_["group-by"]
local head = _local_1_.head
local empty_3f = _local_1_["empty?"]
local debounce = _local_1_.debounce
local tail = _local_1_.tail
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
local function range_builder(context, bufnr, start_pos, end_pos)
  if (((bufnr == start_pos) and (start_pos == end_pos) and (end_pos == nil)) or ((head(start_pos) == head(end_pos)) and (tail(end_pos) == 0))) then
    local function _2_(offset)
      return make_range_params(context, offset)
    end
    return _2_
  else
    local function _3_(offset)
      return make_given_range_params(context, bufnr, start_pos, end_pos, offset)
    end
    return _3_
  end
end
local function request_code_actions(client, bufnr, params, cb)
  local function _5_(err, result, context)
    if err then
      nvim_echo({{("LSP client request failed: " .. err.message), "ErrorMsg"}}, true, {err = true})
    else
    end
    return cb((result or {}), context)
  end
  return client:request("textDocument/codeAction", params, _5_, bufnr)
end
local function request_all(_7_)
  local clients = _7_.clients
  local bufnr = _7_.bufnr
  local make_params = _7_["make-params"]
  local on_actions = _7_["on-actions"]
  local on_done = _7_["on-done"]
  local pending = #clients
  for _, client in ipairs(clients) do
    local params = make_params(client.offset_encoding)
    local function _8_(actions, context)
      on_actions(actions, context)
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
    request_code_actions(client, bufnr, params, _8_)
  end
  return nil
end
local function apply_action(action, _11_)
  local client_id = _11_.client_id
  local bufnr = _11_.bufnr
  local client = vim.lsp.get_client_by_id(client_id)
  local do_apply
  local function _12_(act)
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
  do_apply = _12_
  if (not action.edit and client:supports_method("codeAction/resolve")) then
    local function _16_(err, resolved)
      local function _17_()
        if (err or not resolved) then
          return action
        else
          return resolved
        end
      end
      return do_apply(_17_())
    end
    return client:request("codeAction/resolve", action, _16_, bufnr)
  else
    return do_apply(action)
  end
end
local function select_and_apply(items)
  local function _19_(item)
    local a = item.action
    local _20_
    if a.kind then
      _20_ = ("  [" .. a.kind .. "]")
    else
      _20_ = ""
    end
    return ((a.title or "") .. _20_)
  end
  local function _22_(choice)
    if choice then
      return apply_action(choice.action, choice.context)
    else
      return nil
    end
  end
  return vim.ui.select(items, {prompt = "Code action:", format_item = _19_}, _22_)
end
local function action_lines(actions, buf_uri)
  local seen = {}
  local lines = {}
  local add
  local function _24_(range)
    local line
    do
      local t_25_ = range
      if (nil ~= t_25_) then
        t_25_ = t_25_.start
      else
      end
      if (nil ~= t_25_) then
        t_25_ = t_25_.line
      else
      end
      line = t_25_
    end
    if (line and not seen[line]) then
      table.insert(lines, line)
      seen[line] = true
      return nil
    else
      return nil
    end
  end
  add = _24_
  for _, a in ipairs(actions) do
    local _30_
    do
      local t_29_ = a
      if (nil ~= t_29_) then
        t_29_ = t_29_.kind
      else
      end
      _30_ = t_29_
    end
    if (_30_ == "quickfix") then
      local diagnostics
      local _33_
      do
        local t_32_ = a
        if (nil ~= t_32_) then
          t_32_ = t_32_.diagnostics
        else
        end
        _33_ = t_32_
      end
      diagnostics = (_33_ or {})
      if (#diagnostics > 0) then
        for _0, d in ipairs(diagnostics) do
          add(d.range)
        end
      else
        local edit
        do
          local t_35_ = a
          if (nil ~= t_35_) then
            t_35_ = t_35_.edit
          else
          end
          edit = t_35_
        end
        if edit then
          local _38_
          do
            local t_37_ = edit
            if (nil ~= t_37_) then
              t_37_ = t_37_.changes
            else
            end
            if (nil ~= t_37_) then
              t_37_ = t_37_[buf_uri]
            else
            end
            _38_ = t_37_
          end
          for _0, te in ipairs((_38_ or {})) do
            add(te.range)
          end
          local _42_
          do
            local t_41_ = edit
            if (nil ~= t_41_) then
              t_41_ = t_41_.documentChanges
            else
            end
            _42_ = t_41_
          end
          for _0, dc in ipairs((_42_ or {})) do
            local _45_
            do
              local t_44_ = dc
              if (nil ~= t_44_) then
                t_44_ = t_44_.textDocument
              else
              end
              if (nil ~= t_44_) then
                t_44_ = t_44_.uri
              else
              end
              _45_ = t_44_
            end
            if (_45_ == buf_uri) then
              local _49_
              do
                local t_48_ = dc
                if (nil ~= t_48_) then
                  t_48_ = t_48_.edits
                else
                end
                _49_ = t_48_
              end
              for _1, te in ipairs((_49_ or {})) do
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
local function codeaction_viewport_callback(bufnr)
  do
    local clients = code_action_clients(bufnr)
    if (#clients > 0) then
      local first_line = first_viewport_line()
      local ll = last_viewport_line()
      local ll_cols = line_length_0_indexed(bufnr, ll)
      local buf_uri = vim.uri_from_bufnr(bufnr)
      local context
      local function _55_(d)
        local _56_ = d.lnum
        return (((first_line - 1) <= _56_) and (_56_ <= (ll - 1)))
      end
      context = {diagnostics = vim.lsp.diagnostic.from(vim.tbl_filter(_55_, vim.diagnostic.get(bufnr))), only = {"quickfix"}, triggerKind = 1}
      local seen = {}
      local function _57_(actions)
        for _, line in ipairs(action_lines(actions, buf_uri)) do
          seen[line] = true
        end
        return nil
      end
      local function _58_()
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
      request_all({clients = clients, bufnr = bufnr, ["make-params"] = range_builder(context, bufnr, {first_line, 0}, {ll, ll_cols}), ["on-actions"] = _57_, ["on-done"] = _58_})
    else
    end
  end
  return nil
end
local kind_styles = {{prefix = "quickfix", icon = "\239\130\173", hl = "Warn"}, {prefix = "source", icon = "\239\128\147", hl = "Hint"}, {prefix = "refactor", icon = "\238\171\169", hl = "Info"}, {prefix = "gopls", icon = "\238\152\166", hl = "Hint"}}
local default_kind_style = {icon = "\238\169\188", hl = "Warning", rank = (1 + #kind_styles)}
local function kind_style(kind)
  local _61_
  do
    local found = nil
    for i, _62_ in ipairs(kind_styles) do
      local prefix = _62_.prefix
      local icon = _62_.icon
      local hl = _62_.hl
      if found then break end
      if vim.startswith((kind or ""), prefix) then
        found = {icon = icon, hl = hl, rank = i}
      else
        found = nil
      end
    end
    _61_ = found
  end
  return (_61_ or default_kind_style)
end
local function set_winbar_count(bufnr, actions_by_kind)
  local win = nvim_get_current_win()
  if (not empty_3f(actions_by_kind) and (nvim_win_get_buf(win) == bufnr)) then
    local entries
    do
      local tbl_26_ = {}
      local i_27_ = 0
      for kind, actions in pairs(actions_by_kind) do
        local val_28_ = {count = #actions, style = kind_style(kind)}
        if (nil ~= val_28_) then
          i_27_ = (i_27_ + 1)
          tbl_26_[i_27_] = val_28_
        else
        end
      end
      entries = tbl_26_
    end
    local function _65_(_241, _242)
      return (_241.style.rank < _242.style.rank)
    end
    table.sort(entries, _65_)
    local _66_
    do
      local s = ""
      for _, entry in ipairs(entries) do
        local count = entry.count
        local _let_67_ = entry.style
        local icon = _let_67_.icon
        local hl = _let_67_.hl
        s = (s .. "%#DiagnosticSign" .. hl .. "#" .. icon .. " " .. count .. "%* ")
      end
      _66_ = s
    end
    return nvim_set_option_value("winbar", _66_, {win = win})
  else
    return nvim_set_option_value("winbar", "", {win = win})
  end
end
local function request_code_actions_union(bufnr, on_complete)
  local clients = code_action_clients(bufnr)
  local row = current_line()
  local row_cols = line_length_0_indexed(bufnr, row)
  local context = {triggerKind = 1, diagnostics = M.line_diagnostics(bufnr, row)}
  local seen = {}
  local items = {}
  local gather
  local function _69_(actions, context0)
    for _, action in ipairs(actions) do
      local key = ((action.kind or "") .. (action.title or ""))
      if not seen[key] then
        seen[key] = true
        table.insert(items, {action = action, context = context0})
      else
      end
    end
    return nil
  end
  gather = _69_
  if (#clients == 0) then
    return on_complete(items)
  else
    local pending = (#clients * 2)
    local done
    local function _71_()
      pending = (pending - 1)
      if (pending == 0) then
        return on_complete(items)
      else
        return nil
      end
    end
    done = _71_
    local line_params = range_builder(context, bufnr, {row, 0}, {row, row_cols})
    local cursor_params = range_builder(context)
    local function _73_(actions, context0)
      gather(actions, context0)
      return done()
    end
    request_all({clients = clients, bufnr = bufnr, ["make-params"] = line_params, ["on-actions"] = _73_})
    local function _74_(actions, context0)
      gather(actions, context0)
      return done()
    end
    return request_all({clients = clients, bufnr = bufnr, ["make-params"] = cursor_params, ["on-actions"] = _74_})
  end
end
local function codeaction_line_callback(bufnr)
  if (nvim_win_get_buf(0) == bufnr) then
    local function _76_(items)
      if nvim_buf_is_valid(bufnr) then
        local function _77_(item)
          local case_78_ = string.match((item.action.kind or ""), "^([^.]*)")
          if (nil ~= case_78_) then
            local key = case_78_
            return key
          else
            return nil
          end
        end
        return set_winbar_count(bufnr, group_by(_77_, items))
      else
        return nil
      end
    end
    request_code_actions_union(bufnr, _76_)
  else
  end
  return nil
end
M.line_diagnostics = function(bufnr, row)
  return vim.lsp.diagnostic.from(vim.diagnostic.get(bufnr, {lnum = (row - 1)}))
end
M.code_action = function()
  local function _82_(items)
    if (#items == 0) then
      return vim.notify("No code actions available", vim.log.levels.INFO)
    else
      return select_and_apply(items)
    end
  end
  return request_code_actions_union(0, _82_)
end
M.setup_codeactions = function(bufnr)
  if not vim.b[bufnr].code_action_setup then
    vim.b[bufnr]["code_action_setup"] = true
    local group = nvim_create_augroup(("code_action_bufnr_" .. bufnr), {clear = true})
    local function _84_()
      return codeaction_viewport_callback(bufnr)
    end
    nvim_create_autocmd({"DiagnosticChanged", "WinScrolled"}, {group = group, buffer = bufnr, callback = debounce(100, _84_)})
    local function _85_()
      return codeaction_line_callback(bufnr)
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
