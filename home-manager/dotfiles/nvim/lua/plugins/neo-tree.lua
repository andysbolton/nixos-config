return {
  "nvim-neo-tree/neo-tree.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-tree/nvim-web-devicons",
    "MunifTanjim/nui.nvim",
  },
  version = "*",
  init = function() vim.g.neo_tree_remove_legacy_commands = true end,
  config = function()
    vim.keymap.set(
      "n",
      "<leader>f",
      function() require("workspaces").neotree { toggle = true } end,
      { desc = "Toggle Neotree", silent = true }
    )
    vim.keymap.set("n", "|", ":Neotree reveal<cr>", { silent = true })

    local directory_renderer = vim.deepcopy(require("neo-tree.defaults").renderers.directory)
    table.insert(directory_renderer, { "git_info" })

    local ws = require "workspaces"

    -- extend get_path_to_reveal to map back to symlink
    -- if realpath is passed in
    local manager = require "neo-tree.sources.manager"
    local get_path_to_reveal = manager.get_path_to_reveal
    manager.get_path_to_reveal = function(...)
      local path = get_path_to_reveal(...)
      if not path then return nil end
      return ws.to_cwd_path(path) or path
    end

    require("neo-tree").setup {
      auto_clean_after_session_restore = true,
      close_if_last_window = true,
      sources = { "filesystem", "buffers", "git_status" },
      source_selector = {
        winbar = true,
        content_layout = "center",
      },
      default_component_configs = {
        indent = { padding = 0 },
      },
      window = {
        position = "left",
        width = 40,
        dedicated = true,
        mappings = {
          ["<space>"] = nil,
          ["[b"] = "prev_source",
          ["]b"] = "next_source",
        },
        fuzzy_finder_mappings = { -- define keymaps for filter popup window in fuzzy_finder_mode
          ["<C-j>"] = "move_cursor_down",
          ["<C-k>"] = "move_cursor_up",
        },
      },
      filesystem = {
        follow_current_file = { enabled = true },
        hijack_netrw_behavior = "open_current",
        use_libuv_file_watcher = true,
        -- Fuzzy finder shells out to fd, which won't descend into the
        -- workspace-farm symlinks without --follow.
        find_args = {
          fd = { "--follow" },
        },
        commands = {
          -- Hide plain repos (branch badge, no ⎇ session).
          toggle_plain_repos = function(state)
            ws.hidden = not ws.hidden

            local never = state.filtered_items.never_show
            for _, name in ipairs(ws.plain_repos(state.path)) do
              never[name] = ws.hidden or nil
            end
            require("neo-tree.sources.manager").refresh "filesystem"
          end,
        },
        window = {
          mappings = { ["B"] = "toggle_plain_repos" },
        },
        components = {
          git_info = function(_, node)
            if node.level > 1 then return {} end
            local branch, session, in_farm = ws.classify(node.path)
            if not branch then return {} end
            if session then
              return {
                text = " ⎇ " .. session .. "  " .. string.gsub(branch, vim.pesc(session .. "/"), ""),
                highlight = "NeoTreeGitStaged",
              }
            end
            return { text = "  " .. branch, highlight = in_farm and "NeoTreeGitAdded" or "NeoTreeRootName" }
          end,
        },
        renderers = { directory = directory_renderer },
      },
    }
  end,
}
