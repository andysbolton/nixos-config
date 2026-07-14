-- Workspace mechanics. A workspace ($root/.workspaces/<TICKET>/) holds one
-- entry per repo: a symlink to the main clone (unclaimed, read-only) until
-- the first write, at which point it is replaced in place by a git worktree
-- (claimed). `ls -l` is the status display: symlink = unclaimed, real dir =
-- claimed. Headless-safe (vim.uv/vim.fs/vim.system only) so the guard can
-- drive it via `nvim -l workspaces/guard.lua`.
local M = {}

local uv = vim.uv

function M.root() return vim.env.WORKTREE_SOURCE_ROOT or (uv.os_homedir() .. "/smartwyre") end

function M.farm_path(ticket) return M.root() .. "/.workspaces/" .. ticket end

-- fs_stat follows symlinks; fs_lstat does not. Use lstat to tell an unclaimed
-- symlink ("link") from a claimed worktree ("directory") at the same path.
local function is_dir(path)
  local st = uv.fs_stat(path)
  return st and st.type == "directory"
end

local function lstat_type(path)
  local st = uv.fs_lstat(path)
  return st and st.type
end

local function git(clone, args)
  local result = vim.system(vim.list_extend({ "git", "-C", clone }, args), { text = true }):wait()
  if result.code ~= 0 then
    error(("workspaces: git %s failed in %s: %s"):format(table.concat(args, " "), clone, result.stderr or ""), 0)
  end
  return vim.trim(result.stdout or "")
end

