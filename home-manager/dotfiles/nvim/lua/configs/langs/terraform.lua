return {
  name = "terraform",
  ft = { "terraform", "tf", "terraform-vars" },
  ls = {
    name = "terraformls",
    settings = {},
  },
  -- linter = { name = "tflint" },
  formatter = {
    name = "terraformls",
    actions = {
      function()
        vim.lsp.buf.format()
        return nil
      end,
    },
  },
  treesitter = "terraform",
}
