-- Classification and shared toggle state for sw-workspace farms
-- ($root/.workspaces/*), used by the neo-tree branch badges / B toggle and
-- the telescope pickers.
local M = { hidden = false }

local function read_head(path)
  local head = path .. "/HEAD"
  local f = io.open(head, "r")
  if f then
    local head_contents = f:read "*a"
    f:close()
    local branch = head_contents:match "^ref: refs/heads/(.*)"
    return branch
  end
  return nil
end

local function get_branch(target)
  local git_path = target .. "/.git"
  local git = vim.uv.fs_stat(git_path)

  if not git then return nil end

  -- bare repo
  if git.type == "directory" then return read_head(git_path) end

  -- worktree
  if git.type == "file" then
    local f = io.open(git_path, "r")
    if f then
      local git_contents = f:read "*a"
      f:close()
      return read_head(git_contents:match "^gitdir: ([^\n]*)")
    end
  end

  return nil
end

-- Returns the badge branch, the session name (only for symlinks into a
-- session worktree), and whether the path is inside a workspace farm.
function M.classify(path)
  local workspace_root = path:match "^(.*)/%.workspaces/"
  if not workspace_root then return get_branch(path), nil, false end
  local target = vim.uv.fs_readlink(path)
  if not target then return nil, nil, true end
  return get_branch(target), target:match("^" .. vim.pesc(workspace_root) .. "/([^/]+)/"), true
end

-- Top-level dirs/symlinks under dir that are plain repos (branch, no session).
function M.plain_repos(dir)
  local names = {}
  for name, t in vim.fs.dir(dir) do
    if t == "directory" or t == "link" then
      local branch, session = M.classify(dir .. "/" .. name)
      if branch and not session then names[#names + 1] = name end
    end
  end
  return names
end

-- Reverse-map a resolved realpath back to its symlinked location under the
-- cwd. Only active inside a workspace farm session; nil means "no mapping".
function M.to_cwd_path(path)
  local cwd = vim.uv.cwd()
  if cwd == nil or not cwd:match "/%.workspaces/" or vim.startswith(path, cwd .. "/") then return nil end
  for name, t in vim.fs.dir(cwd) do
    if t == "link" then
      local real = vim.uv.fs_realpath(cwd .. "/" .. name)
      if real and vim.startswith(path, real .. "/") then return cwd .. "/" .. name .. path:sub(#real + 1) end
    end
  end
  return nil
end

-- Show/toggle neo-tree without the "file not in cwd" prompt: with
-- follow_current_file enabled, execute() implies a reveal of the current
-- buffer, which prompts on out-of-cwd (realpath) buffers. Reveal explicitly
-- instead, symlink-mapped and only when the file is inside the cwd.
function M.neotree(args)
  local cwd = vim.uv.cwd()
  local file = vim.api.nvim_buf_get_name(0)
  file = M.to_cwd_path(file) or file
  args = vim.tbl_extend("keep", args, {
    source = "filesystem",
    reveal = false,
    reveal_file = vim.startswith(file, cwd .. "/") and file or nil,
  })
  require("neo-tree.command").execute(args)
end

-- Telescope file_ignore_patterns: base plus, while hidden, the plain repos
-- under the cwd.
function M.ignore_patterns(base)
  local patterns = vim.list_extend({}, base)
  if M.hidden then
    for _, name in ipairs(M.plain_repos(vim.uv.cwd())) do
      patterns[#patterns + 1] = "^" .. vim.pesc(name) .. "/"
    end
  end
  return patterns
end

return M
