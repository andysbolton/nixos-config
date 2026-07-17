local start_insert = function(term)
  vim.api.nvim_buf_set_keymap(term.bufnr, "n", "q", "<cmd>close<CR>", { noremap = true, silent = true })
end

return {
  {
    "akinsho/toggleterm.nvim",
    version = "*",
    config = function()
      require("toggleterm").setup {
        open_mapping = "<F7>",
        terminal_mappings = false,
        insert_mappings = false,
        on_open = start_insert,
        start_in_insert = true,
        persist_mode = false,
      }

      -- Exit terminal mode with <Esc>
      vim.api.nvim_create_autocmd("TermOpen", {
        pattern = "*",
        callback = function(args)
          vim.opt_local.timeoutlen = 200
          vim.keymap.set("t", "<M-j>", [[<C-\><C-n>]], { buffer = args.buf, silent = true })
          vim.keymap.set("t", "<Esc><Esc>", [[<C-\><C-n>]], { buffer = args.buf, silent = true })
        end,
      })

      vim.keymap.set("t", "<C-r>", function()
        local key = vim.fn.getcharstr()
        if vim.fn.keytrans(key):lower() == "<c-r>" then
          return "<C-r>" -- pass through to fish reverse-search
        end
        return [[<C-\><C-n>"]] .. key .. "pi"
      end, { expr = true })

      -- When a bottom terminal is open, force it full-width along the bottom so neo-tree
      -- can't keep full height, then reclaim the CodeCompanion CLI's full-height right
      -- column. No-op when no bottom terminal is open.
      local function realign_bottom()
        local term
        for _, t in ipairs(require("toggleterm.terminal").get_all()) do
          if t:is_open() and t.direction == "horizontal" then -- by direction, not id
            term = t.window
            break
          end
        end
        if not term then return end
        vim.api.nvim_win_call(term, function() vim.cmd "wincmd J" end)
        local cli = require("codecompanion.interactions.cli").get_visible()
        if cli then vim.api.nvim_win_call(cli.ui.winnr, function() vim.cmd "wincmd L" end) end
      end

      -- Work around neovim's terminal redraw bug: resizing a window that holds a
      -- running TUI can leave stale/blank rows that :redraw! won't clear. A real
      -- resize round-trip after the layout settles forces a clean repaint.
      local function repaint_cli()
        local ok, cli_mod = pcall(require, "codecompanion.interactions.cli")
        if not ok then return end
        local cli = cli_mod.get_visible()
        if not cli then return end
        local win = cli.ui.winnr
        if not (win and vim.api.nvim_win_is_valid(win)) then return end
        local w = vim.api.nvim_win_get_width(win)
        if w <= 2 then return end
        vim.api.nvim_win_set_width(win, w - 1)
        vim.schedule(function()
          if vim.api.nvim_win_is_valid(win) then vim.api.nvim_win_set_width(win, w) end
        end)
      end

      vim.keymap.set({ "n", "t" }, "<leader>tb", function()
        vim.cmd "ToggleTerm size=10 direction=horizontal"
        realign_bottom()
        vim.schedule(repaint_cli)
      end, { silent = true, desc = "[T]oggle [b]ottom terminal" })

      -- Opening/re-toggling neo-tree while the terminal is up would let it reclaim full
      -- height; re-align after it settles.
      vim.api.nvim_create_autocmd("FileType", {
        pattern = "neo-tree",
        callback = function()
          vim.schedule(function()
            realign_bottom()
            repaint_cli()
          end)
        end,
      })

      vim.keymap.set(
        { "v" },
        "ts",
        "<cmd>ToggleTermSendVisualSelection<cr>",
        { silent = true, desc = "[T]erminal [s]end visual selection" }
      )
    end,
  },
}
