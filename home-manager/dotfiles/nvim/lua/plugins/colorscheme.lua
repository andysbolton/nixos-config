-- The active theme's colorscheme plugin, from theme.nix (vim.g.theme). Without one, Stylix sets
-- the colours from init.lua.
local theme = vim.g.theme
if not theme then return {} end

return {
  {
    theme.plugin,
    name = theme.name,
    lazy = false,
    priority = 1000,
    config = function() vim.cmd.colorscheme(theme.colorscheme) end,
  },
}
