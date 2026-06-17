-- [nfnl] fnl/mappings/init.fnl
local km_set = vim.keymap.set
km_set({"n", "v"}, "<Space>", "<Nop>", {silent = true})
km_set("n", "k", "v:count == 0 ? 'gk' : 'k'", {expr = true, silent = true})
km_set("n", "j", "v:count == 0 ? 'gj' : 'j'", {expr = true, silent = true})
km_set("n", "<A-Down>", ":m .+1<CR>==", {desc = "Move line down", silent = true})
km_set("n", "<A-Up>", ":m .-2<CR>==", {desc = "Move line up", silent = true})
km_set("i", "<A-Down>", "<Esc>:m .+1<CR>==gi", {desc = "Move line down", silent = true})
km_set("i", "<A-Up>", "<Esc>:m .-2<CR>==gi", {desc = "Move line up", silent = true})
km_set("v", "<A-Down>", ":m '>+1<CR>gv=gv", {desc = "Move line down", silent = true})
km_set("v", "<A-Up>", ":m '<-2<CR>gv=gv", {desc = "Move line up", silent = true})
km_set("n", "<leader>o", "o<Esc>k", {silent = true})
km_set("n", "<leader>O", "O<Esc>j", {silent = true})
km_set({"n", "v"}, "<leader>dd", "\"_dd<Esc>", {silent = true})
km_set({"v"}, "<leader>d", "\"_d<Esc>", {silent = true})
km_set({"n"}, "<leader>x", "\"_x<Esc>", {silent = true})
km_set("n", "<leader>xa", ":wa | qa<cr>", {desc = "Write and close all buffers while terminal open", silent = true})
km_set("n", "<leader>w", ":w<cr>", {desc = "[W]rite", silent = true})
km_set("n", "<leader>wa", ":wa<cr>", {desc = "[W]rite [A]ll", silent = true})
km_set("n", "<C-a>", ":normal gg0vG$<cr>", {desc = "Select all text"})
local function _1_()
  return vim.diagnostic.jump({count = 1, float = true})
end
km_set("n", "[d", _1_, {desc = "Go to previous diagnostic message"})
local function _2_()
  return vim.diagnostic.jump({count = -1, float = true})
end
km_set("n", "]d", _2_, {desc = "Go to next diagnostic message"})
km_set("n", "<leader>d", vim.diagnostic.open_float, {desc = "Open floating diagnostic message"})
km_set("n", "<leader>c", ":let @+=expand('%')<cr>", {desc = "[C]opy current buffer name", silent = true})
km_set("n", "<leader>gs", ":Git<CR>")
km_set("n", "<leader>gd", ":Gdiffsplit<CR>")
km_set("n", "<leader>gc", ":Git commit<CR>")
km_set("n", "<leader>gb", ":Git blame<CR>")
km_set("n", "<leader>gm", ":Git mergetool<CR>")
km_set("t", "<M-Space>", "<Esc>b\\<Esc>ei", {desc = "Fish help abbreviation bypass.", silent = true})
vim.opt.diffopt:append("algorithm:patience")
vim.opt.diffopt:append("indent-heuristic")
local function _3_()
  local function _4_(input)
    if ((input ~= "") and (input ~= nil)) then
      local _let_5_ = vim.api.nvim_exec2(input, {output = true})
      local output = _let_5_.output
      vim.fn.setreg(vim.v.register, output)
      vim.fn.histadd("cmd", input)
      vim.api.nvim_echo({{output, "IncSearch"}}, true, {})
      local function _6_()
        return vim.api.nvim_echo({{output, "Normal"}}, true, {})
      end
      return vim.defer_fn(_6_, 200)
    else
      return nil
    end
  end
  return vim.ui.input({prompt = ":", completion = "command"}, _4_)
end
return vim.keymap.set("n", "y:", _3_)
