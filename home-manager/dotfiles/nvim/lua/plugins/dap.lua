---@diagnostic disable: missing-fields

return {
  "mfussenegger/nvim-dap",
  dependencies = {
    -- Creates a beautiful debugger UI
    { "rcarriga/nvim-dap-ui", dependencies = { "nvim-neotest/nvim-nio" } },

    "leoluz/nvim-dap-go",
    { "jbyuki/one-small-step-for-vimkind", branch = "support-watches" },
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

    vim.keymap.set("n", "<leader>db", require("dap").toggle_breakpoint, { noremap = true })
    vim.keymap.set("n", "<leader>dc", require("dap").continue, { noremap = true })
    vim.keymap.set("n", "<leader>do", require("dap").step_over, { noremap = true })
    vim.keymap.set("n", "<leader>di", require("dap").step_into, { noremap = true })

    vim.keymap.set({ "n", "v" }, "<leader>de", function() require("dapui").eval() end, { desc = "DAP UI: [E]val" })

    vim.keymap.set("n", "<leader>dl", function() require("osv").launch { port = 8086 } end, { noremap = true })

    vim.keymap.set("n", "<leader>dw", function()
      local widgets = require "dap.ui.widgets"
      widgets.hover()
    end)

    vim.keymap.set("n", "<leader>df", function()
      local widgets = require "dap.ui.widgets"
      widgets.centered_float(widgets.frames)
    end)

    vim.keymap.set("n", "<leader>dq", function()
      require("dap").terminate()
      require("dapui").close()
    end, { desc = "Stop Debugging and Close UI" })

    -- Toggle UI windows manually if needed
    vim.keymap.set("n", "<leader>dt", function() require("dapui").toggle() end, { desc = "Toggle DAP UI" })

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
