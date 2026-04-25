return {
  name = "nix",
  ft = { "nix" },
  ls = {
    name = "nil_ls",
    settings = {},
  },
  formatter = {
    name = "nixfmt",
    autoinstall = false,
    actions = {
      function() return require("formatter.filetypes.nix").nixfmt() end,
    },
  },
  treesitter = "nix",
}
