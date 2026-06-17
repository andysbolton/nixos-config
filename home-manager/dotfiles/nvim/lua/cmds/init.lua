-- [nfnl] fnl/cmds/init.fnl
local highlight_group = vim.api.nvim_create_augroup("highlight_on_yank", {clear = true})
local function _1_()
  vim.highlight.on_yank()
  return nil
end
vim.api.nvim_create_autocmd("TextYankPost", {callback = _1_, group = highlight_group, pattern = "*"})
vim.api.nvim_create_user_command("LspInfo", "checkhealth vim.lsp", {desc = "View LSP info"})
local function view_lsp_logs()
  vim.cmd(("tabedit" .. vim.lsp.log.get_filename()))
  local bufnr = vim.api.nvim_get_current_buf()
  local tabnr = vim.api.nvim_get_current_tabpage()
  vim.api.nvim_set_option_value("readonly", true, {buf = bufnr})
  return vim.keymap.set("n", "q", ("<cmd>bdelete! " .. bufnr .. " | tabclose" .. tabnr .. tabnr .. "cr<cr>"), {buffer = bufnr, silent = true, desc = "Close LSP log tab buffer."})
end
return vim.api.nvim_create_user_command("LspLog", view_lsp_logs, {desc = "View LSP logs"})
