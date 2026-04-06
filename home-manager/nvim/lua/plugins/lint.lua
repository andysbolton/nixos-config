return {
  "mfussenegger/nvim-lint",
  dependencies = { "williamboman/mason.nvim", "WhoIsSethDaniel/mason-tool-installer.nvim" },
  config = function()
    local linters = require("configs.util").get_linters()

    local linter_names = {}
    local filetype_linters = {}
    for _, linter in pairs(linters) do
      table.insert(linter_names, linter.name)
      for _, filetype in pairs(linter.filetypes or {}) do
        filetype_linters[filetype] = { linter.name }
      end
    end

    require("mason-tool-installer").setup {
      ensure_installed = { table.unpack(linter_names) },
    }

    require("lint").linters_by_ft = filetype_linters

    for filetype, _ in pairs(filetype_linters) do
      local formatted_filetype = { "*." .. filetype }
      vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "TextChanged", "InsertLeave" }, {
        pattern = formatted_filetype,
        callback = function() require("lint").try_lint() end,
      })
    end
  end,
}
