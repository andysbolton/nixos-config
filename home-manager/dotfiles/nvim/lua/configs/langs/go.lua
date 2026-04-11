return {
  name = "go",
  ft = { "go" },
  ls = {
    name = "gopls",
    settings = {
      settings = {
        gopls = {
          usePlaceholders = true,
          analyses = {
            unusedparams = true,
          },
        },
        hints = {
          assignVariableTypes = true,
          compositeLiteralFields = true,
          compositeLiteralTypes = true,
          constantValues = true,
          functionTypeParameters = true,
          parameterNames = true,
          rangeVariableTypes = true,
        },
      },
    },
  },
  formatter = {
    name = "gofumpt",
    actions = {
      function() return require("formatter.filetypes.go").gofumpt() end,
    },
  },
  treesitter = "go",
}
