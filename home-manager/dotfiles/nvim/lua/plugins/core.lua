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
    "williamboman/mason.nvim",
    config = true,
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
  {
    "alker0/chezmoi.vim",
    lazy = false,
    init = function() vim.g["chezmoi#use_tmp_buffer"] = true end,
  },
  "tpope/vim-sensible",
  -- Detect tabstop and shiftwidth automatically
  "tpope/vim-sleuth",
  "romainl/vim-cool",
  {
    "rmagatti/auto-session",
    config = function()
      ---@diagnostic disable-next-line: missing-fields
      require("auto-session").setup {
        log_level = "error",
        pre_save_cmds = {
          "Neotree close",
        },
        pre_restore_cmds = {
          "Neotree close",
        },
        post_restore_cmds = {
          function()
            if not vim.tbl_contains(vim.v.argv, "DiffviewOpen") then
              require("neo-tree.sources.manager").show "filesystem"
              vim.cmd "Neotree show filesystem"
            end
          end,
        },
      }
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
    -- optional for icon support
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = {
      -- lsp = {
      --   code_actions = {
      --     previewer = "codeaction_native",
      --     preview_pager = "delta --side-by-side --width=$FZF_PREVIEW_COLUMNS --hunk-header-style='omit' --file-style='omit'",
      --   },
      -- },
    },
  },

  -- {
  --   "stevearc/dressing.nvim",
  --   opts = {},
  -- },
}