-- Top-level main clones under root (dirs whose .git is itself a directory;
-- worktrees have a .git file).
function M.main_clones()
  local names = {}
  for name, t in vim.fs.dir(M.root()) do
    if t == "directory" and not name:match "^%." and is_dir(M.root() .. "/" .. name .. "/.git") then
      names[#names + 1] = name
    end
  end
  table.sort(names)
  return names
end

-- Repos claimed in a workspace: farm entries that are real worktree dirs
-- (a real directory carrying a .git file), not symlinks to main clones.
function M.claimed(ticket)
  local names = {}
  local farm = M.farm_path(ticket)
  if is_dir(farm) then
    for name, t in vim.fs.dir(farm) do
      if t == "directory" and uv.fs_stat(farm .. "/" .. name .. "/.git") then names[#names + 1] = name end
    end
  end
  table.sort(names)
  return names
end

-- Context file that coding agents load from the farm cwd; how Claude learns
-- the layout without any agent-specific configuration beyond the guard hook.
local function write_context(ticket, farm)
  local guard = vim.fn.stdpath "config" .. "/lua/workspaces/guard.lua"
  local f = assert(io.open(farm .. "/CLAUDE.md", "w"))
  f:write(([[
# Workspace %s

Generated workspace directory (nvim workspaces plugin; this file is
regenerated, don't edit). Each top-level entry is one repo, in one of two
states you can read off `ls -l`:

- **symlink** to the main clone — unclaimed, treat as read-only; or
- **real directory** — a git worktree on branch `%s`, claimed and editable.

Your first Edit/Write in an unclaimed repo claims it automatically (a hook
replaces the symlink with a worktree in place) — just edit normally. For more
than one branch against this ticket, `git switch -c <branch>` inside a claimed
worktree, or `git worktree add ./<repo>-<name> <branch>` for a second copy.

One rule: don't create or modify files with shell commands (sed, tee, git
apply, scripts) in an *unclaimed* repo — only Edit/Write tools trigger the
claim, so a shell write would land in the shared main clone. Either edit a
file with Edit/Write first, or claim explicitly with
`nvim -l %s <path-to-any-file-in-the-repo>`, then shell freely.
]]):format(ticket, ticket, guard))
  f:close()
end

-- Ensure the farm exists and every main clone has an entry: a symlink where
-- nothing is claimed yet, left untouched where a worktree already stands.
-- Idempotent; never disturbs a claimed worktree.
function M.sync(ticket)
  local farm = M.farm_path(ticket)
  vim.fn.mkdir(farm, "p")
  for _, name in ipairs(M.main_clones()) do
    local entry = farm .. "/" .. name
    if lstat_type(entry) == nil then assert(uv.fs_symlink(M.root() .. "/" .. name, entry, { dir = true })) end
  end
  write_context(ticket, farm)
  return farm
end

-- Farm path -> ticket, repo, claimed?. nil when the path isn't inside a farm
-- repo under root (top-level farm files like CLAUDE.md don't count).
function M.parse(path)
  local ticket, repo = path:match("^" .. vim.pesc(M.root()) .. "/%.workspaces/([^/]+)/([^/]+)/")
  if not ticket then return nil end
  return ticket, repo, lstat_type(M.farm_path(ticket) .. "/" .. repo) == "directory"
end

-- Replace a repo's symlink with a worktree in place, on a branch named after
-- the workspace (created from the main clone's current HEAD, matching what
-- was read through the symlink; reused if it already exists).
function M.claim(ticket, repo)
  local clone = M.root() .. "/" .. repo
  if not is_dir(clone .. "/.git") then error(("workspaces: %s is not a main clone"):format(clone), 0) end
  local farm = M.farm_path(ticket)
  vim.fn.mkdir(farm, "p")
  local entry = farm .. "/" .. repo
  if lstat_type(entry) == "directory" then return entry end -- already claimed
  if lstat_type(entry) == "link" then assert(uv.fs_unlink(entry)) end
  local branch = ticket
  local exists = vim.system({ "git", "-C", clone, "rev-parse", "--verify", "--quiet", "refs/heads/" .. branch }):wait()
  if exists.code == 0 then
    git(clone, { "worktree", "add", entry, branch })
  else
    git(clone, { "worktree", "add", "-b", branch, entry })
  end
  return entry
end

function M.list()
  local workspaces = {}
  local dir = M.root() .. "/.workspaces"
  if is_dir(dir) then
    for name, t in vim.fs.dir(dir) do
      if t == "directory" then workspaces[#workspaces + 1] = { ticket = name, claimed = M.claimed(name) } end
    end
  end
  table.sort(workspaces, function(a, b) return a.ticket < b.ticket end)
  return workspaces
end

-- The main working tree backing a worktree, so `git worktree remove` can run
-- from there (a worktree can't remove itself). Handles sibling worktrees
-- (`<repo>-<name>`) whose dir name doesn't match any main clone.
local function main_worktree(worktree)
  local line = git(worktree, { "worktree", "list", "--porcelain" }):match "^worktree ([^\n]*)"
  return line
end

-- `git worktree remove` refuses a worktree with a *populated* submodule (its
-- working dir has contents) but is fine with a declared-but-empty one. Check
-- the filesystem so removal aborts up front rather than failing mid-teardown.
local function populated_submodule(worktree)
  local mods = vim.system(
    { "git", "-C", worktree, "config", "-f", ".gitmodules", "--get-regexp", "path" },
    { text = true }
  ):wait()
  for line in (mods.stdout or ""):gmatch "[^\n]+" do
    local sub = line:match "%S+%s+(%S+)"
    if sub then
      for _ in vim.fs.dir(worktree .. "/" .. sub) do
        return true
      end
    end
  end
  return false
end

function M.remove(ticket)
  local farm = M.farm_path(ticket)
  local claimed = M.claimed(ticket)
  local blocked = {}
  for _, repo in ipairs(claimed) do
    local worktree = farm .. "/" .. repo
    local status = vim.system({ "git", "-C", worktree, "status", "--porcelain" }, { text = true }):wait()
    if status.code ~= 0 or vim.trim(status.stdout or "") ~= "" then
      blocked[#blocked + 1] = repo .. " (dirty)"
    elseif populated_submodule(worktree) then
      blocked[#blocked + 1] = repo .. " (populated submodule)"
    end
  end
  if #blocked > 0 then
    error(("workspaces: cannot remove %s: %s"):format(ticket, table.concat(blocked, ", ")), 0)
  end
  for _, repo in ipairs(claimed) do
    local worktree = farm .. "/" .. repo
    git(main_worktree(worktree), { "worktree", "remove", worktree })
  end
  vim.fs.rm(farm, { recursive = true, force = true })
end

return M
