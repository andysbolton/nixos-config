-- [nfnl] fnl/configs/util.fnl
local M = {}
local utils = require("utils")
local language_servers = {}
local formatters = {}
local linters = {}
local treesitters = {}
M.get_configs = function()
  return require("configs")
end
M.get_language_servers = function()
  if utils.empty(language_servers) then
    for _, lang in pairs(M.get_configs()) do
      if lang.ls then
        language_servers[lang.ls.name] = lang.ls
      else
      end
    end
  else
  end
  return language_servers
end
M.get_formatters = function()
  if utils.empty(formatters) then
    for _, lang in pairs(M.get_configs()) do
      if lang.formatter then
        local formatter = lang.formatter
        formatter.filetypes = lang.ft
        table.insert(formatters, formatter)
      else
      end
    end
  else
  end
  return formatters
end
M.get_linters = function()
  if utils.empty(linters) then
    for _, lang in pairs(M.get_configs()) do
      if lang.linter then
        local linter = lang.linter
        linter.filetypes = lang.ft
        table.insert(linters, linter)
      else
      end
    end
  else
  end
  return linters
end
M.get_treesitters = function()
  if utils.empty(treesitters) then
    for _, lang in pairs(M.get_configs()) do
      if lang.treesitter then
        table.insert(treesitters, lang.treesitter)
      else
      end
    end
  else
  end
  return treesitters
end
return M
