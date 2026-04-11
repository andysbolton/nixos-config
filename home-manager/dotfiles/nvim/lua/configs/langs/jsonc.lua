return {
  name = "jsonc",
  ft = { "jsonc" },
  ls = {
    name = "jsonls",
    settings = {},
  },
  formatter = {
    name = "fixjson",
    actions = {
      function() return require("formatter.filetypes.json").fixjson() end,
    },
  },
  treesitter = "jsonc",
}
