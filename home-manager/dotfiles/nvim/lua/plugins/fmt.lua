-- [nfnl] fnl/plugins/fmt.fnl
local function filetype_actions()
  local _let_1_ = require("configs.util")
  local get_formatters = _let_1_.get_formatters
  local actions = {}
  for _, formatter in pairs(get_formatters()) do
    for _0, filetype in pairs((formatter.filetypes or {})) do
      actions[filetype] = formatter.actions
    end
  end
  return actions
end
local function _2_()
  local _let_3_ = require("formatter.filetypes.any")
  local remove_trailing_whitespace = _let_3_.remove_trailing_whitespace
  local _let_4_ = require("cmds.fmt")
  local register_formatters = _let_4_.register_formatters
  local formatter = require("formatter")
  local actions = filetype_actions()
  local function _5_()
    return remove_trailing_whitespace()
  end
  actions["*"] = _5_
  formatter.setup({logging = true, log_level = vim.log.levels.WARN, filetype = actions})
  return register_formatters()
end
return {{"mhartington/formatter.nvim", config = _2_, event = "BufWritePre"}}
