return {
  name = "html",
  ft = { "html" },
  ls = {
    name = "html",
    settings = {},
  },
  formatter = {
    name = "prettierd",
    actions = {
      function() return require("formatter.filetypes.html").prettierd() end,
    },
  },
  treesitter = "html",
}
