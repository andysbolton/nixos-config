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
    use_lsp = true,
  },
  treesitter = "terraform",
}
