return {
  {
    "olimorris/codecompanion.nvim",
    keys = {
      {
        "<leader>at",
        function() require("codecompanion").toggle_cli() end,
        silent = true,
        desc = "[A]I: [T]oggle Code Companion",
      },
      -- Work sessions never run in the bare root; route through a workspace
      -- farm instead (which carries the shared auto-memory settings).
      {
        "<leader>aw",
        function()
          if vim.uv.cwd() == require("workspaces.core").root() then
            vim.cmd "Telescope workspaces"
            return vim.notify("workspaces: pick a workspace — claude does not run in the root", vim.log.levels.WARN)
          end
          require("codecompanion").toggle_cli()
        end,
        silent = true,
        desc = "[A]I: claude in [w]orkspace",
      },
      {
        "<leader>aa",
        function() require("codecompanion").cli { prompt = true } end,
        mode = { "n", "v" },
        silent = true,
        desc = "[A]I: [a]sk (compose prompt)",
      },
      {
        "<leader>ab",
        function() require("codecompanion").cli("#{this}", { focus = false }) end,
        mode = { "n", "v" },
        silent = true,
        desc = "[A]I: send [b]uffer/selection as context",
      },
      {
        "<leader>af",
        function()
          require("codecompanion").cli("Fix these diagnostics: #{diagnostics}", { focus = false, submit = true })
        end,
        silent = true,
        desc = "[A]I: [f]ix diagnostics",
      },
      {
        "<leader>ae",
        function() require("codecompanion").cli("Explain #{this}", { prompt = true }) end,
        mode = "v",
        silent = true,
        desc = "[A]I: [e]xplain selection",
      },
      {
        "<leader>ao",
        function() require("codecompanion").cli("#{terminal}", { focus = false }) end,
        silent = true,
        desc = "[A]I: send terminal [o]utput",
      },
    },
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
      {
        "MeanderingProgrammer/render-markdown.nvim",
        ft = { "markdown", "codecompanion" },
      },
      "ravitemer/codecompanion-history.nvim",
    },
    config = function()
      local function turn_off_line_numbers(buf)
        local win = vim.fn.bufwinid(buf)
        if win ~= -1 then
          vim.wo[win].number = false
          vim.wo[win].relativenumber = false
        end
      end

      vim.api.nvim_create_autocmd("User", {
        pattern = "CodeCompanionChatOpened",
        callback = function(args) turn_off_line_numbers(args.data.bufnr) end,
      })

      vim.api.nvim_create_autocmd("User", {
        pattern = "CodeCompanionCLIOpened",
        callback = function(args)
          turn_off_line_numbers(args.buf)
          vim.cmd "startinsert"
          vim.api.nvim_create_autocmd("BufEnter", {
            callback = function() vim.cmd "startinsert" end,
            buffer = args.data.bufnr,
          })
        end,
      })

      require("codecompanion").setup {
        opts = {
          log_level = "DEBUG",
        },
        tools = {
          ["insert_edit_into_file"] = {
            opts = {
              require_approval_before = {
                buffer = true,
                file = true,
              },
            },
          },
        },
        extensions = {
          history = {
            enabled = true,
          },
        },
        adapters = {
          acp = {
            claude_code = function()
              return require("codecompanion.adapters").extend("claude_code", {
                commands = {
                  default = {
                    "claude-code-acp",
                  },
                  yolo = {
                    "claude-code-acp",
                    "--yolo",
                  },
                },
              })
            end,
          },
        },
        -- interactions = {
        --   background = { adapter = { name = "opencode" } },
        --   chat = {
        --     tools = { opts = { auto_submit_errors = true } },
        --     adapter = { name = "claude_code" },
        --   },
        --   inline = { adapter = "opencode" },
        --   cmd = { adapter = "opencode" },
        --   cli = {
        --     agent = "opencode",
        --     agents = {
        --       opencode = {
        --         cmd = "opencode",
        --         args = {},
        --         description = "OpenCode CLI",
        --         provider = "terminal",
        --       },
        --     },
        --   },
        -- },
        interactions = {
          cli = {
            agent = "claude_code",
            agents = {
              claude_code = {
                cmd = "claude",
                args = {},
                description = "Claude Code CLI",
                provider = "terminal",
              },
            },
          },
        },
        display = {
          cli = {
            window = {
              layout = "vertical",
              full_height = true,
              width = 0.375,
            },
          },
        },
      }
    end,
  },
  {
    "supermaven-inc/supermaven-nvim",
    event = "InsertEnter",
    config = function()
      require("supermaven-nvim").setup {
        ignore_filetypes = { ["neo-tree-popup"] = true },
      }
    end,
  },
}
