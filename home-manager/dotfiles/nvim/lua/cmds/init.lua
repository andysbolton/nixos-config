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
vim.api.nvim_create_user_command("LspLog", view_lsp_logs, {desc = "View LSP logfile."})
local function _2_()
  return vim.cmd(("!rm " .. vim.lsp.log.get_filename()))
end
vim.api.nvim_create_user_command("LspLogClear", _2_, {desc = "Clear LSP logfile."})
local function claude_term_3f(buf)
  return ((vim.bo[buf].buftype == "terminal") and (vim.fn.match((vim.b[buf].term_title or ""), "^[\226\156\179\226\151\144\226\151\145\226\151\146\226\151\147] ") >= 0))
end
local function update_title()
  local _3_
  if vim.iter(vim.api.nvim_list_bufs()):any(claude_term_3f) then
    _3_ = "\226\156\179 "
  else
    _3_ = ""
  end
  vim.o.titlestring = (_3_ .. "nvim " .. vim.fn.fnamemodify(vim.fn.getcwd(), ":~"))
  return nil
end
vim.o.title = true
return vim.api.nvim_create_autocmd({"VimEnter", "DirChanged", "FocusLost", "TermOpen", "TermClose"}, {callback = update_title, group = vim.api.nvim_create_augroup("claude_title", {clear = true})})
