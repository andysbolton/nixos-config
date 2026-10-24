{
  config,
  lib,
  pkgs,
  pkgs-unstable,
  inputs,
  osConfig,
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
    ./modules/claude/claude.nix
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

  home.file.".digrc".text = ''
    +search
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
      # Battery levels mirror waybar's battery states.
      "starship.toml".source = (pkgs.formats.toml { }).generate "starship.toml" (
        lib.recursiveUpdate (fromTOML (builtins.readFile ./dotfiles/starship.toml)) {
          battery.display = with osConfig.theme.css; [
            {
              threshold = 10;
              style = "bold ${ERROR}";
            }
            {
              threshold = 20;
              style = "bold ${ATTENTION}";
            }
            {
              threshold = 60;
              style = "bold ${WARN}";
            }
          ];
        }
      );
    };
    # fennel-ls docset: hover docs + completion for the vim/nvim API.
    # Pinned via the flake input; `nix flake update fennel-ls-nvim-docs` to bump.
    dataFile."fennel-ls/docsets/nvim.lua".source = "${inputs.fennel-ls-nvim-docs}/nvim.lua";
  };

  home.packages = with pkgs; [
    (sbcl.withPackages (ps: [ ps.swank ]))
    age # simple modern file encryption tool
    bandwhich
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
    iperf
    jo
    jq
    kakoune
    killall
    lazygit
    lf # terminal file manager
    libnatpmp # NAT-PMP client library and tools
    lsd # modern ls replacement
    lua
    luaPackages.fennel
    lynx # terminal web browser
    mdcat
    nh # helper CLI for Nix/Home Manager workflows
    nix-tree
    nixfmt
    nodejs_24 # Node.js runtime — npx for MCP servers & general tooling
    ookla-speedtest
    pkgs-unstable.gh
    pkgs-unstable.opencode
    postgresql
    procs # modern ps replacement
    python314
    ripgrep # fast recursive text search tool
    rlwrap # readline wrapper for interactive programs
    roswell # Common Lisp environment manager
    rsync
    ruby
    sd # sed replacement
    sshpass
    sops # secrets editor/manager
    starship # cross-shell prompt
    tinyxxd
    tokyonight-extras
    tree # recursive directory listing
    unzip
    vesktop
    wget
    whois
  ];

  programs = {
    direnv = {
      enable = true;
      nix-direnv.enable = true;
    };

    neovim = {
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
        basedpyright
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
        svelte-language-server
        terraform-ls # terraformls
        typescript # tsserver, required by ts_ls
        typescript-language-server # ts_ls
        vscode-langservers-extracted # cssls, html, jsonls
        yaml-language-server # yamlls
        zls

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
    btop.enable = true;
    fish.enable = true;
    tmux = {
      enable = true;
      keyMode = "vi";
      terminal = "tmux-256color";
      plugins = [ pkgs.tmuxPlugins.yank ];
      extraConfig = ''
        set -as terminal-features ",*:RGB"
        set -g copy-mode-match-style 'bg=yellow,fg=black' set -g copy-mode-current-match-style 'bg=red,fg=white'

        set -g set-clipboard on
        bind -T copy-mode-vi v send -X begin-selection
        bind -T copy-mode-vi C-v send -X rectangle-toggle

        bind h select-pane -L
        bind j select-pane -D
        bind k select-pane -U
        bind l select-pane -R
      '';
    };
    git = {
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
    ssh = {
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
    onepassword-secrets = {
      enable = true;
      tokenFile = "${config.home.homeDirectory}/.config/opnix/token";
      service.enable = true;
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
    zoxide = {
      enable = true;
      enableFishIntegration = true;
    };
  };

  programs.neovim.initLua = lib.mkBefore ''
    vim.g.theme = ${lib.generators.toLua { } osConfig.theme.native.nvim}
  '';

  programs.wezterm = {
    enable = true;
    # Loaded at runtime so edits apply without a rebuild.
    extraConfig = ''
      theme = ${lib.generators.toLua { } osConfig.theme.css}
      local dir = "${config.dotfilesPath}/"
      package.path = package.path .. ";" .. dir .. "?.lua"
      for _, file in ipairs({ "wezterm.lua", "modal.lua", "motions.lua" }) do
        wezterm.add_to_config_reload_watch_list(dir .. file)
      end
      return dofile(dir .. "wezterm.lua")
    '';
  };

  stylix = {
    enable = true;
    autoEnable = false;
    targets = {
      btop.enable = true;
      dunst.enable = true;
      firefox = {
        colorTheme.enable = true;
        enable = true;
        profileNames = [ "home" ];
      };
      fish.enable = osConfig.theme.native.fish == null;
      font-packages.enable = true;
      fontconfig.enable = true;
      foot.enable = true;
      neovim.enable = osConfig.theme.native.nvim == null;
      rofi.enable = true;
      tmux.enable = true;
      waybar = {
        addCss = false;
        enable = true;
      };
      wezterm.enable = true;
    };
  };
}
