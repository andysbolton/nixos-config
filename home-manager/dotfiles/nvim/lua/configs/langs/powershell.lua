return {
  name = "powershell",
  ft = { "ps1" },
  ls = {
    name = "powershell_es",
    settings = {},
  },
  formatter = {
    name = "powershell_es",
    actions = {
      function()
        vim.lsp.buf.format()
        return nil
      end,
    },
    autoinstall = false,
  },
}
