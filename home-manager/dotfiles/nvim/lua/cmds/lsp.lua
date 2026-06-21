-- [nfnl] fnl/cmds/lsp.fnl
local M = {}
local nvim_buf_clear_namespace = vim.api.nvim_buf_clear_namespace
local nvim_buf_get_lines = vim.api.nvim_buf_get_lines
local nvim_buf_is_valid = vim.api.nvim_buf_is_valid
local nvim_buf_set_extmark = vim.api.nvim_buf_set_extmark
local nvim_create_augroup = vim.api.nvim_create_augroup
local nvim_create_autocmd = vim.api.nvim_create_autocmd
local nvim_create_namespace = vim.api.nvim_create_namespace
local ns = nvim_create_namespace("code_action_sign")
M.line_diagnostics = function(bufnr, row)
  return vim.lsp.diagnostic.from(vim.diagnostic.get(bufnr, {lnum = (row - 1)}))
end
local function action_lines(actions, buf_uri)
  local seen = {}
  local lines = {}
  local add
  local function _1_(range)
    local line
    do
      local t_2_ = range
      if (nil ~= t_2_) then
        t_2_ = t_2_.start
      else
      end
      if (nil ~= t_2_) then
        t_2_ = t_2_.line
      else
      end
      line = t_2_
    end
    if (line and not seen[line]) then
      table.insert(lines, line)
      seen[line] = true
      return nil
    else
      return nil
    end
  end
  add = _1_
  for _, a in ipairs(actions) do
    local _7_
    do
      local t_6_ = a
      if (nil ~= t_6_) then
        t_6_ = t_6_.kind
      else
      end
      _7_ = t_6_
    end
    if (_7_ == "quickfix") then
      local diagnostics
      local _10_
      do
        local t_9_ = a
        if (nil ~= t_9_) then
          t_9_ = t_9_.diagnostics
        else
        end
        _10_ = t_9_
      end
      diagnostics = (_10_ or {})
      if (#diagnostics > 0) then
        for _0, d in ipairs(diagnostics) do
          add(d.range)
        end
      else
        local edit
        do
          local t_12_ = a
          if (nil ~= t_12_) then
            t_12_ = t_12_.edit
          else
          end
          edit = t_12_
        end
        if edit then
          local _15_
          do
            local t_14_ = edit
            if (nil ~= t_14_) then
              t_14_ = t_14_.changes
            else
            end
            if (nil ~= t_14_) then
              t_14_ = t_14_[buf_uri]
            else
            end
            _15_ = t_14_
          end
          for _0, te in ipairs((_15_ or {})) do
            add(te.range)
          end
          local _19_
          do
            local t_18_ = edit
            if (nil ~= t_18_) then
              t_18_ = t_18_.documentChanges
            else
            end
            _19_ = t_18_
          end
          for _0, dc in ipairs((_19_ or {})) do
            local _22_
            do
              local t_21_ = dc
              if (nil ~= t_21_) then
                t_21_ = t_21_.textDocument
              else
              end
              if (nil ~= t_21_) then
                t_21_ = t_21_.uri
              else
              end
              _22_ = t_21_
            end
            if (_22_ == buf_uri) then
              local _26_
              do
                local t_25_ = dc
                if (nil ~= t_25_) then
                  t_25_ = t_25_.edits
                else
                end
                _26_ = t_25_
              end
              for _1, te in ipairs((_26_ or {})) do
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
local function buf_request_callback(bufnr, response)
  if nvim_buf_is_valid(bufnr) then
    nvim_buf_clear_namespace(bufnr, ns, 0, -1)
    local buf_uri = vim.uri_from_bufnr(bufnr)
    local lines = action_lines((response or {}), buf_uri)
    for _, line in pairs(lines) do
      nvim_buf_set_extmark(bufnr, ns, line, 0, {sign_text = "\239\131\171", sign_hl_group = "DiagnosticSignError", priority = 15})
    end
    return nil
  else
    return nil
  end
end
local function codeaction_autocmd_callback(client, bufnr)
  local first_line = vim.fn.line("w0")
  local last_line = vim.fn.line("w$")
  local last_line_length = #(nvim_buf_get_lines(bufnr, (last_line - 1), last_line, false)[1] or "")
  local params = vim.lsp.util.make_given_range_params({first_line, 0}, {last_line, last_line_length}, bufnr, client.offset_encoding)
  local function _33_(d)
    local _34_ = d.lnum
    return (((first_line - 1) <= _34_) and (_34_ <= (last_line - 1)))
  end
  params.context = {diagnostics = vim.lsp.diagnostic.from(vim.tbl_filter(_33_, vim.diagnostic.get(bufnr))), only = {"quickfix"}, triggerKind = 1}
  local function _35_(_, response)
    return buf_request_callback(bufnr, response)
  end
  client:request("textDocument/codeAction", params, _35_, bufnr)
  return nil
end
M.setup_codeactions = function(client, bufnr)
  local group = nvim_create_augroup(("code_action_bufnr_" .. bufnr), {clear = true})
  local function _36_()
    return codeaction_autocmd_callback(client, bufnr)
  end
  return nvim_create_autocmd({"DiagnosticChanged", "WinScrolled"}, {group = group, buffer = bufnr, callback = _36_})
end
return M
