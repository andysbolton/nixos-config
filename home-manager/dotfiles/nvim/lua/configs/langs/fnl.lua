return {
  name = "fennel",
  ft = { "fennel" },
  ls = {
    name = "fennel_language_server",
    settings = {
      fennel = {
        workspace = {
          -- If you are using hotpot.nvim or aniseed,
          -- make the server aware of neovim runtime files.
          library = vim.api.nvim_list_runtime_paths(),
        },
        diagnostics = {
          globals = { "vim" },
        },
      },
    },
  },
  formatter = {
    name = "fnlfmt",
    actions = {
      function()
        return {
          exe = "fnlfmt",
          args = { "--fix" },
          stdin = false,
        }
      end,
    },
    autoinstall = false,
  },
  treesitter = "fennel",
}
