{
  config,
  lib,
  pkgs,
  pkgs-unstable,
  inputs,
  ...
}:
let
  dotnetSdks = pkgs.dotnetCorePackages.combinePackages [
    pkgs.dotnetCorePackages.sdk_8_0-bin
    # https://github.com/nixos/nixpkgs/issues/464575
    # pkgs.dotnetCorePackages.sdk_9_0-bin
    # pkgs.dotnetCorePackages.sdk_10_0-bin
  ];
in
{
  imports = [
    ./options/shared.nix
    ./modules/fish.nix
    ./modules/lan-mouse.nix
  ];

  home.stateVersion = "25.05";

  # Real-file copy, not home.file: a store symlink trips sshd StrictModes on macOS
  # (group-writable store) and falls back to password auth.
  home.activation.authorizedKeys =
    let
      keysFile = pkgs.writeText "authorized_keys" ''
        ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIK3wN9/LQcWF0pun3XaCnRfNnIiMbJlCxG2tZl3n9I3c andy-ed25519
      '';
    in
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      run install -d -m 700 "$HOME/.ssh"
      run install -m 600 ${keysFile} "$HOME/.ssh/authorized_keys"
    '';

  home.shell.enableFishIntegration = true;
  home.sessionVariables = {
    # DOTNET_HOST_PATH = "${dotnetSdks}/share/dotnet/dotnet";
    # DOTNET_ROOT = "${dotnetSdks}/share/dotnet";
    EDITOR = "nvim";
  };

  xdg = {
    enable = true;
    configFile = {
      nvim.source = config.lib.file.mkOutOfStoreSymlink "${config.dotfilesPath}/nvim";
      "opencode/config.json".source =
        config.lib.file.mkOutOfStoreSymlink "${config.dotfilesPath}/opencode/config.json";
      "starship.toml".source = ./dotfiles/starship.toml;
    };
    # fennel-ls docset: hover docs + completion for the vim/nvim API.
    # Pinned via the flake input; `nix flake update fennel-ls-nvim-docs` to bump.
    dataFile."fennel-ls/docsets/nvim.lua".source = "${inputs.fennel-ls-nvim-docs}/nvim.lua";
  };

  home.file = {
    ".local/bin".source = config.lib.file.mkOutOfStoreSymlink "${config.dotfilesPath}/bin";
    ".wezterm.lua".source = config.lib.file.mkOutOfStoreSymlink "${config.dotfilesPath}/wezterm.lua";
  };

  home.sessionPath = [ "${config.home.homeDirectory}/.local/bin" ];

  home.packages = with pkgs; [
    (sbcl.withPackages (ps: [ ps.swank ]))
    age # simple modern file encryption tool
    bat # cat replacement with syntax highlighting
    bat-extras.core
    delta # syntax-highlighting pager for git diff output
    dig # DNS lookup tool
    docker-compose
    dotnetSdks
    entr # run commands on file change
    fd
    file
    fzf
    gcc
    gnumake
    go
    httpie # user-friendly HTTP client
    hwatch
    jq
    killall
    lazygit
    lf # terminal file manager
    libnatpmp # NAT-PMP client library and tools
    lsd # modern ls replacement
    lua
    luaPackages.fennel
    lynx # terminal web browser
    nh # helper CLI for Nix/Home Manager workflows
    nix-tree
    nixfmt
    nodejs_24 # Node.js runtime — npx for MCP servers & general tooling
    pkgs-unstable.gh
    pkgs-unstable.opencode
    postgresql
    procs # modern ps replacement
    python314
    ripgrep # fast recursive text search tool
    rlwrap # readline wrapper for interactive programs
    roswell # Common Lisp environment manager
    rsync
    sd # sed replacement
    sops # secrets editor/manager
    starship # cross-shell prompt
    speedtest-cli
    tinyxxd
    tokyonight-extras
    tree # recursive directory listing
    unzip
    vesktop
    wezterm
    wget
    whois
    zoxide # smarter cd command
  ];

  programs.claude-code.enable = true;

  # Companion to plan mode: keeps its read-only enforcement but defers the
  # plan-drafting behaviour so the session stays conversational.
  programs.claude-code.commands.discuss = ''
    ---
    description: Discussion mode — in plan mode, defer planning until asked
    ---

    Discussion mode: treat plan mode as read-only conversation. Explore the
    codebase and answer questions conversationally. Defer drafting a plan, and do
    not call ExitPlanMode or steer towards plan approval, until I explicitly ask
    for a plan. If plan mode is not active, remind me to enable it (shift+tab)
    before continuing.
  '';

  # Merge notification hooks (turn finished / waiting for input) into
  # ~/.claude/settings.json without letting nix own the file (so interactive
  # /model, /fast, etc. still persist).
  home.activation.claudeNotifyHooks =
    let
      notifyScript = pkgs.writeShellScript "hm-claude-notify" (
        ''
          input=$(cat)
          sid=$(${pkgs.jq}/bin/jq -r .session_id <<<"$input")
          cwd=$(${pkgs.jq}/bin/jq -r .cwd <<<"$input")
          msg=$(${pkgs.jq}/bin/jq -r '.message // "Needs your attention"' <<<"$input")
          # Session name via the live-session registry (undocumented internals);
          # fall back to the project directory name.
          name=$(${pkgs.jq}/bin/jq -rs --arg sid "$sid" \
            '[.[] | select(.sessionId == $sid) | .name] | first // empty' \
            "$HOME"/.claude/sessions/*.json 2>/dev/null)
          title="Claude Code - ''${name:-''${cwd##*/}}"
        ''
        + (
          if pkgs.stdenv.hostPlatform.isDarwin then
            ''
              # env vars sidestep AppleScript string escaping
              MSG="$msg" TITLE="$title" /usr/bin/osascript -e \
                'display notification (system attribute "MSG") with title (system attribute "TITLE") sound name "Glass"'
            ''
          else
            ''
              ${pkgs.libnotify}/bin/notify-send "$title" "$msg"
              ${pkgs.libcanberra-gtk3}/bin/canberra-gtk-play -f ${pkgs.sound-theme-freedesktop}/share/sounds/freedesktop/stereo/complete.oga
            ''
        )
      );
    in
    lib.hm.dag.entryAfter [ "writeBoundary" ]
      # bash
      ''
        settings="$HOME/.claude/settings.json"
        ${pkgs.coreutils}/bin/mkdir -p "$HOME/.claude"
        [ -s "$settings" ] || echo '{}' > "$settings"

        cmd=${notifyScript}
        new=$(${pkgs.jq}/bin/jq --arg cmd "$cmd" '
          .hooks.Stop |= [ { hooks: [ { type: "command", command: $cmd } ] } ]
          | .hooks.Notification |= [ { hooks: [ { type: "command", command: $cmd } ] } ]
        ' "$settings" 2>/dev/null) || {
          echo "claude-code: settings.json is not valid JSON, skipping hook patch" >&2
          new=""
        }

        if [ -n "$new" ] && [ "$new" != "$(${pkgs.coreutils}/bin/cat "$settings")" ]; then
          printf '%s\n' "$new" > "$settings"
        fi
      '';

  # Statusline showing Claude's cwd + git branch, patched into settings.json
  # the same way as the notify hooks above.
  home.activation.claudeStatusLine =
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
    lib.hm.dag.entryAfter [ "writeBoundary" ]
      # bash
      ''
        settings="$HOME/.claude/settings.json"
        ${pkgs.coreutils}/bin/mkdir -p "$HOME/.claude"
        [ -s "$settings" ] || echo '{}' > "$settings"

        cmd=${statusLineScript}
        new=$(${pkgs.jq}/bin/jq --arg cmd "$cmd" '
          .statusLine = { type: "command", command: $cmd }
        ' "$settings" 2>/dev/null) || {
          echo "claude-code: settings.json is not valid JSON, skipping statusline patch" >&2
          new=""
        }

        if [ -n "$new" ] && [ "$new" != "$(${pkgs.coreutils}/bin/cat "$settings")" ]; then
          printf '%s\n' "$new" > "$settings"
        fi
      '';

  programs.neovim = {
    enable = true;
    sideloadInitLua = true;
    withRuby = false;
    withPython3 = false;
    # All language servers, formatters, linters and debug adapters are
    # managed here via nix (previously a mix of nix and mason.nvim).
    extraPackages = with pkgs; [
      # Runtimes / build tooling needed by various servers & plugins
      cargo
      luaPackages.luarocks
      nodejs_24
      tree-sitter

      # Language servers
      bash-language-server # bashls
      clang-tools # clangd (also provides clang-format)
      clojure-lsp
      dockerfile-language-server # dockerls (docker-langserver)
      fennel-ls # fennel_ls
      fish-lsp
      fsautocomplete
      gopls
      jq-lsp # jqls
      lua-language-server # lua_ls
      marksman
      nixd
      omnisharp-roslyn # omnisharp
      pyright
      svelte-language-server
      terraform-ls # terraformls
      typescript # tsserver, required by ts_ls
      typescript-language-server # ts_ls
      vscode-langservers-extracted # cssls, html, jsonls
      yaml-language-server # yamlls

      # Formatters
      black
      csharpier
      fantomas
      fixjson
      fnlfmt
      gofumpt
      nixfmt
      prettierd
      shfmt
      stylua
      zprint

      # Linters
      cpplint
      markdownlint-cli # markdownlint
      shellcheck

      # Debug adapters
      delve # dlv, used by nvim-dap-go
    ];
  };

  programs.btop.enable = true;
  programs.fish.enable = true;

  programs.tmux = {
    enable = true;
    keyMode = "vi";
    terminal = "tmux-256color";
    plugins = [ pkgs.tmuxPlugins.yank ];
    extraConfig = ''
      set -as terminal-features ",*:RGB"
      set -g copy-mode-match-style 'bg=yellow,fg=black'
      set -g copy-mode-current-match-style 'bg=red,fg=white'

      set -g set-clipboard on
      bind -T copy-mode-vi v send -X begin-selection
      bind -T copy-mode-vi C-v send -X rectangle-toggle
    '';
  };

  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "Andy Bolton";
      };
      core = {
        editor = "nvim";
        longpaths = true;
        pager = "delta";
      };
      interactive = {
        diffFilter = "delta --color-only";
      };
      delta = {
        navigate = true;
        light = false;
        line-numbers = true;
      };
      push = {
        autoSetupRemote = true;
      };
      mergetool = {
        keepBackup = false;
      };
      pull = {
        rebase = false;
      };
    };
  };

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    extraConfig = ''
      Include ~/.ssh/config.local
      ServerAliveInterval 15
      ServerAliveCountMax 4
      TCPKeepAlive yes
    '';
    settings = {
      "*" = { };
      main = {
        hostname = "main.tail4b1b78.ts.net";
        user = "andy";
        identityfile = "~/.ssh/id_ed25519";
      };
      portable = {
        hostname = "portable.tail4b1b78.ts.net";
        user = "andy";
        identityfile = "~/.ssh/id_ed25519";
      };
      work = {
        hostname = "work.tail4b1b78.ts.net";
        user = "andybolton";
        identityfile = "~/.ssh/id_ed25519";
      };
      jetkvm = {
        hostname = "jetkvm.tail4b1b78.ts.net";
        user = "root";
        identityfile = "~/.ssh/id_ed25519";
      };

    };
  };

  programs.onepassword-secrets = {
    enable = true;
    tokenFile = "${config.home.homeDirectory}/.config/opnix/token";
    secrets = {
      ageKey = {
        reference = "op://nix/age-secret-key/password";
        path = ".config/sops/age/keys.txt";
        mode = "0600";
      };
      sshRsa = {
        reference = "op://nix/andy-ssh-rsa/private key";
        path = ".ssh/id_rsa";
        mode = "0600";
      };
      sshRsaPub = {
        reference = "op://nix/andy-ssh-rsa/public key";
        path = ".ssh/id_rsa.pub";
        mode = "0600";
      };
      sshEd25519 = {
        reference = "op://nix/andy-ssh-ed25519/private key?ssh-format=openssh";
        path = ".ssh/id_ed25519";
        mode = "0600";
      };
      sshEd25519Pub = {
        reference = "op://nix/andy-ssh-ed25519/public key";
        path = ".ssh/id_ed25519.pub";
        mode = "0600";
      };
      sshConfig = {
        reference = "op://nix/SSH Config/notesPlain";
        path = ".ssh/config.local";
        mode = "0600";
      };
    };
  };

  stylix.enable = true;
  stylix.autoEnable = true;

  stylix.base16Scheme = "${pkgs.base16-schemes}/share/themes/tokyo-night-moon.yaml";

  stylix.targets.neovim.enable = false;
  stylix.targets.fish.enable = false;
  stylix.targets.waybar.enable = false;
  stylix.targets.gnome.enable = false;
  stylix.targets.gtk.enable = false;
  stylix.targets.eog.enable = false;
  stylix.targets.gnome-text-editor.enable = false;

  stylix.targets.firefox.profileNames = [ "home" ];
  stylix.targets.firefox.colorTheme.enable = true;
}
