-- [nfnl] fnl/plugins/fmt.fnl
local formatters
do
  local _let_1_ = require("configs.util")
  local get_formatters = _let_1_.get_formatters
  formatters = get_formatters()
end
local filetype_actions
do
  local filetype_actions0 = {}
  for _, formatter in pairs(formatters) do
    for _0, filetype in pairs((formatter.filetypes or {})) do
      filetype_actions0[filetype] = formatter.actions
    end
  end
  filetype_actions = filetype_actions0
end
local function _2_()
  local _let_3_ = require("formatter.filetypes.any")
  local remove_trailing_whitespace = _let_3_.remove_trailing_whitespace
  local _let_4_ = require("cmds.fmt")
  local register_formatters = _let_4_.register_formatters
  local formatter = require("formatter")
  local function _5_()
    return remove_trailing_whitespace()
  end
  filetype_actions["*"] = _5_
  formatter.setup({logging = true, log_level = vim.log.levels.WARN, filetype = filetype_actions})
  return register_formatters()
end
return {{"mhartington/formatter.nvim", config = _2_}}
