-- [nfnl] init.fnl
table.unpack = (table.unpack or unpack)
vim.g.python3_host_prog = (vim.fn.expand("~") .. ".asdf/shims/python")
vim.g.mapleader = " "
vim.g.maplocalleader = " "
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
