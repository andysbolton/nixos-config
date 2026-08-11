return {
  "tpope/vim-surround",
  {
    "folke/which-key.nvim",
    config = true,
    event = "VeryLazy",
  },
  {
    "mg979/vim-visual-multi",
    branch = "master",
  },
  {
    "numToStr/Comment.nvim",
    config = function()
      require("Comment").setup()
      local ft = require "Comment.ft"
      -- Formatting for jq files
      ft.jq = "#%s"
    end,
  },
  -- Detect tabstop and shiftwidth automatically
  "tpope/vim-sleuth",
  "romainl/vim-cool",
  {
    "rmagatti/auto-session",
    priority = 100,
    config = function()
      ---@diagnostic disable-next-line: missing-fields
      -- an unguarded :Neotree close would drag the lazy-loaded plugin in
      -- via its cmd trigger on every session save/restore
      local close_neotree = function()
        if package.loaded["neo-tree"] then vim.cmd "Neotree close" end
      end
      require("auto-session").setup {
        log_level = "error",
        -- default (true) registers the telescope session-lens extension at
        -- startup, force-loading the otherwise lazy telescope
        session_lens = { load_on_setup = false },
        pre_save_cmds = {
          close_neotree,
        },
        pre_restore_cmds = {
          close_neotree,
        },
        post_restore_cmds = {
          function()
            if not vim.tbl_contains(vim.v.argv, "DiffviewOpen") then
              require("workspaces").neotree { action = "show" }
            end
          end,
        },
      }
      -- localoptions records each buffer's filetype in the session, so restore
      -- doesn't depend on filetype detection (see nvim-session-restore-ft-poisoning)
      vim.o.sessionoptions = "blank,buffers,curdir,folds,help,tabpages,winsize,winpos,localoptions"
    end,
  },
  {
    "folke/trouble.nvim",
    opts = {},
    cmd = "Trouble",
    keys = {
      {
        "<leader>xx",
        "<cmd>Trouble diagnostics toggle<cr>",
        desc = "Diagnostics (Trouble)",
      },
      {
        "<leader>xX",
        "<cmd>Trouble diagnostics toggle filter.buf=0<cr>",
        desc = "Buffer Diagnostics (Trouble)",
      },
      {
        "<leader>cs",
        "<cmd>Trouble symbols toggle focus=false<cr>",
        desc = "Symbols (Trouble)",
      },
      {
        "<leader>cl",
        "<cmd>Trouble lsp toggle focus=false win.position=right<cr>",
        desc = "LSP Definitions / references / ... (Trouble)",
      },
      {
        "<leader>xL",
        "<cmd>Trouble loclist toggle<cr>",
        desc = "Location List (Trouble)",
      },
      {
        "<leader>xQ",
        "<cmd>Trouble qflist toggle<cr>",
        desc = "Quickfix List (Trouble)",
      },
    },
  },
  {
    "ellisonleao/glow.nvim",
    opts = true,
    cmd = "Glow",
  },
  {
    "ibhagwan/fzf-lua",
    event = "VeryLazy",
    -- optional for icon support
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = {
      lsp = {
        code_actions = {
          previewer = "codeaction_native",
        },
      },
    },
    config = function(_, opts)
      local fzf = require "fzf-lua"
      fzf.setup(opts)
      -- route vim.ui.select (incl. code actions) through fzf-lua
      fzf.register_ui_select {
        winopts = { width = 0.6, height = 0.8 },
      }
    end,
  },
}
