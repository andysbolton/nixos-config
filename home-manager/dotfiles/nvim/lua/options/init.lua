-- [nfnl] fnl/options/init.fnl
vim.o.hlsearch = true
vim.wo.number = true
vim.wo.relativenumber = true
vim.o.mouse = "a"
vim.o.clipboard = "unnamedplus"
if (os.getenv("SSH_TTY") or os.getenv("SSH_CONNECTION")) then
  local osc52 = require("vim.ui.clipboard.osc52")
  vim.g.clipboard = {name = "OSC 52", copy = {["+"] = osc52.copy("+"), ["*"] = osc52.copy("*")}, paste = {["+"] = osc52.paste("+"), ["*"] = osc52.paste("*")}}
else
end
do
  local system_open = vim.ui.open
  local function _2_(path, opt)
    local uri, line = path:match("^(file://[^#]*)#?L?(%d*)$")
    if uri then
      if (vim.api.nvim_win_get_config(0).relative ~= "") then
        vim.api.nvim_win_close(0, false)
      else
      end
      vim.cmd.edit(vim.fn.fnameescape(vim.uri_to_fname(uri)))
      if (line ~= "") then
        vim.api.nvim_win_set_cursor(0, {tonumber(line), 0})
      else
      end
      return nil
    else
      return system_open(path, opt)
    end
  end
  vim.ui.open = _2_
end
vim.o.breakindent = true
vim.o.undofile = true
vim.o.ignorecase = true
vim.o.smartcase = true
vim.wo.signcolumn = "auto:2"
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
local function _6_()
  if ((vim.fn.mode() ~= "c") and (vim.bo.buftype ~= "nofile")) then
    return vim.cmd("checktime")
  else
    return nil
  end
end
vim.api.nvim_create_autocmd({"BufEnter", "CursorHold", "CursorHoldI", "FocusGained"}, {pattern = {"*"}, callback = _6_, desc = "Reload buffer on focus/hold unless in command-line window"})
vim.opt.list = true
vim.opt.listchars:append({extends = "\226\128\186", precedes = "\226\128\185", eol = "\226\143\142", trail = "\194\183", nbsp = "\226\142\181", space = " "})
vim.o.scrolloff = 1
vim.o.sidescrolloff = 2
vim.opt.display:append("truncate")
vim.o.mousemoveevent = true
vim.fileformats = "unix"
vim.o.showmode = false
return nil
