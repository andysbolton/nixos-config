{
  jq,
  neovim-unwrapped,
}:
{
  description = "Claim a workspace worktree before Claude edits a farm repo";
  hooks.PreToolUse.matcher = "Edit|Write|MultiEdit|NotebookEdit";
  runtimeInputs = [
    jq
    neovim-unwrapped
  ];
}
