return {
  "mfussenegger/nvim-lint",
  config = function()
    -- Linters are provided by nix (see programs.neovim.extraPackages).
    local linters = require("configs.util").get_linters()

    local filetype_linters = {}
    for _, linter in pairs(linters) do
      for _, filetype in pairs(linter.filetypes or {}) do
        filetype_linters[filetype] = { linter.name }
      end
    end

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
