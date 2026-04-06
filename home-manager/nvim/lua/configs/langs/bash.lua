return {
  name = "bash",
  ft = { "sh" },
  ls = {
    name = "bashls",
    settings = {},
  },
  linter = { name = "shellcheck" },
  formatter = {
    name = "shfmt",
    actions = {
      function() return require("formatter.filetypes.sh").shfmt() end,
    },
  },
  treesitter = "bash",
}
