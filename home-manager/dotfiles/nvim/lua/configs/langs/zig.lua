return {
  name = "zig",
  ft = { "zig" },
  ls = {
    name = "zls",
    settings = {},
  },
  formatter = {
    name = "zigfmt",
    actions = {
      function() return require("formatter.filetypes.zig").zigfmt() end,
    },
  },
  treesitter = "zig",
}
