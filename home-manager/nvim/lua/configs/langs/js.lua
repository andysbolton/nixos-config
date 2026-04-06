return {
  name = "javascript",
  ft = { "javascript" },
  ls = {
    name = "ts_ls",
    settings = {},
  },
  formatter = {
    name = "prettierd",
    actions = {
      function() return require("formatter.filetypes.javascript").prettierd() end,
    },
  },
  treesitter = "javascript",
}
