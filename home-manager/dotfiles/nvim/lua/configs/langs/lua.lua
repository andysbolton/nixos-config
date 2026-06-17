return {
  name = "lua",
  ft = { "lua" },
  ls = {
    name = "lua_ls",
    autoinstall = false,
    settings = {
      Lua = {
        telemetry = { enable = false },
        diagnostics = {
          globals = { "vim" },
        },
        workspace = {
          checkThirdParty = false,
        },
      },
    },
  },
  formatter = {
    name = "stylua",
    autoinstall = false,
    actions = { function() return require("formatter.filetypes.lua").stylua() end },
  },
  treesitter = "lua",
}
