return {
  "nvim-treesitter/nvim-treesitter",
  dependencies = {
    -- possibly readd nvim-treesitter-textobjects
  },
  branch = "main",
  build = ":TSUpdate",
  main = "nvim-treesitter",

  init = function()
    local ensure_installed = require("configs.util").get_treesitters()
    local default_treesitters = { "vimdoc", "vim", "markdown_inline" }

    for _, v in ipairs(default_treesitters) do
      table.insert(ensure_installed, v)
    end

    local already_installed = require("nvim-treesitter.config").get_installed()
    local parsers_to_install = vim
      .iter(ensure_installed)
      :filter(function(parser) return not vim.tbl_contains(already_installed, parser) end)
      :totable()

    if #parsers_to_install > 0 then require("nvim-treesitter").install(parsers_to_install) end

    vim.api.nvim_create_autocmd("FileType", {
      callback = function()
        -- Enable syntax highlighting
        pcall(vim.treesitter.start)

        -- Enable treesitter-based indentation
        vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
      end,
    })
  end,
}
