#!/usr/bin/env bash

# Make sure file is in a symlinked worktree farm (dotfiles/nvim/lua/workspaces/).

input=$(cat)

file=$(jq -r '.tool_input.file_path // .tool_input.notebook_path // empty' <<<"$input")
case "$file" in
"${WORKTREE_SOURCE_ROOT:-$HOME/smartwyre}/.workspaces/"*) ;;
*) exit 0 ;;
esac

err=$(nvim -l "${XDG_CONFIG_HOME:-$HOME/.config}/nvim/lua/workspaces/guard.lua" "$file" 2>&1) || {
  echo "workspaces guard blocked the edit: $err" >&2
  exit 2
}
