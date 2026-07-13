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
        "<leader>gf",
        function() require("telescope.builtin").git_files() end,
        desc = "Search [G]it [F]iles",
      },
      {
        "<leader>sf",
        function()
          require("telescope.builtin").find_files {
            file_ignore_patterns = require("workspaces").ignore_patterns { ".git/" },
          }
        end,
        desc = "[S]earch [F]iles",
      },
      { "<leader>sh", function() require("telescope.builtin").help_tags() end, desc = "[S]earch [H]elp" },
      {
        "<leader>sw",
        function()
          require("telescope.builtin").grep_string {
            file_ignore_patterns = require("workspaces").ignore_patterns {},
          }
        end,
        desc = "[S]earch current [W]ord",
      },
      {
        "<leader>sr",
        function() require("telescope.builtin").resume() end,
        desc = "[S]earch [R]esume",
      },
      {
        "<leader><leader>",
        function() require("telescope.builtin").buffers() end,
        desc = "Search Buffers",
      },
      {
        "<leader>shl",
        function() require("telescope.builtin").highlights() end,
        desc = "[S]earch [H]igh[l]ights",
      },
      {
        "<leader>sg",
        function()
          require("telescope").extensions.live_grep_args.live_grep_args {
            file_ignore_patterns = require("workspaces").ignore_patterns { ".git/" },
          }
        end,
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
      local actions = require "telescope.actions"
      local lga_actions = require "telescope-live-grep-args.actions"

      -- Follow symlinks so grep works in sw-workspace symlink farms;
      -- vimgrep_arguments replaces the defaults, so extend rather than restate
      local vimgrep_arguments = { unpack(require("telescope.config").values.vimgrep_arguments) }
      table.insert(vimgrep_arguments, "--follow")

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
          vimgrep_arguments = vimgrep_arguments,
          mappings = {
            i = {
              ["<C-s>"] = actions.select_vertical,
            },
          },
        },
        pickers = {
          find_files = {
            file_ignore_patterns = { ".git/" },
            hidden = true,
            follow = true,
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
