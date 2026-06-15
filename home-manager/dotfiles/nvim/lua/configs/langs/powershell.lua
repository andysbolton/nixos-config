return {
  name = "powershell",
  ft = { "ps1" },
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
