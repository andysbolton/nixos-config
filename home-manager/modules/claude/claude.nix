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

  # Provided so claude-mem doesn't download its own binaries.
  home.packages = [
    pkgs.bun
    pkgs.uv
  ];

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

  programs.claude-code.settings =
    let
      statusLineScript = pkgs.writeShellScript "hm-claude-statusline" ''
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
      '';
    in
    {
      model = "opus";
      effortLevel = "high";
      modelSettings.claude-opus-5-5.effortLevel = "medium";
      skipWorkflowUsageWarning = true;
      theme = "dark";
      editorMode = "vim";
      # Not programs.claude-code.plugins/marketplaces: claude-mem runs `bun install`
      # in its plugin root, and HM's known_marketplaces.json symlink is read-only.
      extraKnownMarketplaces.thedotmack.source = {
        source = "directory";
        path = "${pkgs.fetchFromGitHub {
          owner = "thedotmack";
          repo = "claude-mem";
          tag = "v15.2.0";
          hash = "sha256-K7kN0sulwKKDEZwhOZjNbb50fbCxtsTGkUyzRn7qnGA=";
        }}";
      };
      enabledPlugins."claude-mem@thedotmack" = true;
      env.CLAUDE_MEM_TELEMETRY = "0";
      statusLine = {
        type = "command";
        command = "${statusLineScript}";
      };
    };
}
