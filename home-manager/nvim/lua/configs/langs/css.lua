return {
  name = "css",
  ft = { "css" },
  ls = {
    name = "cssls",
    settings = {},
  },
  linter = { name = "stylelint" },
  formatter = {
    name = "prettierd",
    actions = {
      function() return require("formatter.filetypes.css").prettierd() end,
    },
  },
  treesitter = "css",
}
