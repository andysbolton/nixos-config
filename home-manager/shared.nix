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
    inputs.stylix.homeModules.stylix
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
    };
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
    claude-code
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
    tokyonight-extras
    tree # recursive directory listing
    unzip
    vesktop
    wezterm
    wget
    whois
    zoxide # smarter cd command
  ];

  programs.neovim = {
    enable = true;
    sideloadInitLua = true;
    withRuby = false;
    withPython3 = false;
    extraPackages = with pkgs; [
      cargo
      clang-tools
      fennel-ls
      fnlfmt
      lua-language-server
      luaPackages.luarocks
      nodejs_24
      stylua
      tree-sitter
    ];
  };

  programs.btop.enable = true;
  programs.fish.enable = true;

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
