{
  config,
  lib,
  pkgs,
  pkgs-unstable,
  self,
  osConfig,
  ...
}:
let
  sketchybarBottom = pkgs.callPackage ../pkgs/sketchybar-bottom.nix { inherit pkgs-unstable; };
in
{
  imports = [
    ./modules/firefox.nix
    ./options/work.nix
    ./shared.nix
  ];

  targets.darwin.copyApps.enable = true;
  targets.darwin.linkApps.enable = false;

  home.homeDirectory = "/Users/andybolton";

  xdg.configFile = {
    "skhd/home-manager.skhdrc".source =
      config.lib.file.mkOutOfStoreSymlink "${config.dotfilesPath}/skhd/home-manager.skhdrc";
    sketchybar.source = config.lib.file.mkOutOfStoreSymlink "${config.dotfilesPath}/sketchybar";
    sketchybar-bottom.source = config.lib.file.mkOutOfStoreSymlink "${config.dotfilesPath}/sketchybar";
  };

  home.file.".hammerspoon/init.lua".source =
    config.lib.file.mkOutOfStoreSymlink "${config.dotfilesPath}/hammerspoon/init.lua";

  home.packages = with pkgs; [
    _1password-cli
    _1password-gui
    (azure-cli.withExtensions [
      azure-cli-extensions.azure-devops
      azure-cli-extensions.durabletask
      azure-cli-extensions.resource-graph
    ])
    desktoppr
    gatherv2
    jira-cli-go
    maccy
    moonlight-qt
    pngpaste
    powershell
    powershell-editor-services
    sketchybarBottom
  ];

  home.sessionPath = [
    "${config.home.homeDirectory}/Applications/Home Manager Apps/WezTerm.app"
  ];

  home.sessionVariables = {
    BROWSER = "${pkgs.firefox}/Applications/Firefox.app/Contents/MacOS/firefox";
  };

  launchd.agents.sketchybar-bottom = {
    enable = true;
    config = {
      Label = "org.nix-community.home.sketchybar-bottom";
      ProcessType = "Interactive";
      KeepAlive = true;
      RunAtLoad = true;
      StandardOutPath = "${config.home.homeDirectory}/Library/Logs/sketchybar/sketchybar-bottom.out.log";
      StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/sketchybar/sketchybar-bottom.err.log";
      Program = "${sketchybarBottom}/bin/sketchybar-bottom";
    };
  };

  services.jankyborders = {
    enable = true;
    settings = {
      width = 5.0;
      active_color = "0xff7dcfff";
      inactive_color = "0xff414868";
      hidpi = "on";
    };
  };

  programs.sketchybar = {
    enable = true;
    includeSystemPath = true;
    extraPackages = [
      pkgs-unstable.yabai
      pkgs.entr
      pkgs.ifstat-legacy
      pkgs.jq
    ];
  };

  programs.git = {
    settings = {
      user = {
        email = "andy.bolton@smartwyre.com";
      };
    };
  };
}
