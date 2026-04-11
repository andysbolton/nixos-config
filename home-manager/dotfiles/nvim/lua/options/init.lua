-- [nfnl] fnl/options/init.fnl
vim.o.hlsearch = true
vim.wo.number = true
vim.wo.relativenumber = true
vim.o.mouse = "a"
vim.o.clipboard = "unnamedplus"
vim.o.breakindent = true
vim.o.undofile = true
vim.o.ignorecase = true
vim.o.smartcase = true
vim.wo.signcolumn = "yes"
vim.o.updatetime = 250
vim.o.timeout = true
vim.o.timeoutlen = 300
vim.o.completeopt = "menuone,noselect"
vim.o.termguicolors = true
vim.o.splitbelow = true
vim.o.splitright = true
vim.o.tabstop = 4
vim.o.shiftwidth = 4
vim.o.softtabstop = 4
vim.o.expandtab = true
vim.o.autoread = true
vim.api.nvim_create_autocmd({"BufEnter", "CursorHold", "CursorHoldI", "FocusGained"}, {command = "if mode() != 'c' | checktime | endif", pattern = {"*"}})
vim.opt.list = true
vim.opt.listchars:append({extends = "\226\128\186", precedes = "\226\128\185", eol = "\226\143\142", trail = "\194\183", nbsp = "\226\142\181", space = " "})
vim.o.mousemoveevent = true
vim.fileformats = "unix"
return nil
