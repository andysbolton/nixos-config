-- [nfnl] fnl/plugins/lisp.fnl
local function _1_()
  vim.g["conjure#extract#tree_sitter#enabled"] = true
  return nil
end
local function _2_()
  local paredit = require("nvim-paredit")
  local ts_context = require("nvim-paredit.treesitter.context")
  local ts_forms = require("nvim-paredit.treesitter.forms")
  local ts_utils = require("nvim-paredit.treesitter.utils")
  local pair_3f
  local function _3_(node)
    return (node and string.match(node:type(), "_pair$"))
  end
  pair_3f = _3_
  local pair_aware_root
  local function _4_(node, context)
    local result = ts_forms.get_node_root(node, context)
    local guard = 0
    while (pair_3f(result) and (guard < 16)) do
      local nxt = ts_utils.find_root_element_relative_to(result, node)
      if (not nxt or nxt:equal(result)) then
        guard = 99
      else
        result = nxt
        guard = (guard + 1)
      end
    end
    return result
  end
  pair_aware_root = _4_
  local enclosing_form
  local function _6_(node)
    local p = node:parent()
    while pair_3f(p) do
      p = p:parent()
    end
    return p
  end
  enclosing_form = _6_
  local raise
  local function _7_(pick)
    local function _8_()
      local context = ts_context.create_context()
      if context then
        local current = pair_aware_root(pick(context), context)
        if current then
          local parent = enclosing_form(current)
          if (parent and not ts_utils.is_document_root(parent)) then
            local text = vim.treesitter.get_node_text(current, 0)
            local sr, sc, er, ec = parent:range()
            vim.api.nvim_buf_set_text(0, sr, sc, er, ec, vim.fn.split(text, "\n"))
            return vim.api.nvim_win_set_cursor(0, {(sr + 1), sc})
          else
            return nil
          end
        else
          return nil
        end
      else
        return nil
      end
    end
    return _8_
  end
  raise = _7_
  local raise_form
  local function _12_(c)
    return ts_forms.find_nearest_form(c.node, c)
  end
  raise_form = raise(_12_)
  local raise_element
  local function _13_(c)
    return c.node
  end
  raise_element = raise(_13_)
  local function _14_()
    return paredit.cursor.place_cursor(paredit.wrap.wrap_element_under_cursor("(", ")", {placement = "inner_start", mode = "insert"}))
  end
  local function _15_()
    return paredit.cursor.place_cursor(paredit.wrap.wrap_element_under_cursor("(", ")", {placement = "inner_end", mode = "insert"}))
  end
  local function _16_()
    return paredit.cursor.place_cursor(paredit.wrap.wrap_enclosing_form_under_cursor("(", ")", {placement = "innert_start", mode = "insert"}))
  end
  local function _17_()
    return paredit.cursor.place_cursor(paredit.wrap.wrap_enclosing_form_under_cursor("(", ")", {placement = "inner_end", mode = "insert"}))
  end
  return paredit.setup({indent = {enabled = true}, keys = {[">s"] = {paredit.api.slurp_forwards, "Slurp forwards"}, ["<s"] = {paredit.api.slurp_backwards, "Slurp backwards"}, [">b"] = {paredit.api.barf_forwards, "Barf forwards"}, ["<b"] = {paredit.api.barf_backwards, "Barf backwards"}, ["<localleader>rf"] = {raise_form, "[R]aise [f]orm"}, ["<localleader>re"] = {raise_element, "[R]aise [e]lement"}, ["<localleader>wh"] = {_14_, "[W]rap element [h]ead"}, ["<localleader>wt"] = {_15_, "[W]rap element insert [t]ail"}, ["<localleader>weh"] = {_16_, "[W]rap [e]nclosing form insert [h]ead"}, ["<localleader>wet"] = {_17_, "[W]rap [e]nclosing form insert [t]ail"}, ["<("] = false, ["<)"] = false, ["<localleader>O"] = false, ["<localleader>o"] = false, [">("] = false, [">)"] = false}})
end
return {"gpanders/fennel-repl.nvim", "gpanders/nvim-parinfer", "vlime/vlime", {"Olical/conjure", config = _1_}, {"julienvincent/nvim-paredit", config = _2_}}
