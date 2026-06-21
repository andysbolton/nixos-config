return {
  name = "bash",
  ft = { "sh" },
  ls = {
    name = "bashls",
    settings = {},
  },
  formatter = {
    name = "shfmt",
    actions = {
      function() return require("formatter.filetypes.sh").shfmt() end,
    },
  },
  treesitter = "bash",
}
