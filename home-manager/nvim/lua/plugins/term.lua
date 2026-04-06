local start_insert = function()
  if not vim.g.SessionLoad then vim.cmd "startinsert!" end
end

return {
  {
    "akinsho/toggleterm.nvim",
    version = "*",
    config = function()
      require("toggleterm").setup {
        open_mapping = "<F7>",
        terminal_mappings = false,
        insert_mappings = false,
        on_open = start_insert,
      }

      -- Exit terminal mode with <Esc>
      vim.api.nvim_create_autocmd("TermOpen", {
        pattern = "*",
        callback = function(args)
          local filetype = vim.bo[args.buf].filetype
          if filetype == "toggleterm" then
            vim.keymap.set("t", "<Esc>", [[<C-\><C-n>]], { buffer = args.buf, silent = true })
          end
        end,
      })

      -- Quick exit
      -- This interfers when navigating 'less' in the integrated terminal.
      -- vim.keymap.set("t", "jk", [[<C-\><C-n>]], { silent = true })

      -- Enable <C-r> in terminal mode to paste from register, as in normal mode
      vim.keymap.set("t", "<C-r>", function()
        local next_char_code = vim.fn.getchar()
        local next_char = vim.fn.nr2char(next_char_code)
        return [[<C-\><C-n>"]] .. next_char .. "pi"
      end, { expr = true })

      vim.keymap.set(
        { "n", "t" },
        "<leader>tf",
        "<cmd>ToggleTerm direction=float<cr>",
        { silent = true, desc = "[T]oggle [f]oating terminal" }
      )

      vim.keymap.set(
        { "n", "t" },
        "<leader>tf",
        "<cmd>ToggleTerm direction=float<cr>",
        { silent = true, desc = "[T]oggle [f]oating terminal" }
      )

      vim.keymap.set(
        { "n", "t" },
        "<leader>tb",
        "<cmd>ToggleTerm size=10 direction=horizontal<cr>",
        { silent = true, desc = "[T]oggle [b]ottom terminal" }
      )

      vim.keymap.set(
        { "n", "t" },
        "<leader>ts",
        "<cmd>ToggleTerm size=80 direction=vertical<cr>",
        { silent = true, desc = "[T]oggle [s]ide terminal" }
      )
    end,
  },
}
