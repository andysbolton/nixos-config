return {
  {
    "zbirenbaum/copilot.lua",
    cmd = "Copilot",
    event = "InsertEnter",
    config = function()
      require("copilot").setup {
        panel = {
          keymap = {
            jump_prev = "N",
            jump_next = "n",
          },
        },
        suggestion = {
          keymap = {
            accept = "<C-j>",
          },
          auto_trigger = true,
          layout = {
            position = "right",
            ratio = 0.4,
          },
        },
        filetypes = {
          yaml = true,
        },
      }
    end,
  },
  {
    "zbirenbaum/copilot-cmp",
    config = function() require("copilot_cmp").setup { auto_trigger = false } end,
  },
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
        vim.notify("win is" .. win)
        if win ~= -1 then
          vim.wo[win].number = false
          vim.wo[win].relativenumber = false
        end
      end

      vim.api.nvim_create_autocmd("FileType", {
        pattern = "codecompanion",
        callback = function(args) turn_off_line_numbers(args.buf) end,
      })

      vim.api.nvim_create_autocmd("User", {
        pattern = "CodeCompanionCLICreated",
        callback = function(args)
          -- print(vim.inspect(args))
          turn_off_line_numbers(args.buf)
          -- vim.keymap.set("t", "jk", [[<C-\><C-n>]], { buffer = args.buf, silent = true })
        end,
      })

      vim.api.nvim_create_autocmd("TermOpen", {
        pattern = "term://*opencode",
        callback = function(args)
          turn_off_line_numbers(args.buf)
          vim.keymap.set("t", "jk", [[<C-\><C-n>]], { buffer = args.buf, silent = true })
        end,
      })

      vim.api.nvim_create_autocmd("User", {
        pattern = "CodeCompanionCLICreated",
        callback = function(args)
          -- print(vim.inspect(args))
          turn_off_line_numbers(args.buf)
          -- vim.keymap.set("t", "jk", [[<C-\><C-n>]], { buffer = args.buf, silent = true })
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
            opencode = function()
              return require("codecompanion.adapters").extend("opencode", {
                defaults = {
                  -- model = "claude-sonnet-4.6",
                },
              })
            end,
          },
        },
        interactions = {
          background = { adapter = { name = "opencode" } },
          chat = {
            tools = { opts = { auto_submit_errors = true } },
            adapter = { name = "mistral", model = "devstral-latest" },
          },
          inline = { adapter = "opencode" },
          cmd = { adapter = "opencode" },
          cli = {
            agent = "opencode",
            agents = {
              opencode = {
                cmd = "opencode",
                args = {},
                description = "OpenCode CLI",
                provider = "terminal",
              },
            },
          },
        },
        display = {
          chat = {
            show_token_count = true,
            show_settings = true,
            show_tools_processing = true,
            window = {
              layout = "vertical",
            },
          },
        },
      }
    end,
  },
}
