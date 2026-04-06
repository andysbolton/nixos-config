-- [nfnl] fnl/cmds/fmt.fnl
local M = {}
local config_utils = require("configs.util")
local utils = require("utils")
local formatters_by_ft = {}
for _, lang in pairs(config_utils.get_configs()) do
  if (lang.formatter and not (lang.autoinstall == false)) then
    local or_1_ = utils.empty(lang.ft)
    if not or_1_ then
      local function _2_()
        return lang.ft
      end
      or_1_ = (_2_ == 0)
    end
    if or_1_ then
      vim.notify(("No filetypes specified for " .. lang.name .. "."), vim.log.levels.WARN)
    else
      for _0, ft in pairs(lang.ft) do
        formatters_by_ft[ft] = lang.formatter
      end
    end
  else
  end
end
local function get_file_name(path)
  local matches
  do
    local tbl_26_ = {}
    local i_27_ = 0
    for seg in string.gmatch(path, "([^/\\]+)") do
      local val_28_ = seg
      if (nil ~= val_28_) then
        i_27_ = (i_27_ + 1)
        tbl_26_[i_27_] = val_28_
      else
      end
    end
    matches = tbl_26_
  end
  return matches[#matches]
end
local function buf_write_post_callback(ev)
  local formatter = formatters_by_ft[vim.bo.filetype]
  if formatter then
    if formatter.use_lsp then
      vim.lsp.buf.format()
    else
      vim.cmd("FormatWrite")
    end
    vim.notify(("Formatted " .. get_file_name(ev.file) .. " with " .. (formatter.name or "[couldn't find formatter name]") .. ((formatter.use_lsp and " (LSP)") or "") .. " (buf " .. ev.buf .. ")."))
    return nil
  else
    return nil
  end
end
M.register_formatters = function()
  local group = vim.api.nvim_create_augroup("formatting-group", {clear = true})
  return vim.api.nvim_create_autocmd("BufWritePost", {group = group, callback = buf_write_post_callback})
end
return M
