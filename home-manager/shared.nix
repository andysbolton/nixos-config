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
    discord
    docker-compose
    dotnetSdks
    fd
    file
    fzf
    gcc
    git
    gnumake
    go
    httpie # user-friendly HTTP client
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
    tokyonight-extras
    tree # recursive directory listing
    unzip
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

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    extraConfig = ''
      Include ~/.ssh/config.local
    '';
    settings = {
      "*".identityAgent =
        if pkgs.stdenv.isDarwin then
          ''"~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"''
        else
          "~/.1password/agent.sock";
      main = {
        hostname = "main.tail4b1b78.ts.net";
        user = "andy";
      };
      # TODO: switch to FQDN once portable is on the tailnet
      portable = {
        hostname = "portable.local";
        user = "andy";
      };
      work = {
        hostname = "work.tail4b1b78.ts.net";
        user = "andybolton";
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
