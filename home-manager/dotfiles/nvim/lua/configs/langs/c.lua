return {
  name = "c",
  ft = { "c" },
  ls = { name = "clangd", settings = { cmd = { "clangd", "--clang-tidy", "--offset-encoding=utf-16" } } },
  formatter = {
    name = "clang-format",
    actions = function()
      local fmt = require "formatter.filetypes.c"
      return fmt.clangformat()
    end,
    autoinstall = false,
  },
  linter = { name = "cpplint" },
  treesitter = "c",
}
