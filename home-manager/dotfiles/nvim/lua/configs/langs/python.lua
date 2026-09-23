return {
  name = "python",
  ft = { "python" },
  ls = {
    name = "basedpyright",
    settings = {},
  },
  formatter = {
    name = "black",
    actions = {
      function() return require("formatter.filetypes.python").black() end,
    },
  },
  treesitter = "python",
}
