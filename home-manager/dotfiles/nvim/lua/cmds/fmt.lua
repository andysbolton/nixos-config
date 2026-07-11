-- [nfnl] fnl/cmds/fmt.fnl
local M = {}
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
  vim.cmd("FormatWrite")
  vim.notify(("Formatted " .. get_file_name(ev.file) .. " buf (" .. ev.buf .. ")."))
  return nil
end
M.register_formatters = function()
  local group = vim.api.nvim_create_augroup("formatting-group", {clear = true})
  return vim.api.nvim_create_autocmd("BufWritePost", {group = group, callback = buf_write_post_callback})
end
return M
