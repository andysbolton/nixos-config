local getflake = string.format([[(builtins.getFlake "%s")]], vim.fn.expand "~/nixos-config")

local options
if vim.uv.os_uname().sysname == "Darwin" then
  local cfg = getflake .. [[.darwinConfigurations."work-darwin"]]
  options = {
    ["nix-darwin"] = { expr = cfg .. ".options" },
    ["home-manager"] = { expr = cfg .. ".options.home-manager.users.type.getSubOptions [ ]" },
  }
else
  local cfg = string.format([[%s.nixosConfigurations."%s"]], getflake, vim.fn.hostname())
  options = {
    nixos = { expr = cfg .. ".options" },
    ["home-manager"] = { expr = cfg .. ".options.home-manager.users.type.getSubOptions [ ]" },
  }
end

return {
  name = "nix",
  ft = { "nix" },
  ls = {
    name = "nixd",
    settings = {
      nixd = {
        nixpkgs = {
          expr = "import " .. getflake .. ".inputs.nixpkgs { }",
        },
        options = options,
      },
    },
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
