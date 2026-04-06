{ pkgs, pkgs-unstable, inputs, ... }: {
  imports = [ inputs.stylix.homeModules.stylix ];

  home.stateVersion = "25.05";

  home.sessionVariables = { EDITOR = "nvim"; };

  xdg.configFile."nvim".source = ./nvim;

  home.packages = with pkgs; [
    (sbcl.withPackages (ps: [ ps.swank ]))
    _1password-cli
    _1password-gui
    age # simple modern file encryption tool
    bat # cat replacement with syntax highlighting
    pkgs-unstable.chezmoi
    delta # syntax-highlighting pager for git diff output
    dig # DNS lookup tool
    discord
    fd
    file
    fzf
    gcc
    gh
    git
    gnumake
    go
    httpie # user-friendly HTTP client
    jq
    killall
    lf # terminal file manager
    libnatpmp # NAT-PMP client library and tools
    lsd # modern ls replacement
    lua
    luaPackages.fennel
    lynx # terminal web browser
    nh # helper CLI for Nix/Home Manager workflows
    nixfmt
    opencode
    pkgs-unstable.github-copilot-cli # GitHub Copilot CLI from unstable nixpkgs
    procs # modern ps replacement
    python314
    ripgrep # fast recursive text search tool
    rlwrap # readline wrapper for interactive programs
    roswell # Common Lisp environment manager
    rsync
    sops # secrets editor/manager
    starship # cross-shell prompt
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
      dotnet-sdk
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

  stylix.enable = true;
  stylix.autoEnable = true;

  stylix.base16Scheme =
    "${pkgs.base16-schemes}/share/themes/tokyo-night-dark.yaml";

  stylix.targets.neovim.enable = false;
  stylix.targets.waybar.enable = false;
  stylix.targets.gnome.enable = false;
  stylix.targets.gtk.enable = false;
  stylix.targets.eog.enable = false;
  stylix.targets.gnome-text-editor.enable = false;

  stylix.targets.firefox.profileNames = [ "home" ];
  stylix.targets.firefox.colorTheme.enable = true;
}
