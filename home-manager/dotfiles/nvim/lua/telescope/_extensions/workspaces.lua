-- Workspace picker: <CR> opens the selection (or creates a workspace named
-- after the prompt when nothing matches), <C-d> removes with confirmation.
local pickers = require "telescope.pickers"
local finders = require "telescope.finders"
local conf = require("telescope.config").values
local actions = require "telescope.actions"
local action_state = require "telescope.actions.state"

local function make_finder()
  local core = require "workspaces.core"
  local results = {}
  for _, ws in ipairs(core.list()) do
    local parts = { ws.ticket }
    if #ws.claimed > 0 then parts[#parts + 1] = "⎇ " .. table.concat(ws.claimed, " ") end
    results[#results + 1] = { ticket = ws.ticket, line = table.concat(parts, "  ") }
  end

  return finders.new_table {
    results = results,
    entry_maker = function(entry) return { value = entry, display = entry.line, ordinal = entry.line } end,
  }
end

local function workspaces_picker(opts)
  opts = opts or {}
  pickers
    .new(opts, {
      prompt_title = "Workspaces (<CR> open/create, <C-d> remove)",
      finder = make_finder(),
      sorter = conf.generic_sorter(opts),
      attach_mappings = function(prompt_bufnr, map)
        actions.select_default:replace(function()
          local selection = action_state.get_selected_entry()
          local prompt = action_state.get_current_line()
          actions.close(prompt_bufnr)
          if selection then
            require("workspaces").open(selection.value.ticket)
          elseif prompt:match "^[%w-]+$" then
            require("workspaces").open(prompt:upper())
          else
            vim.notify("workspaces: invalid ticket " .. vim.inspect(prompt), vim.log.levels.WARN)
          end
        end)
        map({ "i", "n" }, "<C-d>", function()
          local selection = action_state.get_selected_entry()
          if not selection then return end
          local ticket = selection.value.ticket
          if vim.fn.confirm("Remove workspace " .. ticket .. " (worktrees and farm)?", "&Yes\n&No", 2) ~= 1 then
            return
          end
          local ok, err = pcall(require("workspaces.core").remove, ticket)
          if not ok then
            vim.notify(tostring(err), vim.log.levels.ERROR)
            return
          end
          vim.notify("workspaces: removed " .. ticket)
          actions.close(prompt_bufnr)
          workspaces_picker(opts)
        end)
        return true
      end,
    })
    :find()
end

return require("telescope").register_extension {
  exports = { workspaces = workspaces_picker },
}
