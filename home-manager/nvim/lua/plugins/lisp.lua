-- [nfnl] fnl/plugins/lisp.fnl
local function _1_()
  vim.g["conjure#extract#tree_sitter#enabled"] = true
  return nil
end
local function _2_()
  local paredit = require("nvim-paredit")
  local function _3_()
    return paredit.cursor.place_cursor(paredit.wrap.wrap_element_under_cursor("(", ")", {placement = "inner_start", mode = "insert"}))
  end
  local function _4_()
    return paredit.cursor.place_cursor(paredit.wrap.wrap_element_under_cursor("(", ")", {placement = "inner_end", mode = "insert"}))
  end
  local function _5_()
    return paredit.cursor.place_cursor(paredit.wrap.wrap_enclosing_form_under_cursor("(", ")", {placement = "innert_start", mode = "insert"}))
  end
  local function _6_()
    return paredit.cursor.place_cursor(paredit.wrap.wrap_enclosing_form_under_cursor("(", ")", {placement = "inner_end", mode = "insert"}))
  end
  return paredit.setup({keys = {[">s"] = {paredit.api.slurp_forwards, "Slurp forwards"}, ["<s"] = {paredit.api.slurp_backwards, "Slurp backwards"}, [">b"] = {paredit.api.barf_forwards, "Barf forwards"}, ["<b"] = {paredit.api.barf_backwards, "Barf backwards"}, ["<localleader>rf"] = {paredit.api.raise_form, "[R]aise [f]orm"}, ["<localleader>re"] = {paredit.api.raise_element, "[R]aise [e]lement"}, ["<localleader>wh"] = {_3_, "[W]rap element [h]ead"}, ["<localleader>wt"] = {_4_, "[W]rap element insert [t]ail"}, ["<localleader>weh"] = {_5_, "[W]rap [e]nclosing form insert [h]ead"}, ["<localleader>wet"] = {_6_, "[W]rap [e]nclosing form insert [t]ail"}, ["<("] = false, ["<)"] = false, ["<localleader>O"] = false, ["<localleader>o"] = false, [">("] = false, [">)"] = false}})
end
return {"gpanders/fennel-repl.nvim", "gpanders/nvim-parinfer", "vlime/vlime", {"julienvincent/nvim-paredit", config = _2_}}
