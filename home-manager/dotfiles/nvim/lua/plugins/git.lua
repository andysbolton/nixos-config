return {
  "tpope/vim-fugitive",
  "tpope/vim-rhubarb",
  {
    -- Adds git releated signs to the gutter, as well as utilities for managing changes
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPost", "BufNewFile" },
    opts = {
      -- See `:help gitsigns.txt`
      signs = {
        add = { text = "+" },
        change = { text = "~" },
        delete = { text = "_" },
        topdelete = { text = "‾" },
        changedelete = { text = "~" },
      },
      sign_priority = 2,
    },
  },
  "APZelos/blamer.nvim",
  {
    "sindrets/diffview.nvim",
    cmd = { "DiffviewOpen" },
    keys = {
      {
        "<leader>dv",
        function()
          local lib = require "diffview.lib"

          if lib.get_current_view() then
            vim.cmd "DiffviewClose"
          else
            vim.cmd "DiffviewOpen"
          end
        end,
        desc = "Toggle [D]iff[v]iew",
      },
    },
  },
}
