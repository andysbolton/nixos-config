return {
  name = "css",
  ft = { "css", "less" },
  ls = {
    name = "cssls",
    settings = {},
  },
  formatter = {
    name = "prettierd",
    actions = {
      function() return require("formatter.filetypes.css").prettierd() end,
    },
  },
  treesitter = "css",
}
