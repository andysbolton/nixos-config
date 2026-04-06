-- [nfnl] fnl/cmds/init.fnl
local highlight_group = vim.api.nvim_create_augroup("highlight_on_yank", {clear = true})
local function _1_()
  vim.highlight.on_yank()
  return nil
end
vim.api.nvim_create_autocmd("TextYankPost", {callback = _1_, group = highlight_group, pattern = "*"})
local function _2_()
  vim.notify("Copilot disabled in exercism directory.")
  vim.cmd("Copilot disable")
  return nil
end
return vim.api.nvim_create_autocmd("BufEnter", {pattern = (vim.fn.expand("~") .. "/exercism/*"), callback = _2_})
