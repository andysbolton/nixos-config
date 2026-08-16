---@diagnostic disable: missing-fields

return {
  "mfussenegger/nvim-dap",
  dependencies = {
    -- Creates a beautiful debugger UI
    { "rcarriga/nvim-dap-ui", dependencies = { "nvim-neotest/nvim-nio" } },

    "leoluz/nvim-dap-go",
    { "jbyuki/one-small-step-for-vimkind", branch = "support-watches" },
  },
  keys = {
    { "<leader>db", function() require("dap").toggle_breakpoint() end },
    { "<leader>dc", function() require("dap").continue() end },
    { "<leader>do", function() require("dap").step_over() end },
    { "<leader>di", function() require("dap").step_into() end },
    { "<leader>de", function() require("dapui").eval() end, mode = { "n", "v" }, desc = "DAP UI: [E]val" },
    { "<leader>dl", function() require("osv").launch { port = 8086 } end },
    { "<leader>dw", function() require("dap.ui.widgets").hover() end },
    {
      "<leader>df",
      function()
        local widgets = require "dap.ui.widgets"
        widgets.centered_float(widgets.frames)
      end,
    },
    {
      "<leader>dq",
      function()
        require("dap").terminate()
        require("dapui").close()
      end,
      desc = "Stop Debugging and Close UI",
    },
    { "<leader>dt", function() require("dapui").toggle() end, desc = "Toggle DAP UI" },
  },
  config = function()
    local dap = require "dap"
    local dapui = require "dapui"

    -- Debug adapters are provided by nix (see programs.neovim.extraPackages);
    -- nvim-dap-go finds `dlv` (delve) on PATH.

    dap.configurations.lua = {
      {
        type = "nlua",
        request = "attach",
        name = "Attach to running Neovim instance",
      },
    }

    dap.adapters.nlua = function(callback, config)
      callback { type = "server", host = config.host or "127.0.0.1", port = config.port or 8086 }
    end

    -- vim.keymap.set("n", "<F5>", dap.continue, { desc = "Debug: Start/Continue" })
    -- vim.keymap.set("n", "<F11>", dap.step_into, { desc = "Debug: Step Into" })
    -- vim.keymap.set("n", "<F10>", dap.step_over, { desc = "Debug: Step Over" })
    -- vim.keymap.set("n", "<F12>", dap.step_out, { desc = "Debug: Step Out" })
    -- vim.keymap.set("n", "<leader>b", dap.toggle_breakpoint, { desc = "Debug: Toggle [B]reakpoint" })
    -- vim.keymap.set(
    --   "n",
    --   "<leader>B",
    --   function() dap.set_breakpoint(vim.fn.input "Breakpoint condition: ") end,
    --   { desc = "Debug: Set Breakpoint Condition" }
    -- )
    --
    -- -- Toggle to see last session result. Without this, you can't see session output in case of a unhandled exception.
    -- vim.keymap.set("n", "<F6>", dapui.toggle, { desc = "Debug: See last session result." })

    dapui.setup {
      icons = { expanded = "▾", collapsed = "▸", current_frame = "*" },
      controls = {
        icons = {
          pause = "⏸",
          play = "▶",
          step_into = "⏎",
          step_over = "⏭",
          step_out = "⏮",
          step_back = "b",
          run_last = "▶▶",
          terminate = "⏹",
          disconnect = "⏏",
        },
      },
    }

    vim.fn.sign_define("DapBreakpoint", { text = "🛑", texthl = "", linehl = "", numhl = "" })
    vim.fn.sign_define("DapStopped", { text = "➡️", texthl = "", linehl = "", numhl = "" })

    dap.listeners.after.event_initialized["dapui_config"] = dapui.open
    dap.listeners.before.event_terminated["dapui_config"] = dapui.close
    dap.listeners.before.event_exited["dapui_config"] = dapui.close

    -- Install golang specific config
    require("dap-go").setup()
  end,
}
