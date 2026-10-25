{
  config,
  lib,
  pkgs,
  ...
}:
{
  programs.claude-code.enable = true;

  programs.claude-code.lspServers = {
    lua = {
      command = lib.getExe pkgs.lua-language-server;
      extensionToLanguage.".lua" = "lua";
    };
    nix = {
      command = lib.getExe pkgs.nixd;
      extensionToLanguage.".nix" = "nix";
    };
    fennel = {
      command = lib.getExe pkgs.fennel-ls;
      extensionToLanguage.".fnl" = "fennel";
    };
    fish = {
      command = lib.getExe pkgs.fish-lsp;
      args = [ "start" ];
      extensionToLanguage.".fish" = "fish";
    };
  };

  programs.claude-code.commands.discuss = ./commands/discuss.md;

  programs.claude-code.context = ./CLAUDE.md;

  programs.claude-code.plugins =
    let
      mkPlugin = import ./plugins/mk-plugin.nix pkgs;
    in
    [
      (mkPlugin ./plugins/notify)
    ]
    ++ lib.optional pkgs.stdenv.hostPlatform.isDarwin (mkPlugin ./plugins/workspace-guard);

  home.activation.claudeLspRecommendations =
    let
      neverPlugins = map (name: "${name}-lsp@claude-plugins-official") (
        lib.attrNames config.programs.claude-code.lspServers
      );
    in
    lib.hm.dag.entryAfter [ "writeBoundary" ]
      # bash
      ''
        state="$HOME/.claude.json"
        if [ -s "$state" ]; then
          new=$(${pkgs.jq}/bin/jq --argjson ids ${lib.escapeShellArg (builtins.toJSON neverPlugins)} '
            .lspRecommendationNeverPlugins |= ((. // []) + $ids | unique)
          ' "$state" 2>/dev/null) || new=""

          if [ -n "$new" ] && [ "$new" != "$(${pkgs.coreutils}/bin/cat "$state")" ]; then
            printf '%s\n' "$new" > "$state"
          fi
        fi
      '';

  home.packages = [
    (pkgs.writeShellScriptBin "hm-claude-statusline" ''
      input=$(cat)
      dir=$(${pkgs.jq}/bin/jq -r '.workspace.current_dir // .cwd' <<<"$input")
      branch=$(${pkgs.git}/bin/git -C "$dir" branch --show-current 2>/dev/null)
      case "$dir" in
        "$HOME") dir="~" ;;
        "$HOME"/*) dir="~''${dir#"$HOME"}" ;;
      esac
      if [ -n "$branch" ]; then
        printf '%s ⎇ %s\n' "$dir" "$branch"
      else
        printf '%s\n' "$dir"
      fi
    '')
  ];

  # Linked directly, not through the store: Claude Code writes settings.json and only
  # resolves one symlink level (anthropics/claude-code#15786).
  home.activation.claudeSettings = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    run ln -sfn ${config.dotfilesPath}/claude/settings.json "$HOME/.claude/settings.json"
  '';
}
