return {
  name = "markdown",
  ft = { "markdown" },
  ls = {
    name = "marksman",
    settings = {},
  },
  linter = { name = "markdownlint" },
  formatter = {
    name = "prettierd",
    actions = {
      function() return require("formatter.filetypes.markdown").prettierd() end,
    },
  },
  treesitter = "markdown",
}
