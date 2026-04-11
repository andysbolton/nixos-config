return {
  {
    "nvim-telescope/telescope.nvim",
    version = "*",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "BurntSushi/ripgrep",
      "nvim-telescope/telescope-live-grep-args.nvim",
      "benfowler/telescope-luasnip.nvim",
    },
    keys = {
      {
        "<leader>?",
        function() require("telescope.builtin").oldfiles() end,
        desc = "[?] Find recently opened files",
      },
      {
        "<leader><space>",
        function() require("telescope.builtin").buffers() end,
        desc = "[ ] Find existing buffers",
      },
      {
        "<leader>gf",
        function() require("telescope.builtin").git_files() end,
        desc = "Search [G]it [F]iles",
      },
      { "<leader>sf", function() require("telescope.builtin").find_files() end, desc = "[S]earch [F]iles" },
      { "<leader>sh", function() require("telescope.builtin").help_tags() end, desc = "[S]earch [H]elp" },
      {
        "<leader>sw",
        function() require("telescope.builtin").grep_string() end,
        desc = "[S]earch current [W]ord",
      },
      {
        "<leader>sr",
        function() require("telescope.builtin").resume() end,
        desc = "[S]earch [R]esume",
      },
      {
        "<leader>sb",
        function() require("telescope.builtin").buffers() end,
        desc = "[S]earch [B]uffers",
      },
      {
        "<leader>sg",
        ":lua require('telescope').extensions.live_grep_args.live_grep_args()<CR>",
        desc = "[S]earch by [G]rep",
      },
      { "<leader>sd", function() require("telescope.builtin").diagnostics() end, desc = "[S]earch [D]iagnostics" },
      { "<leader>sk", function() require("telescope.builtin").keymaps() end, desc = "[S]earch [K]eymaps" },
      {
        "<leader>ssn",
        function() require("telescope").extensions.luasnip.luasnip {} end,
        desc = "[S]earch [S][n]ippets",
      },
      {
        "<leader>/",
        function()
          require("telescope.builtin").current_buffer_fuzzy_find(require("telescope.themes").get_dropdown {
            winblend = 10,
            previewer = false,
          })
        end,
        desc = "[/] Fuzzily search in current buffer",
      },
    },
    config = function()
      local lga_actions = require "telescope-live-grep-args.actions"
      require("telescope").setup {
        extensions = {
          live_grep_args = {
            file_ignore_patterns = { ".git/" },
            auto_quoting = true,
            mappings = {
              i = {
                ["<C-h>"] = lga_actions.quote_prompt { postfix = " --hidden" },
                ["<C-i>"] = lga_actions.quote_prompt { postfix = " --iglob" },
                ["<C-f>"] = lga_actions.quote_prompt { postfix = " --fixed-strings" },
                ["<C-s>"] = lga_actions.quote_prompt(),
              },
            },
          },
        },
        defaults = {
          mappings = {
            i = {
              ["<C-u>"] = false,
              ["<C-d>"] = false,
            },
          },
        },
        pickers = {
          find_files = {
            file_ignore_patterns = { ".git/" },
            hidden = true,
          },
        },
      }

      require("telescope").load_extension "luasnip"

      -- Enable telescope fzf native, if installed
      pcall(require("telescope").load_extension, "fzf")
    end,
  },
  {
    "nvim-telescope/telescope-fzf-native.nvim",
    build = "make",
    cond = function() return vim.fn.executable "make" == 1 end,
  },
}
