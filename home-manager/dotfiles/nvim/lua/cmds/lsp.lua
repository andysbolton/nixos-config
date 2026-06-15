-- [nfnl] fnl/cmds/lsp.fnl
local M = {}
local lsp_util = vim.lsp.util
local buf_request_all = vim.api.buf_request_all
local nvim_buf_clear_namespace = vim.api.nvim_buf_clear_namespace
local nvim_buf_set_extmark = vim.api.nvim_buf_set_extmark
local nvim_create_augroup = vim.api.nvim_create_augroup
local nvim_create_autocmd = vim.api.nvim_create_autocmd
local nvim_create_namespace = vim.api.nvim_create_namespace
local nvim_win_get_cursor = vim.api.nvim_win_get_cursor
vim.fn.sign_define("light_bulb_sign", {text = "\240\159\146\161", texthl = "LspDiagnosticsDefaultInformation"})
vim.diagnostic.config({virtual_lines = true, virtual_text = false})
local function buf_request_callback(line, ns_id, bufnr, res)
  vim.fn.sign_unplace("light_bulb_sign")
  nvim_buf_clear_namespace(bufnr, ns_id, 0, -1)
  local _, value = next(res)
  local result = value.result
  local len
  if (nil ~= result) then
    len = #result
  else
    len = 0
  end
  if (len > 0) then
    local line_num = (line - 1)
    local col_num = 0
    local text = string.format(" %d code actions", len)
    local opts = {virt_text = {{text, "DiagnosticInfo"}}, virt_text_pos = "eol_right_align", priority = 0}
    nvim_buf_set_extmark(bufnr, ns_id, line_num, col_num, opts)
    return vim.fn.sign_place(0, "light_bulb_sign", "light_bulb_sign", bufnr, {lnum = line, priority = 10})
  else
    return nil
  end
end
local function codeaction_autocmd_callback(ns_id, bufnr)
  local line = table.unpack(nvim_win_get_cursor(0))
  local params = lsp_util.make_range_params(0, "utf-8")
  params.context = {diagnostics = vim.diagnostic.get(bufnr, {namespace = ns_id, lnum = line}), triggerKind = vim.lsp.protocol.CodeActionTriggerKind.Invoked}
  local function _3_(res)
    return buf_request_callback(line, ns_id, bufnr, res)
  end
  buf_request_all(bufnr, "textDocument/codeAction", params, _3_)
  return nil
end
M.setup_codeactions = function(bufnr)
  local ns_id = nvim_create_namespace(("code_action_virtual_text_" .. bufnr))
  local code_action_group = nvim_create_augroup(("code_action_bufnr_" .. bufnr), {clear = true})
  local function _4_()
    return bufnr
  end
  return nvim_create_autocmd({"CursorHold", "CursorHoldI", "BufLeave"}, {group = code_action_group, buffer = bufnr, callback = _4_})
end
return M
