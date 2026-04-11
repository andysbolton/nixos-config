return {
  name = "csharp",
  ft = { "cs" },
  ls = {
    name = "omnisharp",
    settings = {},
  },
  treesitter = "c_sharp",
  formatter = {
    name = "csharpier",
    action = function()
      local util = require "formatter.util"
      return {
        exe = "dotnet",
        args = { "csharpier", util.escape_path(util.get_current_buffer_file_name()) },
        stdin = true,
      }
    end,
  },
}
