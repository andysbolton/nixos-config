return {
  name = "json",
  ft = { "json" },
  ls = {
    name = "jsonls",
    settings = {},
  },
  formatter = {
    name = "fixjson",
    actions = {
      function()
        local formatter = require("formatter.filetypes.json").fixjson()
        table.insert(formatter.args, "--indent")
        table.insert(formatter.args, "2")
        return formatter
      end,
    },
  },
  treesitter = "json",
}
