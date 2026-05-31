return {
  "nvim-neo-tree/neo-tree.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-tree/nvim-web-devicons",
    "MunifTanjim/nui.nvim",
  },
  version = "*",
  init = function() vim.g.neo_tree_remove_legacy_commands = true end,
  config = function()
    vim.keymap.set("n", "<leader>f", ":Neotree toggle<cr>", { desc = "Toggle Neotree", silent = true })
    vim.keymap.set("n", "|", ":Neotree reveal<cr>", { silent = true })

    require("neo-tree").setup {
      auto_clean_after_session_restore = true,
      close_if_last_window = true,
      sources = { "filesystem", "buffers", "git_status" },
      source_selector = {
        winbar = true,
        content_layout = "center",
      },
      default_component_configs = {
        indent = { padding = 0 },
      },
      window = {
        position = "left",
        width = 40,
        dedicated = true,
        mappings = {
          ["<space>"] = false,
          ["[b"] = "prev_source",
          ["]b"] = "next_source",
        },
        fuzzy_finder_mappings = { -- define keymaps for filter popup window in fuzzy_finder_mode
          ["<C-j>"] = "move_cursor_down",
          ["<C-k>"] = "move_cursor_up",
        },
      },
      filesystem = {
        follow_current_file = { enabled = true },
        hijack_netrw_behavior = "open_current",
        use_libuv_file_watcher = true,
      },
    }
  end,
}
