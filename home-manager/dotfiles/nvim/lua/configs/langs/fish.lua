-- TODO: all this is untested, need to revisit.
return {
  name = "fish",
  ft = { "fish" },
  ls = {
    name = "fish-lsp",
    settings = {},
  },
  formatter = {
    name = "fishindent",
    actions = {
      function() return require("formatter.filetypes.fish").fishindent() end,
    },
  },
  treesitter = "fish",
}
