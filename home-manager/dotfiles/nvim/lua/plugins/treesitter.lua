return {
  "nvim-treesitter/nvim-treesitter",
  dependencies = {
    -- possibly readd nvim-treesitter-textobjects
  },
  branch = "main",
  build = ":TSUpdate",
  main = "nvim-treesitter",

  init = function()
    local ensureInstalled = require("configs.util").get_treesitters()
    local default_treesitters = { "vimdoc", "vim", "markdown_inline" }

    for _, v in ipairs(default_treesitters) do
      table.insert(ensureInstalled, v)
    end

    local alreadyInstalled = require("nvim-treesitter.config").get_installed()
    local parsersToInstall = vim
      .iter(ensureInstalled)
      :filter(function(parser) return not vim.tbl_contains(alreadyInstalled, parser) end)
      :totable()

    if #parsersToInstall > 0 then require("nvim-treesitter").install(parsersToInstall) end

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
