-- [nfnl] fnl/cmds/lsp.fnl
local M = {}
local nvim_create_augroup = vim.api.nvim_create_augroup
local nvim_create_autocmd = vim.api.nvim_create_autocmd
local nvim_win_get_cursor = vim.api.nvim_win_get_cursor
vim.fn.sign_define({{name = "light_bulb_sign", text = "\240\159\146\161", texthl = "LspDiagnosticsDefaultInformation"}})
vim.diagnostic.config({virtual_lines = true, virtual_text = false})
local function buf_request_callback(line, bufnr, response)
  vim.fn.sign_unplace("light_bulb_sign", {buffer = bufnr})
  if ((nil ~= response) and (#response > 0)) then
    return vim.fn.sign_place(0, "light_bulb_sign", "light_bulb_sign", bufnr, {lnum = line, priority = 10})
  else
    return nil
  end
end
local function codeaction_autocmd_callback(client, bufnr)
  local row = table.unpack(nvim_win_get_cursor(0))
  local params = vim.lsp.util.make_range_params(0, client.offset_encoding)
  local _2_
  do
    local tbl_26_ = {}
    local i_27_ = 0
    for _, d in ipairs(vim.diagnostic.get(bufnr, {lnum = (row - 1)})) do
      local val_28_
      do
        local t_3_ = d
        if (nil ~= t_3_) then
          t_3_ = t_3_.user_data
        else
        end
        if (nil ~= t_3_) then
          t_3_ = t_3_.lsp
        else
        end
        val_28_ = t_3_
      end
      if (nil ~= val_28_) then
        i_27_ = (i_27_ + 1)
        tbl_26_[i_27_] = val_28_
      else
      end
    end
    _2_ = tbl_26_
  end
  params.context = {diagnostics = _2_, triggerKind = 1}
  local function _7_(_, response)
    return buf_request_callback(row, bufnr, response)
  end
  client:request("textDocument/codeAction", params, _7_, bufnr)
  return nil
end
M.setup_codeactions = function(client, bufnr)
  local code_action_group = nvim_create_augroup(("code_action_bufnr_" .. bufnr), {clear = true})
  local function _8_()
    return codeaction_autocmd_callback(client, bufnr)
  end
  return nvim_create_autocmd({"CursorHold", "CursorHoldI"}, {group = code_action_group, buffer = bufnr, callback = _8_})
end
return M
