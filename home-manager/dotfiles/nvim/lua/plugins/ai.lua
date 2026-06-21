return {
  {
    "olimorris/codecompanion.nvim",
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

      -- Claude Code via the CodeCompanion CLI
      local cli = function(...) return require("codecompanion").cli(...) end

      vim.keymap.set({ "n" }, "<leader>a", function() cli() end, { silent = true, desc = "[A]I: new CLI" })

      vim.keymap.set(
        { "n" },
        "<leader>at",
        function() require("codecompanion").toggle() end,
        { silent = true, desc = "[A]I: [T]oggle Code Companion" }
      )

      vim.keymap.set(
        { "n", "v" },
        "<leader>aa",
        function() cli { prompt = true } end,
        { silent = true, desc = "[A]I: [a]sk (compose prompt)" }
      )

      vim.keymap.set(
        { "n", "v" },
        "<leader>ab",
        function() cli("#{this}", { focus = false }) end,
        { silent = true, desc = "[A]I: send [b]uffer/selection as context" }
      )

      vim.keymap.set(
        "n",
        "<leader>af",
        function() cli("Fix these diagnostics: #{diagnostics}", { focus = false, submit = true }) end,
        { silent = true, desc = "[A]I: [f]ix diagnostics" }
      )

      vim.keymap.set(
        "v",
        "<leader>ae",
        function() cli("Explain #{this}", { prompt = true }) end,
        { silent = true, desc = "[A]I: [e]xplain selection" }
      )

      vim.keymap.set(
        "n",
        "<leader>ao",
        function() cli("#{terminal}", { focus = false }) end,
        { silent = true, desc = "[A]I: send terminal [o]utput" }
      )
    end,
  },
  {
    "supermaven-inc/supermaven-nvim",
    config = function() require("supermaven-nvim").setup {} end,
  },
}
