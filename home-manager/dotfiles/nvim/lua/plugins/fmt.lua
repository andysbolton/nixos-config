-- [nfnl] fnl/plugins/fmt.fnl
local formatters
do
  local _let_1_ = require("configs.util")
  local get_formatters = _let_1_.get_formatters
  formatters = get_formatters()
end
local formatter_names, filetype_actions
do
  local formatter_names0 = {}
  local filetype_actions0 = {}
  for _, formatter in pairs(formatters) do
    do
      if (formatter.name and (formatter.use_lsp ~= true) and (formatter.autoinstall ~= false)) then
        table.insert(formatter_names0, formatter.name)
      else
      end
    end
    for _0, filetype in pairs((formatter.filetypes or {})) do
      filetype_actions0[filetype] = formatter.actions
    end
  end
  formatter_names, filetype_actions = formatter_names0, filetype_actions0
end
local function _3_()
  local mason_tool_installer = require("mason-tool-installer")
  local _let_4_ = require("formatter.filetypes.any")
  local remove_trailing_whitespace = _let_4_.remove_trailing_whitespace
  local _let_5_ = require("cmds.fmt")
  local register_formatters = _let_5_.register_formatters
  local formatter = require("formatter")
  mason_tool_installer.setup({ensure_installed = {table.unpack(formatter_names)}})
  if (vim.fn.has == "win32") then
    filetype_actions["*"] = remove_trailing_whitespace()
  else
  end
  formatter.setup({logging = true, log_level = vim.log.levels.WARN, filetype = filetype_actions})
  return register_formatters()
end
return {{"mhartington/formatter.nvim", config = _3_, dependencies = {"williamboman/mason.nvim", "WhoIsSethDaniel/mason-tool-installer.nvim"}}}
