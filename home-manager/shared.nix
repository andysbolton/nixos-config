{
  config,
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

  home.file.".local/bin".source = config.lib.file.mkOutOfStoreSymlink "${config.dotfilesPath}/bin";

  home.sessionPath = [ "${config.home.homeDirectory}/.local/bin" ];

  home.packages = with pkgs; [
    (sbcl.withPackages (ps: [ ps.swank ]))
    _1password-cli
    _1password-gui
    age # simple modern file encryption tool
    bat # cat replacement with syntax highlighting
    bat-extras.core
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
    pkgs-unstable.github-copilot-cli # GitHub Copilot CLI from unstable nixpkgs
    pkgs-unstable.opencode
    postgresql
    procs # modern ps replacement
    python314
    ripgrep # fast recursive text search tool
    rlwrap # readline wrapper for interactive programs
    roswell # Common Lisp environment manager
    rsync
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

  programs.man = {
    enable = true;
    generateCaches = true;
  };

  programs.btop.enable = true;
  programs.fish = {
    enable = true;
    package = pkgs-unstable.fish;
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
