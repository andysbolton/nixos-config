-- [nfnl] Compiled from init.fnl by https://github.com/Olical/nfnl, do not edit.
table.unpack = (table.unpack or unpack)
vim.g.python3_host_prog = (vim.fn.expand("~") .. ".asdf/shims/python3")
vim.g.mapleader = " "
vim.g.maplocalleader = " "
vim.g.copilot_no_tab_map = true
vim.o.winborder = "rounded"
local lazypath = (vim.fn.stdpath("data") .. "/lazy/lazy.nvim")
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({"git", "clone", "--filter=blob:none", "https://github.com/folke/lazy.nvim.git", "--branch=stable", lazypath})
else
end
vim.opt.rtp:prepend(lazypath)
do
  local lazy = require("lazy")
  lazy.setup({{import = "plugins"}}, {{change_detection = {notify = false}}})
end
require("mappings")
require("options")
return require("cmds")
